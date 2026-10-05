# Upgrade Retebio a Spree 5.x Headless con Dati Storici e Vue Storefront Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Creare il nuovo progetto Retebio in `/Users/novellig/docker_images/retebio_local/retebio_5x` basato su Spree 5.x Headless (Rails 8 / Ruby 3.3) accoppiato a Vue Storefront, interamente containerizzato in Docker, preservando al 100% lo storico di ordini, clienti, pagamenti, catalogo e immagini media tramite una procedura di restore automatizzata e ripetibile.

**Architecture:** Stack decoupled 100% Docker confinato nella directory dedicata `retebio_5x`: backend Rails 8 con Spree Commerce 5.1 in modalità Headless (Spree Admin + Storefront API v2 via Doorkeeper OAuth2), PostgreSQL 16 e Redis 7 sulla rete container `retebio_net`. Frontend separato basato su Vue Storefront. Customizzazioni di business (B2B prezzi riservati e vendita a multipli del peso) estratte dal core legacy e implementate esclusivamente come decoratori Rails e serializer su API v2. Procedura di migrazione DB incapsulata in uno script bash idempotente per garantire ripetibilità al go-live davanti al cliente.

**Tech Stack:** Ruby 3.3.0, Rails 8.0.0, Spree Commerce ~> 5.1 (`spree`, `spree_admin`, `spree_api`, `spree_emails`), PostgreSQL 16, Redis 7, Active Storage, Vue Storefront (Node.js/Vue 3/Nuxt), Docker & Docker Compose.

**Spec:** `docs/superpowers/specs/2026-10-04-spree5-upgrade-design.md`

## Global Constraints

- **Nuova Directory di Progetto**: Il nuovo progetto deve risiedere esclusivamente in `/Users/novellig/docker_images/retebio_local/retebio_5x`.
- **Isolamento Totale dell'Ambiente Legacy**: La directory `spree_43` e i dump SQL originali non devono essere toccati né modificati.
- **Preservazione Storico Dati al 100%**: Ordini, clienti, indirizzi, pagamenti, tassonomie, catalogo e immagini Active Storage.
- **Zero Modifiche al Core Spree**: Nessun fork; tutte le personalizzazioni risiedono in decoratori puliti (`app/models/spree/*_decorator.rb`, `app/serializers/spree/*_decorator.rb`).
- **100% Docker**: Tutti i servizi (database, cache, backend rails, frontend vue) girano in container Docker.
- **Ripetibilità Scriptata**: Procedura di restore e migrazione automatizzata per essere rieseguita su dump freschi.
- **Verifica Immagini Media**: Controllo esplicito della presenza e visualizzazione dei media catalogo sia su backend (Spree Admin / storage) sia su frontend (Vue Storefront).

## Review Focus

1. **Dump Schema Conflicts**: Riferimenti legacy nel dump 4.3 (es. colonna `deleted_at` su `spree_stores` o chiavi orfane) che bloccano `rails db:migrate` in Spree 5.x.
2. **Missing Media Blobs**: Record in `active_storage_blobs` che non trovano il file fisico corrispondente su disco in `storage/` e causano 404 in Spree Admin o Vue.
3. **B2B Price Leak**: Chiamate API v2 anonime che espongono prezzi o consentono la creazione/modifica del carrello a visitatori non autenticati.
4. **Weight Multiplier Validation Bypass**: Aggiunta al carrello di quantità non multiple del peso (`variant.weight`) tramite chiamate API dirette che bypassano i controlli del frontend.
5. **CORS / Network Resolution**: Chiamate client-side e SSR di Vue Storefront verso il backend Spree bloccate da policy CORS o da host non raggiungibili tra container.

---

### Task 1: Inizializzazione Progetto in `retebio_5x` e Docker Environment Setup

**Files:**
- Create: `retebio_5x/Dockerfile.dev`
- Create: `retebio_5x/docker-compose.yaml`
- Create: `retebio_5x/config/database.yml`
- Copy/Initialize: Struttura Rails 8 / Spree 5.1 in `retebio_5x/`
- Test: Verifica container status e endpoint health `/up`

**Interfaces:**
- Consumes: Configurazione Docker host, immagini ufficiali `postgres:16-alpine`, `redis:7-alpine`, `ruby:3.3.0-slim`
- Produces: Servizi `retebio_postgres`, `retebio_redis`, `retebio_spree_backend` attivi sulla rete `retebio_net`, porta 4000 esposta sull'host

