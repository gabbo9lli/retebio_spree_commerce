#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$BACKEND_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
DUMP_FILE="${1:-$WORKSPACE_DIR/dump_prod_241006.sql}"
CONTAINER_PG="retebio_postgres"
CONTAINER_APP="retebio_backend"
LOG_DIR="$BACKEND_DIR/tmp"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/migration_${TIMESTAMP}.log"

echo "==========================================================" | tee "$LOG_FILE"
echo "  RETEBIO: RESTORE & MIGRAZIONE SPREE 5.x                 " | tee -a "$LOG_FILE"
echo "  Data: $(date)                                           " | tee -a "$LOG_FILE"
echo "  Dump di Origine: $DUMP_FILE                             " | tee -a "$LOG_FILE"
echo "  Log: $LOG_FILE                                          " | tee -a "$LOG_FILE"
echo "==========================================================" | tee -a "$LOG_FILE"

# 1. Verifica container Postgres
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_PG}$"; then
  echo "[-] ERRORE: Container $CONTAINER_PG non in esecuzione. Avviare con docker compose up -d" | tee -a "$LOG_FILE"
  exit 1
fi

# 2. Drop e Ricreazione Database
echo "[1/6] Ricreazione database pulito 'retebio_development'..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_PG" psql -U postgres -c "DROP DATABASE IF EXISTS retebio_development WITH (FORCE);" >> "$LOG_FILE" 2>&1
docker exec "$CONTAINER_PG" psql -U postgres -c "CREATE DATABASE retebio_development;" >> "$LOG_FILE" 2>&1

# 3. Restore del Dump SQL
echo "[2/6] Ripristino dump SQL nel database..." | tee -a "$LOG_FILE"
if [[ "$DUMP_FILE" == *.zip ]]; then
  unzip -p "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development >> "$LOG_FILE" 2>&1
elif [[ "$DUMP_FILE" == *.gz ]]; then
  gzip -dc "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development >> "$LOG_FILE" 2>&1
else
  docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development < "$DUMP_FILE" >> "$LOG_FILE" 2>&1
fi

# 4. Pre-Migration Sanitization (allineamento schema_migrations per tabelle preesistenti)
echo "[3/6] Sanitizzazione schema e registrazione versioni baseline..." | tee -a "$LOG_FILE"
docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development << 'EOSQL' >> "$LOG_FILE" 2>&1
-- Assicura che la tabella schema_migrations esista
CREATE TABLE IF NOT EXISTS schema_migrations (version character varying PRIMARY KEY);

-- Registra le versioni delle tabelle già create dal dump Spree 4.3 per evitare collisioni create_table
INSERT INTO schema_migrations (version) VALUES ('20240523142421') ON CONFLICT (version) DO NOTHING; -- spree_users
INSERT INTO schema_migrations (version) VALUES ('20240523142422') ON CONFLICT (version) DO NOTHING; -- active_storage_tables
INSERT INTO schema_migrations (version) VALUES ('20240523142423') ON CONFLICT (version) DO NOTHING; -- action_mailbox_tables
INSERT INTO schema_migrations (version) VALUES ('20240523142424') ON CONFLICT (version) DO NOTHING; -- action_text_tables
INSERT INTO schema_migrations (version) VALUES ('20250210131634') ON CONFLICT (version) DO NOTHING; -- spree_four_three baseline
INSERT INTO schema_migrations (version) VALUES ('20250210131720') ON CONFLICT (version) DO NOTHING; -- spree_api add_api_key
INSERT INTO schema_migrations (version) VALUES ('20250210131721') ON CONFLICT (version) DO NOTHING; -- spree_api resize_api_key
INSERT INTO schema_migrations (version) VALUES ('20250210131722') ON CONFLICT (version) DO NOTHING; -- spree_api rename_api_key
INSERT INTO schema_migrations (version) VALUES ('20250210131723') ON CONFLICT (version) DO NOTHING; -- spree_api add_index
INSERT INTO schema_migrations (version) VALUES ('20250210131724') ON CONFLICT (version) DO NOTHING; -- spree_api create_doorkeeper
INSERT INTO schema_migrations (version) VALUES ('20250210131725') ON CONFLICT (version) DO NOTHING; -- spree_api change_integer_id

-- Pulizia indici/colonne duplicate se presenti
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'spree_stores' AND column_name = 'deleted_at') THEN
    -- Mantieni se compatibile
    NULL;
  END IF;
END $$;
EOSQL

# 5. Esecuzione Migrazioni Spree 5.x
echo "[4/6] Esecuzione 'rails db:migrate' all'interno del container Spree 5.x..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bundle exec rails db:migrate >> "$LOG_FILE" 2>&1

# 6. Post-Migration Data Healing (assegnazione store predefinito e sincronizzazione admin users)
echo "[5/6] Esecuzione Data Healing e setup store/admin..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bundle exec rails runner "
# Store predefinito
store = Spree::Store.default || Spree::Store.first || Spree::Store.create!(
  name: 'Retebio',
  code: 'retebio',
  url: 'localhost:4000',
  mail_from_address: 'info@retebio.it',
  default_currency: 'EUR'
)
store.update!(default: true) unless store.default?

# Aggiornamento store_id per record orfani
orders_fixed = Spree::Order.where(store_id: nil).update_all(store_id: store.id)
puts \"Associati #{orders_fixed} ordini allo store '#{store.name}'.\"

products_fixed = 0
Spree::Product.all.find_each do |p|
  unless p.stores.include?(store)
    p.stores << store
    products_fixed += 1
  end
end
puts \"Associati #{products_fixed} prodotti allo store '#{store.name}'.\"

# Sincronizzazione admin user in Spree::AdminUser se non presente
admin_role = Spree::Role.find_by(name: 'admin')
if admin_role
  spree_admins = Spree.user_class.joins(:spree_roles).where(spree_roles: { id: admin_role.id })
  spree_admins.find_each do |legacy_admin|
    admin_user = Spree::AdminUser.find_or_initialize_by(email: legacy_admin.email)
    if admin_user.new_record?
      admin_user.encrypted_password = legacy_admin.encrypted_password
      admin_user.save!(validate: false)
      puts \"Migrato account amministratore: #{admin_user.email}\"
    end
    admin_user.add_role('admin', store)
  end
end

# Se nessun admin esiste ancora, ne creiamo uno predefinito per i test
if Spree::AdminUser.count.zero?
  admin = Spree::AdminUser.create!(email: 'admin@retebio.it', password: 'password123', password_confirmation: 'password123')
  admin.add_role('admin', store)
  puts 'Creato account admin di test: admin@retebio.it / password123'
else
  Spree::AdminUser.all.find_each do |admin|
    admin.add_role('admin', store)
  end
end
" >> "$LOG_FILE" 2>&1

echo "[6/6] Riavvio rapido del server web per caricare il nuovo schema..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bash -c "rm -f tmp/pids/server.pid"
docker restart "$CONTAINER_APP" >> "$LOG_FILE" 2>&1
sleep 5

echo "==========================================================" | tee -a "$LOG_FILE"
echo "  MIGRAZIONE COMPLETATA CON SUCCESSO!                     " | tee -a "$LOG_FILE"
echo "==========================================================" | tee -a "$LOG_FILE"
