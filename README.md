# Retebio: Spree Commerce 5.x Headless + Vue Storefront

Piattaforma e-commerce per **Retebio** basata su architettura **Headless**, completamente containerizzata con Docker e Docker Compose.

---

## 🏗 Architettura

- **Backend**: Spree Commerce 5.1 su Ruby 3.3.0 e Rails 8.0.2 (Headless: Storefront API v2 + Spree Admin).
- **Frontend**: Vue Storefront (Vue.js / Nuxt / Storefront UI).
- **Database**: PostgreSQL 16.
- **Cache & Code**: Redis 7 & Sidekiq.
- **Media & Immagini**: Active Storage (locale in dev, Amazon S3 in produzione).
- **Reverse Proxy**: Caddy (produzione con HTTPS / SSL Let's Encrypt automatico).

---

## 🚀 Avvio Rapido Locale (Docker)

Per avviare l'intero stack applicativo:

```bash
# Avvio di tutti i container in background
docker compose up -d

# Verifica dello stato dei servizi
docker compose ps
```

### Endpoint Principali:
- **Storefront Clienti (Vue Storefront)**: [http://localhost:3000](http://localhost:3000)
- **Pannello di Controllo Spree Admin**: [http://localhost:4000/admin](http://localhost:4000/admin)
  - *Credenziali test*: `admin@retebio.it` / `password123`
- **Storefront API v2**: [http://localhost:4000/api/v2/storefront/products](http://localhost:4000/api/v2/storefront/products)
- **Healthcheck**: [http://localhost:4000/up](http://localhost:4000/up)

---

## 🔄 Procedura Ripetibile di Restore e Migrazione Dati

Per ripristinare il database storico da un dump SQL di produzione ed eseguire l'allineamento automatico allo schema Spree 5.1:

```bash
./scripts/db_restore_and_migrate.sh [percorso_al_dump.sql]
```

Lo script è **completamente automatizzato e idempotente**:
1. Resetta ed elimina il database con terminazione forzata delle connessioni attive (`DROP DATABASE ... WITH (FORCE)`).
2. Ricrea `retebio_development` e importa il dump specificato.
3. Sanitizza e allinea le migrazioni schema.
4. Esegue le migrazioni di Spree 5.x.
5. Assegna lo store predefinito e sincronizza gli account amministratore.
6. Riavvia Puma e genera un log dettagliato in `backend/tmp/migration_YYYYMMDD_HHMMSS.log`.

---

## 🧪 Suite di Test e Verifiche

```bash
# Esecuzione test RSpec (B2B, Vendita a peso, Redirect root)
docker exec -e RAILS_ENV=test retebio_backend bundle exec rspec

# Verifica integrità dati storici (ordini, clienti, catalogo)
docker exec retebio_backend bundle exec rails runner bin/verify_data_integrity.rb

# Verifica immagini media catalogo e Active Storage
docker exec retebio_backend bundle exec rails runner bin/verify_catalog_media.rb
```

---

## ☁️ Deployment su AWS a Costi Minimi (~$15–$25/mese)

L'architettura di produzione è ottimizzata per minimizzare al massimo i costi cloud:

1. **Infrastruttura consigliata**:
   - Singola istanza **AWS EC2 `t4g.small`** (2 vCPU, 2 GB RAM, architettura ARM Graviton) a circa **$12/mese**, oppure **AWS Lightsail** 4 GB RAM a **$20/mese**.
2. **Media Storage**:
   - I file di Active Storage vengono salvati su **Amazon S3** (`ACTIVE_STORAGE_SERVICE=amazon`), con costi nell'ordine di **pochi centesimi al mese** ($0.023/GB).
3. **SSL e Reverse Proxy**:
   - **Caddy** gestisce automaticamente i certificati SSL gratuiti via Let's Encrypt per i domini configurati (`STORE_DOMAIN` e `API_DOMAIN`).

### Avvio in Produzione:

```bash
# 1. Configurare le variabili d'ambiente
cp .env.example .env
# Editare .env con domini, secret e credenziali S3

# 2. Avviare con l'override di produzione
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```