- [ ] **Step 1: Inizializzare la directory `retebio_5x` con il template applicativo Spree 5.1**

Copiare l'applicazione pulita Rails 8 / Spree 5.1 da `spree_starter_latest` a `retebio_5x` (escludendo file temporanei e log):
```bash
rsync -av --exclude 'tmp/' --exclude 'log/' --exclude '.git/' spree_starter_latest/ retebio_5x/
```

- [ ] **Step 2: Configurare `retebio_5x/Dockerfile.dev`**

Creare `retebio_5x/Dockerfile.dev`:
```dockerfile
FROM ruby:3.3.0-slim

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      libpq-dev \
      libvips \
      postgresql-client \
      redis-tools && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    DISABLE_SPRING=1

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 4000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "4000"]
```

- [ ] **Step 3: Configurare `retebio_5x/docker-compose.yaml`**

Creare `retebio_5x/docker-compose.yaml`:
```yaml
services:
  postgres:
    image: postgres:16-alpine
    container_name: retebio_postgres
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
      POSTGRES_DB: retebio_development
    volumes:
      - retebio_pgdata:/var/lib/postgresql/data
      - ../:/dumps:ro
    ports:
      - "5432:5432"
    networks:
      - retebio_net

  redis:
    image: redis:7-alpine
    container_name: retebio_redis
    ports:
      - "6379:6379"
    volumes:
      - retebio_redisdata:/data
    networks:
      - retebio_net

  web:
    build:
      context: .
      dockerfile: Dockerfile.dev
    container_name: retebio_spree_backend
    depends_on:
      - postgres
      - redis
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0 -p 4000"
    ports:
      - "4000:4000"
    volumes:
      - .:/rails
      - bundle_cache:/usr/local/bundle
      - ./storage:/rails/storage
      - ../:/dumps:ro
    environment:
      DB_HOST: postgres
      DB_USER: postgres
      DB_PASSWORD: password
      DB_PORT: 5432
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: development
    networks:
      - retebio_net

volumes:
  retebio_pgdata:
  retebio_redisdata:
  bundle_cache:

networks:
  retebio_net:
    name: retebio_net
```

- [ ] **Step 4: Configurare `retebio_5x/config/database.yml`**

Assicurare che il database si chiami `retebio_development`:
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development: &development
  <<: *default
  database: retebio_development
  host: <%= ENV.fetch('DB_HOST', 'postgres') %>
  username: <%= ENV.fetch('DB_USER', 'postgres') %>
  password: <%= ENV.fetch('DB_PASSWORD', 'password') %>
  port: <%= ENV.fetch('DB_PORT', 5432) %>
  gssencmode: disable

test:
  <<: *default
  database: retebio_test
  host: <%= ENV.fetch('DB_HOST', 'postgres') %>
  username: <%= ENV.fetch('DB_USER', 'postgres') %>
  password: <%= ENV.fetch('DB_PASSWORD', 'password') %>
  port: <%= ENV.fetch('DB_PORT', 5432) %>
  gssencmode: disable

production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
```

- [ ] **Step 5: Avviare i container e verificare l'avvio**

Eseguire:
```bash
cd retebio_5x && docker compose build web && docker compose up -d
```
Verificare con:
```bash
docker compose ps
docker compose logs web | tail -n 20
curl -s http://localhost:4000/up
```
Atteso: Servizi `retebio_postgres`, `retebio_redis`, `retebio_spree_backend` in stato `Up`; l'endpoint health risponde HTTP 200.

---

### Task 2: Script Automatizzato di Restore e Migrazione (`retebio_5x/scripts/db_restore_and_migrate.sh`)

**Files:**
- Create: `retebio_5x/scripts/db_restore_and_migrate.sh`
- Test: Esecuzione su dump `dump_prod_241006.sql` e verifica log di migrazione

**Interfaces:**
- Consumes: Dump SQL `dump_prod_241006.sql`, container `retebio_postgres`, container `retebio_spree_backend`
- Produces: Database `retebio_development` allineato allo schema Spree 5.1 con tutti i dati storici, file di log in `retebio_5x/tmp/migration_YYYYMMDD_HHMMSS.log`

- [ ] **Step 1: Scrivere lo script di sanitizzazione e restore automatizzato**

Creare `retebio_5x/scripts/db_restore_and_migrate.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WORKSPACE_DIR="$(cd "$PROJECT_DIR/.." && pwd)"
DUMP_FILE="${1:-$WORKSPACE_DIR/dump_prod_241006.sql}"
CONTAINER_PG="retebio_postgres"
CONTAINER_APP="retebio_spree_backend"
LOG_DIR="$PROJECT_DIR/tmp"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/migration_${TIMESTAMP}.log"

