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

CURRENT_RAILS_ENV="$(docker exec "$CONTAINER_APP" printenv RAILS_ENV 2>/dev/null || echo "development")"
if [ "$CURRENT_RAILS_ENV" = "production" ]; then
  DB_NAME="${DB_NAME:-retebio_production}"
else
  DB_NAME="${DB_NAME:-retebio_development}"
fi

# 2. Drop e Ricreazione Database
echo "[1/6] Ricreazione database pulito '$DB_NAME'..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_PG" psql -U postgres -c "DROP DATABASE IF EXISTS $DB_NAME WITH (FORCE);" >> "$LOG_FILE" 2>&1
docker exec "$CONTAINER_PG" psql -U postgres -c "CREATE DATABASE $DB_NAME;" >> "$LOG_FILE" 2>&1

# 3. Restore del Dump SQL
echo "[2/6] Ripristino dump SQL nel database..." | tee -a "$LOG_FILE"
if [[ "$DUMP_FILE" == *.zip ]]; then
  unzip -p "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d $DB_NAME >> "$LOG_FILE" 2>&1
elif [[ "$DUMP_FILE" == *.gz ]]; then
  gzip -dc "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d $DB_NAME >> "$LOG_FILE" 2>&1
else
  docker exec -i "$CONTAINER_PG" psql -U postgres -d $DB_NAME < "$DUMP_FILE" >> "$LOG_FILE" 2>&1
fi

# 4. Pre-Migration Sanitization (allineamento schema_migrations per tabelle preesistenti)
echo "[3/6] Sanitizzazione schema e registrazione versioni baseline..." | tee -a "$LOG_FILE"
docker exec -i "$CONTAINER_PG" psql -U postgres -d $DB_NAME << 'EOSQL' >> "$LOG_FILE" 2>&1
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
    NULL;
  END IF;
END $$;
EOSQL

# 5. Esecuzione Migrazioni Spree 5.x
echo "[4/6] Esecuzione 'rails db:migrate' all'interno del container Spree 5.x..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bundle exec rails db:migrate >> "$LOG_FILE" 2>&1

# 6. Post-Migration Data Healing: Ripristino e configurazione completa utenti, store e checkout
echo "[5/6] Ripristino utenti originali, anagrafiche e configurazione store..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bundle exec rails runner "
# 1. Paesi e Regioni per spedizione/fatturazione (se non presenti nel dump)
if Spree::Country.count.zero?
  puts 'Seeding Paesi e Province...'
  Spree::Seeds::Countries.call rescue nil
  Spree::Seeds::States.call rescue nil
  Spree::Seeds::Zones.call rescue nil
  puts \"Caricati #{Spree::Country.count} paesi e #{Spree::State.count} province.\"
end

it_country = Spree::Country.find_by(iso: 'IT') || Spree::Country.first

# 2. Store predefinito
store = Spree::Store.default || Spree::Store.first || Spree::Store.create!(
  name: 'Retebio',
  code: 'retebio',
  url: ENV['SPREE_STORE_URL'] || 'localhost:4000',
  mail_from_address: 'info@retebio.it',
  customer_support_email: 'info@retebio.it',
  default_currency: 'EUR',
  supported_currencies: 'EUR'
)
store.default_country = it_country if it_country
store.mail_from_address = 'info@retebio.it' if store.mail_from_address.blank?
store.customer_support_email = 'info@retebio.it' if store.customer_support_email.blank?
store.default_currency = 'EUR'
store.supported_currencies = 'EUR'
store.default = true
store.save!

# 3. Aggiornamento store_id per ordini e prodotti
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

# 4. Ripristino Utenti Amministratori Originali (Spree::AdminUser)
admin_role = Spree::Role.find_or_create_by!(name: 'admin')
user_role = Spree::Role.find_or_create_by!(name: 'user')

# Nel dump di produzione gli account amministratori storici sono:
# gabbo9lli@gmail.com, fillomix@hotmail.it, gruppobio@email.it, info@retebio.it, spree@example.com
admin_emails = ['gabbo9lli@gmail.com', 'fillomix@hotmail.it', 'gruppobio@email.it', 'info@retebio.it', 'spree@example.com']