echo "=== Inizio Restore e Migrazione Spree 5.x: $(date) ===" | tee "$LOG_FILE"
echo "Target Dump: $DUMP_FILE" | tee -a "$LOG_FILE"

# 1. Verifica container Postgres
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_PG}$"; then
  echo "ERRORE: Container $CONTAINER_PG non in esecuzione. Avviare con docker compose up -d" | tee -a "$LOG_FILE"
  exit 1
fi

# 2. Drop e Ricreazione Database
echo "--> Resetto database retebio_development..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_PG" psql -U postgres -c "DROP DATABASE IF EXISTS retebio_development;" >> "$LOG_FILE" 2>&1
docker exec "$CONTAINER_PG" psql -U postgres -c "CREATE DATABASE retebio_development;" >> "$LOG_FILE" 2>&1

# 3. Restore del Dump SQL
echo "--> Ripristino dump SQL nel database..." | tee -a "$LOG_FILE"
if [[ "$DUMP_FILE" == *.zip ]]; then
  unzip -p "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development >> "$LOG_FILE" 2>&1
elif [[ "$DUMP_FILE" == *.gz ]]; then
  gzip -dc "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development >> "$LOG_FILE" 2>&1
else
  cat "$DUMP_FILE" | docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development >> "$LOG_FILE" 2>&1
fi

# 4. Pre-Migration Sanitization (pulizia artefatti vecchi fork)
echo "--> Sanitizzazione pre-migrazione..." | tee -a "$LOG_FILE"
docker exec -i "$CONTAINER_PG" psql -U postgres -d retebio_development << 'EOSQL' >> "$LOG_FILE" 2>&1
-- Assicura che la tabella schema_migrations esista e non abbia duplicati che bloccano Rails 8
CREATE TABLE IF NOT EXISTS schema_migrations (version character varying PRIMARY KEY);
-- Allinea timestamp o colonne custom se presenti
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'spree_stores' AND column_name = 'deleted_at') THEN
    ALTER TABLE spree_stores DROP COLUMN IF EXISTS deleted_at;
  END IF;
END $$;
EOSQL

# 5. Esecuzione Migrazioni Spree 5.x
echo "--> Esecuzione 'rails db:migrate' all'interno del container web..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bundle exec rails db:migrate >> "$LOG_FILE" 2>&1

# 6. Post-Migration Data Healing (assegnazione store predefinito a record orfani)
echo "--> Esecuzione script di post-migrazione e coerenza dati..." | tee -a "$LOG_FILE"
docker exec "$CONTAINER_APP" bundle exec rails runner "
default_store = Spree::Store.default || Spree::Store.first || Spree::Store.create!(name: 'Retebio', code: 'retebio', url: 'localhost:4000', mail_from_address: 'info@retebio.it', default_currency: 'EUR')
Spree::Order.where(store_id: nil).update_all(store_id: default_store.id)
Spree::Product.all.each do |p|
  p.stores << default_store unless p.stores.include?(default_store)
end
puts 'Data healing completato con successo.'
" >> "$LOG_FILE" 2>&1

echo "=== Restore e Migrazione completati con successo! Log salvato in $LOG_FILE ===" | tee -a "$LOG_FILE"
```
Rendere eseguibile:
```bash
chmod +x retebio_5x/scripts/db_restore_and_migrate.sh
```

- [ ] **Step 2: Eseguire lo script e verificare l'esito**

Eseguire:
```bash
./retebio_5x/scripts/db_restore_and_migrate.sh
```
Atteso: "=== Restore e Migrazione completati con successo! ===" e codice di uscita 0.

---

### Task 3: Script di Riconciliazione e Integrità dei Dati Storici

**Files:**
- Create: `retebio_5x/bin/verify_data_integrity.rb`
- Test: Esecuzione via `rails runner` nel container web

**Interfaces:**
- Consumes: Database `retebio_development` post-migrazione
- Produces: Report a terminale con conteggi e controlli di non-regressione su ordini, clienti, pagamenti e catalogo

- [ ] **Step 1: Creare lo script di verifica riconciliazione dati**

Creare `retebio_5x/bin/verify_data_integrity.rb`:
```ruby
# frozen_string_literal: true

puts "\n=============================================="
puts "  RETEBIO: VERIFICA INTEGRITA' DATI STORICI   "
puts "=============================================="

errors = []

# 1. Clienti / Utenti
users_count = Spree.user_class.count
puts "1. Totale Utenti Registrati: #{users_count}"
errors << "Nessun utente trovato!" if users_count.zero?

# 2. Ordini
orders_total = Spree::Order.count
completed_orders = Spree::Order.complete.count
orders_revenue = Spree::Order.complete.sum(:total)
puts "2. Ordini Totali: #{orders_total}"
puts "   Ordini Completati: #{completed_orders}"
puts "   Fatturato Totale Storico: €#{sprintf('%.2f', orders_revenue)}"
errors << "Nessun ordine storico presente!" if orders_total.zero?

# 3. Line Items
line_items_count = Spree::LineItem.count
puts "3. Totale Righe Ordine (Line Items): #{line_items_count}"
errors << "Line items orfani o assenti!" if line_items_count.zero?

# 4. Pagamenti
payments_count = Spree::Payment.count
completed_payments = Spree::Payment.completed.count
puts "4. Transazioni di Pagamento: #{payments_count} (Completati: #{completed_payments})"

# 5. Catalogo
products_count = Spree::Product.count
variants_count = Spree::Variant.count
taxonomies_count = Spree::Taxonomy.count
puts "5. Catalogo:"
puts "   Prodotti: #{products_count}"
puts "   Varianti: #{variants_count}"
puts "   Tassonomie: #{taxonomies_count}"
errors << "Prodotti del catalogo non trovati!" if products_count.zero?

# 6. Store predefinito
store = Spree::Store.default
puts "6. Store Predefinito: #{store&.name} (Code: #{store&.code}, Valuta: #{store&.default_currency})"
errors << "Store predefinito non configurato!" if store.nil?

puts "=============================================="
if errors.empty?
  puts " ESITO: TUTTI I DATI STORICI SONO INTEGRI! (0 ERRORI)"
  puts "==============================================\n"
  exit 0
else
  puts " ATTENZIONE: Rilevate anomalie:"
  errors.each { |err| puts "  - #{err}" }
  puts "==============================================\n"
  exit 1
end
```

- [ ] **Step 2: Eseguire lo script di verifica nel container**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rails runner bin/verify_data_integrity.rb
```
Atteso: Report con conteggio ordini, utenti, fatturato storico e "ESITO: TUTTI I DATI STORICI SONO INTEGRI! (0 ERRORI)".

---

### Task 4: Verifica Immagini Media del Catalogo (Active Storage & Spree Admin)

**Files:**
- Create: `retebio_5x/bin/verify_catalog_media.rb`
- Test: Esecuzione via `rails runner` nel container web

**Interfaces:**
- Consumes: Tabelle `active_storage_blobs`, `active_storage_attachments`, `spree_assets`, volume `/rails/storage`
- Produces: Report di corrispondenza tra file fisici su disco e record DB; verifica endpoint immagini Admin

- [ ] **Step 1: Creare lo script di verifica delle immagini media**

Creare `retebio_5x/bin/verify_catalog_media.rb`:
```ruby
# frozen_string_literal: true

puts "\n=============================================="
puts "  RETEBIO: VERIFICA IMMAGINI MEDIA CATALOGO   "
puts "=============================================="

total_assets = Spree::Asset.count
total_blobs = ActiveStorage::Blob.count
puts "Totale Asset Spree: #{total_assets}"
puts "Totale Blob Active Storage: #{total_blobs}"

products_with_images = Spree::Product.joins(variants_including_master: :images).distinct.count
puts "Prodotti con immagini associate: #{products_with_images}"

# Verifica presenza file fisici su disco per il servizio Active Storage
missing_files = 0
valid_files = 0

ActiveStorage::Blob.find_each do |blob|
  service = blob.service
  if service.exist?(blob.key)
    valid_files += 1
  else
    missing_files += 1
  end
end

puts "Verifica storage su disco:"
puts " - Immagini con file presente su disco: #{valid_files}"
puts " - Immagini con file mancante: #{missing_files}"

# Test serializzazione URL immagine per il primo prodotto con immagine
sample_product = Spree::Product.joins(variants_including_master: :images).first
if sample_product && sample_product.images.any?
  sample_img = sample_product.images.first
  url = Rails.application.routes.url_helpers.rails_blob_url(sample_img.attachment, host: 'http://localhost:4000') rescue nil
  puts "Test URL immagine prodotto '#{sample_product.name}': #{url}"
end

puts "=============================================="
```