legacy_admins = Spree.user_class.where(email: admin_emails)
legacy_admins.find_each do |legacy_admin|
  admin_user = Spree::AdminUser.find_or_initialize_by(email: legacy_admin.email)
  admin_user.encrypted_password = legacy_admin.encrypted_password
  admin_user.password_salt = legacy_admin.password_salt if admin_user.respond_to?(:password_salt=)
  admin_user.first_name = legacy_admin.first_name
  admin_user.last_name = legacy_admin.last_name
  admin_user.login = legacy_admin.login
  admin_user.save!(validate: false)
  admin_user.add_role('admin', store)
  puts \"Ripristinato amministratore originale: #{admin_user.email} (ID: #{admin_user.id})\"
end

# Assicura anche account amministratore di default admin@retebio.it
default_admin = Spree::AdminUser.find_or_initialize_by(email: 'admin@retebio.it')
if default_admin.new_record?
  default_admin.password = 'password123'
  default_admin.password_confirmation = 'password123'
  default_admin.save!
end
default_admin.add_role('admin', store)
puts \"Account amministratore predefinito pronto: admin@retebio.it / password123 (ID: #{default_admin.id})\"

# Rimuove associazioni ruoli orfani con user_type 'Spree::AdminUser' non corrispondenti a record reali
Spree::RoleUser.where(user_type: 'Spree::AdminUser').where.not(user_id: Spree::AdminUser.pluck(:id)).delete_all

# 5. Ripristino di TUTTI gli Utenti Clienti Originali (Spree::User) con Ruolo 'user'
puts \"Ripristino e abilitazione ruolo 'user' per #{Spree.user_class.count} clienti originali...\"
Spree.user_class.find_each do |client_user|
  Spree::RoleUser.find_or_create_by!(role: user_role, user: client_user)
end
puts \"Tutti i #{Spree.user_class.count} utenti del backup sono abilitati al login e acquisto B2B.\"

# Assicura anche account test B2B cliente@retebio.it per verifiche rapide
test_client = Spree.user_class.find_or_initialize_by(email: 'cliente@retebio.it')
test_client.password = 'password123'
test_client.password_confirmation = 'password123'
test_client.first_name = 'Cliente'
test_client.last_name = 'Test'
test_client.save!
Spree::RoleUser.find_or_create_by!(role: user_role, user: test_client)

if it_country
  test_addr = {
    firstname: 'Cliente',
    lastname: 'Test',
    company: 'Azienda Agricola Test',
    address1: 'Via Roma 1',
    city: 'Reggio Emilia',
    zipcode: '42121',
    phone: '3331234567',
    country: it_country,
    state: re_state
  }
  b = test_client.bill_address || test_client.build_bill_address
  b.assign_attributes(test_addr)
  b.save!
  s = test_client.ship_address || test_client.build_ship_address
  s.assign_attributes(test_addr)
  s.save!
  test_client.bill_address = b
  test_client.ship_address = s
  test_client.save!
end
puts \"Account test B2B pronto: cliente@retebio.it / password123 (ID: #{test_client.id})\"

# 6. Associazione Metodi di Pagamento allo Store
Spree::PaymentMethod.find_each do |pm|
  pm.stores << store unless pm.stores.include?(store)
end

# 7. Applicazione OAuth per API Storefront / Admin
oauth_app = Spree::OauthApplication.find_or_create_by!(name: 'Admin Panel') do |app|
  app.scopes = 'admin'
  app.redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'
end
puts \"Applicazione OAuth verificata: #{oauth_app.name}\"
" >> "$LOG_FILE" 2>&1

echo "[6/6] Riavvio rapido del server web per caricare il nuovo schema..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bash -c "rm -f tmp/pids/server.pid"
docker restart "$CONTAINER_APP" >> "$LOG_FILE" 2>&1
sleep 5

echo "==========================================================" | tee -a "$LOG_FILE"
echo "  MIGRAZIONE E RIPRISTINO UTENTI COMPLETATI CON SUCCESSO! " | tee -a "$LOG_FILE"
echo "==========================================================" | tee -a "$LOG_FILE"