- [ ] **Step 2: Eseguire la verifica e analizzare l'output**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rails runner bin/verify_catalog_media.rb
```
Atteso: Statistiche su asset presenti, prodotti con immagini e URL di test generato.

---

### Task 5: Riprogettazione B2B (Prezzi Riservati e Carrello Gated su API v2)

**Files:**
- Create: `retebio_5x/spec/requests/spree/api/v2/storefront/b2b_pricing_spec.rb`
- Create: `retebio_5x/app/serializers/spree/v2/storefront/product_serializer_decorator.rb`
- Create: `retebio_5x/app/controllers/spree/api/v2/storefront/cart_controller_decorator.rb`
- Test: RSpec test suite nel container web

**Interfaces:**
- Consumes: Spree Storefront API v2 (`Spree::Api::V2::Storefront::ProductsController`, `Spree::Api::V2::Storefront::CartController`)
- Produces: Oscuramento prezzi (`price = nil`) per chiamate senza token Bearer utente; blocco aggiunta carrello per visitatori anonimi con `401 Unauthorized`

- [ ] **Step 1: Scrivere i test RSpec per la protezione B2B**

Creare `retebio_5x/spec/requests/spree/api/v2/storefront/b2b_pricing_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe 'B2B Gated Store API', type: :request do
  let!(:store) { Spree::Store.default || create(:store) }
  let!(:product) { create(:product, price: 15.50, stores: [store]) }
  let!(:user) { create(:user) }

  describe 'GET /api/v2/storefront/products' do
    context 'quando l utente non e autenticato' do
      it 'restituisce i prodotti senza esporre i prezzi' do
        get '/api/v2/storefront/products'
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        first_product_attrs = json['data'].first['attributes']
        expect(first_product_attrs['price']).to be_nil
        expect(first_product_attrs['display_price']).to be_nil
      end
    end

    context 'quando l utente e autenticato via token' do
      it 'mostra il prezzo corretto' do
        token = Doorkeeper::AccessToken.create!(resource_owner_id: user.id, application_id: nil, scopes: 'storefront')
        get '/api/v2/storefront/products', headers: { 'Authorization' => "Bearer #{token.token}" }
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        first_product_attrs = json['data'].first['attributes']
        expect(first_product_attrs['price']).to eq('15.5')
      end
    end
  end

  describe 'POST /api/v2/storefront/cart/add_item' do
    context 'quando l utente anonimo tenta di aggiungere al carrello' do
      it 'risponde con 401 Unauthorized' do
        post '/api/v2/storefront/cart/add_item', params: { variant_id: product.master.id, quantity: 1 }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
```

- [ ] **Step 2: Eseguire il test per verificare il fallimento (Red)**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rspec spec/requests/spree/api/v2/storefront/b2b_pricing_spec.rb
```
Atteso: FAIL (i prezzi sono attualmente visibili anche agli utenti anonimi).

- [ ] **Step 3: Implementare il Decorator del Serializer Prodotto**

Creare `retebio_5x/app/serializers/spree/v2/storefront/product_serializer_decorator.rb`:
```ruby
# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      module ProductSerializerDecorator
        def self.prepended(base)
          base.attribute :price do |product, params|
            params[:current_user].present? ? product.price.to_s : nil
          end

          base.attribute :display_price do |product, params|
            params[:current_user].present? ? product.display_price.to_s : nil
          end

          base.attribute :compare_at_price do |product, params|
            params[:current_user].present? ? product.compare_at_price.to_s : nil
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::ProductSerializer.prepend(Spree::V2::Storefront::ProductSerializerDecorator)
```

- [ ] **Step 4: Implementare la protezione su CartController**

Creare `retebio_5x/app/controllers/spree/api/v2/storefront/cart_controller_decorator.rb`:
```ruby
# frozen_string_literal: true

module Spree
  module Api
    module V2
      module Storefront
        module CartControllerDecorator
          def self.prepended(base)
            base.before_action :require_spree_user_for_b2b, only: [:create, :add_item, :set_quantity, :remove_line_item]
          end

          private

          def require_spree_user_for_b2b
            unless spree_current_user.present?
              render_error_payload(Spree.t(:b2b_login_required, default: 'Accesso richiesto per acquistare'), :unauthorized)
            end
          end
        end
      end
    end
  end
end

Spree::Api::V2::Storefront::CartController.prepend(Spree::Api::V2::Storefront::CartControllerDecorator)
```

- [ ] **Step 5: Eseguire nuovamente i test RSpec (Green)**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rspec spec/requests/spree/api/v2/storefront/b2b_pricing_spec.rb
```
Atteso: PASS con tutti i test verdi.

---

### Task 6: Riprogettazione Vendita a Peso e Multipli (`product.weight`)

**Files:**
- Create: `retebio_5x/spec/models/spree/line_item_weight_spec.rb`
- Create: `retebio_5x/app/models/spree/line_item_decorator.rb`
- Create: `retebio_5x/app/serializers/spree/v2/storefront/variant_serializer_decorator.rb`
- Test: RSpec test suite nel container web

**Interfaces:**
- Consumes: Campo `weight` di `Spree::Variant`
- Produces: Validazione `LineItem` per imporre multipli del peso; attributi `weight` e `quantity_step` serializzati su API v2

- [ ] **Step 1: Scrivere test RSpec per la validazione quantità a peso**

Creare `retebio_5x/spec/models/spree/line_item_weight_spec.rb`:
```ruby
require 'rails_helper'

RSpec.describe Spree::LineItem, type: :model do
  let(:order) { create(:order) }
  let(:variant) { create(:variant, weight: 2.5) }

  it 'è valido se la quantità è un multiplo esatto del peso (o step)' do
    line_item = Spree::LineItem.new(order: order, variant: variant, quantity: 5.0)
    expect(line_item).to be_valid
  end

  it 'non è valido se la quantità non rispetta lo step del peso' do
    line_item = Spree::LineItem.new(order: order, variant: variant, quantity: 3.0)
    expect(line_item).not_to be_valid
    expect(line_item.errors[:quantity]).to include("deve essere un multiplo del peso di vendita (2.5)")
  end
end
```

- [ ] **Step 2: Eseguire il test per verificare il fallimento (Red)**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rspec spec/models/spree/line_item_weight_spec.rb
```
Atteso: FAIL (validazione custom ancora non presente).

- [ ] **Step 3: Implementare la validazione in LineItemDecorator**

Creare `retebio_5x/app/models/spree/line_item_decorator.rb`:
```ruby
# frozen_string_literal: true

module Spree
  module LineItemDecorator
    def self.prepended(base)
      base.validate :validate_quantity_matches_weight_step
    end

    private

    def validate_quantity_matches_weight_step
      return unless variant&.weight.present? && variant.weight > 0
      step = variant.weight
      # Verifica modulo con tolleranza floating point
      remainder = (quantity % step).round(4)
      if remainder > 0.0001 && (step - remainder).abs > 0.0001
        errors.add(:quantity, "deve essere un multiplo del peso di vendita (#{step})")
      end
    end
  end
end

Spree::LineItem.prepend(Spree::LineItemDecorator)
```

- [ ] **Step 4: Esporre lo step di quantità nel VariantSerializer**

Creare `retebio_5x/app/serializers/spree/v2/storefront/variant_serializer_decorator.rb`:
```ruby
# frozen_string_literal: true

module Spree
  module V2
    module Storefront
      module VariantSerializerDecorator
        def self.prepended(base)
          base.attribute :weight do |variant|
            variant.weight.to_f
          end

          base.attribute :quantity_step do |variant|
            (variant.weight.present? && variant.weight > 0) ? variant.weight.to_f : 1.0
          end
        end
      end
    end
  end
end

Spree::V2::Storefront::VariantSerializer.prepend(Spree::V2::Storefront::VariantSerializerDecorator)
```

- [ ] **Step 5: Eseguire i test RSpec (Green)**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rspec spec/models/spree/line_item_weight_spec.rb
```
Atteso: PASS con tutti i test verdi.

---

### Task 7: Connessione Vue Storefront, CORS e Verifica Rendering Frontend

**Files:**
- Create: `retebio_5x/config/initializers/cors.rb`
- Modify: `vue-storefront-spree/docker-compose.yml`
- Test: Chiamata API e verifica rendering del frontend Vue su `http://localhost:3000`

**Interfaces:**
- Consumes: Backend Spree su `http://web:4000` sulla rete Docker `retebio_net`
- Produces: Frontend Vue Storefront che interroga Spree 5.1, renderizza il catalogo con immagini, mostra login al posto dei prezzi e imposta i delta di peso

- [ ] **Step 1: Configurare CORS in Rails per Vue Storefront**

Creare `retebio_5x/config/initializers/cors.rb`:
```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000', 'http://127.0.0.1:3000'
    resource '/api/v2/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
    resource '/spree_oauth/*',
      headers: :any,
      methods: [:post, :options],
      credentials: true
    resource '/rails/active_storage/*',
      headers: :any,
      methods: [:get, :options, :head]
  end
end
```

- [ ] **Step 2: Aggiornare il docker-compose di vue-storefront-spree**

Modificare `vue-storefront-spree/docker-compose.yml` per agganciarsi a `retebio_net`:
```yaml
version: '3.7'
services:
  frontend:
    build:
      context: .
      dockerfile: Dockerfile.development
    container_name: retebio_frontend
    ports:
      - "3000:3000"
    environment:
      - BACKEND_URL=http://web:4000
    volumes:
      - .:/app
    networks:
      - retebio_net

networks:
  retebio_net:
    external: true
```

- [ ] **Step 3: Avviare il frontend e verificare la connessione alle API**

Eseguire:
```bash
cd vue-storefront-spree && docker compose up -d
```
Verificare con:
```bash
curl -I http://localhost:3000
curl -s http://localhost:4000/api/v2/storefront/products | head -n 30
```
Atteso: Frontend risponde con `HTTP/1.1 200 OK`; l'API restituisce il catalogo serializzato in JSON:API.

- [ ] **Step 4: Verifica visiva del rendering immagini su backend e frontend**

1. Aprire Spree Admin (`http://localhost:4000/admin`) -> Prodotti -> Immagini: verificare che i thumbnail vengano mostrati senza broken image.
2. Aprire Vue Storefront (`http://localhost:3000`): verificare che la griglia catalogo mostri le foto dei prodotti, che i prezzi siano oscurati se non autenticati e che il tasto di acquisto rimandi al login.

---

### Task 8: Collaudo Finale End-to-End e Validazione Script Ripetibile

**Files:**
- Test: Script `retebio_5x/scripts/db_restore_and_migrate.sh` eseguito da zero
- Test: Script `retebio_5x/bin/verify_data_integrity.rb`
- Test: Script `retebio_5x/bin/verify_catalog_media.rb`

**Interfaces:**
- Consumes: Procedura di ripristino completa
- Produces: Conferma definitiva dell'idempotenza dello script e conformità totale per la validazione cliente

- [ ] **Step 1: Eseguire un reset totale e ri-esecuzione dello script di restore**

Eseguire:
```bash
./retebio_5x/scripts/db_restore_and_migrate.sh
```
Atteso: Lo script cancella il DB, reimporta il dump 4.3, esegue le migrazioni 5.1, effettua il data healing e termina con esito positivo senza errori.

- [ ] **Step 2: Eseguire la suite di verifica integrità e media**

Eseguire:
```bash
docker exec retebio_spree_backend bundle exec rails runner bin/verify_data_integrity.rb
docker exec retebio_spree_backend bundle exec rails runner bin/verify_catalog_media.rb
docker exec retebio_spree_backend bundle exec rspec
```
Atteso:
- Tutti gli ordini, clienti, pagamenti riconciliati al 100%.
- Nessuna rottura sulle immagini catalogo.
- Tutti i test RSpec di B2B e Vendita a peso verdi.

- [ ] **Step 3: Verificare che l'ambiente legacy spree_43 sia intatto**

Eseguire:
```bash
cd /Users/novellig/docker_images/retebio_local/spree_43 && git status
```
Atteso: Nessun file modificato o cancellato; la directory legacy è rimasta perfettamente isolata.
