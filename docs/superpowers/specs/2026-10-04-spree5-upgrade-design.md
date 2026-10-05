# Design Spec: Upgrade Retebio a Spree 5.x Headless con Dati Storici e Vue Storefront

- **Data**: 2026-10-04
- **Stato**: Approvato dal committente (Design completato)
- **Target**: Spree Commerce 5.x (Headless) + Vue Storefront + PostgreSQL 16 + Redis
- **Directory Progetto**: `/Users/novellig/docker_images/retebio_local/retebio_5x`
- **Ambiente**: Docker (100% containerizzato, ambiente sandbox isolato)

---

## 1. Contesto e Obiettivi

### 1.1 Contesto AS-IS
Il sistema attuale di Retebio si basa su un fork modificato di Spree Commerce 4.3.1 (Rails 6.1, Ruby 2.7.2). Le personalizzazioni storiche includono:
1. **Negozio B2B ad accesso riservato**: Prezzi, totali e carrello oscurati agli utenti non autenticati (`_cart_form.html.erb`, `_product.html.erb`, `_line_item_data.html.erb`, `orders/edit.html.erb`). Checkout anonimo disabilitato.
2. **Vendita a collo / proporzionale al peso**: Step di quantità e quantità minima legati al peso (`product.weight`), con logica JavaScript modificata direttamente nel core (`cart.js`, `quantity_select.js`).
3. **Modifiche allo schema core**: Soft-deletion su `Spree::Store` (`acts_as_paranoid`) e migrazione custom su store.

I dati storici di produzione (ordini, clienti, indirizzi, pagamenti, catalogo e immagini) sono contenuti nei dump SQL (`dump_prod_241006.sql`).

### 1.2 Obiettivi del Progetto
- **Salto Diretto a Spree 5.x (Headless)**: Modernizzazione dello stack su Ruby 3.3+ / Rails 8.0 / Spree 5.x.
- **Nessuna modifica al core**: Tutte le logiche custom (B2B, peso, validazioni) devono risiedere esclusivamente in decoratori Rails, serializer e moduli isolati.
- **Frontend Decoupled**: Storefront moderno basato su Vue (Vue Storefront), comunicante tramite le Storefront API v2 di Spree.
- **Integrità Totale dei Dati Storici**: Preservazione al 100% di ordini, clienti, pagamenti, catalogo e immagini Active Storage.
- **Procedura di Restore Ripetibile e Scriptata**: Poiché questa è un'attività di collaudo/test, l'intera pipeline di restore e migrazione DB deve essere automatizzata in uno script idempotente per essere rieseguita in fase di go-live davanti al cliente su dump fresco.
- **Verifica Completa Immagini Media**: Garanzia di corretta associazione e visualizzazione delle immagini catalogo sia nel backend (Spree Admin / Active Storage) sia nel frontend (Vue Storefront).
- **Isolamento dell'Ambiente Legacy**: La codebase attuale (`spree_43`) e i dump originali rimangono intatti e inalterati.

---

## 2. Architettura del Sistema e Containerizzazione Docker

Tutti i componenti del nuovo stack risiedono in container Docker orchestrati da `docker-compose.yml`, collegati tramite una rete interna isolata (`retebio_net`):

```
+-----------------------------------------------------------------------------------+
|                              DOCKER ENVIRONMENT                                   |
|                                                                                   |
|  +--------------------+                     +----------------------------------+  |
|  |                    |  HTTP / API Calls   |                                  |  |
|  |   vue-storefront   | <=================> |           spree-backend          |  |
|  |     (Port 3000)    |  (Bearer Token)     |      (Spree 5.x API / Admin)     |  |
|  |                    |                     |            (Port 4000)           |  |
|  +--------------------+                     +----------------------------------+  |
|                                                              |                    |
|                                              +---------------+---------------+    |
|                                              |                               |    |
|                                              v                               v    |
|                                      +---------------+               +---------+  |
|                                      |   postgres    |               |  redis  |  |
|                                      | (PostgreSQL)  |               | (Cache) |  |
|                                      +---------------+               +---------+  |
|                                              |                                    |
|                                              v                                    |
|                                      [ Volume storage/ ]                          |
|                                     (Active Storage Media)                        |
+-----------------------------------------------------------------------------------+
```

### Servizi Docker:
1. **`postgres`**: PostgreSQL (15 o 16), porta 5432. Volume persistente per i dati di sviluppo/test (`retebio_pgdata`).
2. **`redis`**: Redis 7 per caching e code di background (Sidekiq / Active Job).
3. **`spree-backend`**:
   - Ruby 3.3+, Rails 8.x, Spree ~> 5.1 (`spree_api`, `spree_admin`, `spree_emails`).
   - `spree_storefront` (HTML classico Rails) disabilitato in favore dell'approccio headless.
   - Volume montato per `storage/` per gestire i file fisici di Active Storage.
4. **`vue-storefront`**:
   - Node.js runtime per l'applicazione Vue Storefront.
   - Espone la UI per i clienti su porta 3000.

---

## 3. Strategia di Migrazione Database e Procedura di Restore Ripetibile

### 3.1 Script Automatizzato di Restore e Migrazione (`retebio_5x/scripts/db_restore_and_migrate.sh`)
Lo script sarà completamente autonomo, parametrizzabile con il percorso del dump e idempotente:

```bash
#!/usr/bin/env bash
# Uso: ./retebio_5x/scripts/db_restore_and_migrate.sh [path_to_dump.sql]
```

**Fasi eseguite dallo script:**
1. **Pulizia Database**: Esecuzione di `DROP DATABASE IF EXISTS retebio_development; CREATE DATABASE retebio_development;` nel container postgres.
2. **Restore del Dump**: Esecuzione di `psql` (o `pg_restore`) a partire dal file di dump (supporto `.sql` o `.sql.zip`/`.sql.gz`).
3. **Pre-Migration Sanitization**:
   - Rimozione o normalizzazione di colonne/indici legacy del vecchio fork (es. colonna `deleted_at` su `spree_stores`).
   - Normalizzazione `schema_migrations` per evitare conflitti con i timestamp di Spree 4.3 vs 5.x.
4. **Esecuzione Migrazioni Spree 5.x**:
   - `bundle exec rails spree:install:migrations`
   - `bundle exec rails db:migrate` con output rediretto su log dedicato (`retebio_5x/tmp/migration_YYYYMMDD_HHMM.log`).
5. **Data Healing / Sanity Post-Migrazione**:
   - Associazione dello store predefinito a ordini, pagamenti e prodotti che dovessero risultare privi di `store_id`.
   - Verifica chiavi esterne e consistenza delle valute (`EUR`).
6. **Report di Validazione**:
   - Stampa a video del riepilogo conteggi pre vs post migrazione.

---

## 4. Riprogettazione delle Personalizzazioni di Business (Headless)

### 4.1 Modello B2B: Prezzi Riservati e Checkout Protetto
- **Backend - Serializer Decorators (`app/serializers/spree/v2/storefront/product_serializer_decorator.rb`)**:
  - Se la richiesta non include un utente autenticato (`current_spree_user.nil?`), i campi di prezzo (`price`, `display_price`, `compare_at_price`) vengono restituiti come `null`.
- **Backend - Carrello e Checkout Gated**:
  - Decoratore sul controller API `/api/v2/storefront/cart` per bloccare chiamate da utenti anonimi (`render_error_payload` con codice `unauthorized`).
- **Frontend Vue**:
  - In assenza di token utente: sostituisce il blocco prezzo e "Aggiungi al carrello" con un messaggio di login (*"Accedi per visualizzare i prezzi e acquistare"*).

### 4.2 Vendita a Collo / Multipli del Peso (`product.weight`)
- **Backend - Validazione Modello (`app/models/spree/line_item_decorator.rb`)**:
  - Validazione: se la variante ha un `weight > 0`, la `quantity` dell'ordine deve essere un multiplo valido del peso (o step calcolato).
- **Backend - Serializer (`app/serializers/spree/v2/storefront/variant_serializer_decorator.rb`)**:
  - Esposizione esplicita degli attributi `weight`, `quantity_step` e `min_quantity`.
- **Frontend Vue**:
  - Il componente selettore quantità regola il delta di incremento/decremento (`+ / -`) sui multipli del peso forniti dall'API.

---

## 5. Integrazione Headless & Vue Storefront

### 5.1 Autenticazione e Sicurezza
- **Doorkeeper (OAuth 2.0 nativo di Spree)**:
  - Generazione token Bearer tramite `POST /spree_oauth/token` (grant type: `password`).
  - Refresh token gestito automaticamente prima della scadenza.
- **CORS (`config/initializers/cors.rb`)**:
  - `rack-cors` configurato con origini consentite (il dominio e porta di Vue Storefront), con supporto a credenziali e header di autorizzazione.

### 5.2 Gestione Carrello su API v2
- Gli endpoint utilizzati da Vue Storefront:
  - `GET /api/v2/storefront/cart`: Recupero carrello corrente dell'utente autenticato.
  - `POST /api/v2/storefront/cart/add_item`: Aggiunta prodotto (validazione quantità a multipli del peso).
  - `PATCH /api/v2/storefront/cart/set_quantity`: Aggiornamento riga carrello.
  - `DELETE /api/v2/storefront/cart/remove_line_item/:id`: Eliminazione riga carrello.

---

## 6. Gestione e Verifica delle Immagini e Media del Catalogo

### 6.1 Backend (Active Storage & Spree Admin)
- **Persistenza**:
  - I record in `active_storage_blobs` e `active_storage_attachments` del dump puntano ai file fisici tramite la chiave generata (es. `4wm5989uq9dvtoihkz7n8w59wrdx`).
  - Un volume Docker monta la directory `storage/` condivisa.
- **Script di Validazione Media (`bin/verify_catalog_media.rb`)**:
  - Esegue la scansione di tutti i prodotti e relative immagini (`Spree::Product` -> `images`).
  - Verifica per ciascuna immagine se il blob è presente su disco o storage service.
  - Restituisce report: Totale immagini catalogo, Immagini con file fisico valido, Immagini orfane/mancanti.
- **Verifica Spree Admin**:
  - Controllo visivo e via test automatico che la scheda prodotto in `/admin/products/:id/images` visualizzi correttamente i thumbnail e l'anteprima senza errori 404 o broken image.

### 6.2 Frontend (Vue Storefront)
- **Serializzazione URL**:
  - Spree Storefront API v2 serializza le immagini con percorsi corretti (es. `styles: [mini, small, product, large]`).
  - Verifica che gli URL generati dall'API siano raggiungibili dal browser client e dal container Vue.
- **Verifica Rendering UI**:
  - Pagina Categoria (PLP): le card prodotto devono mostrare l'immagine principale del catalogo con fallback per prodotti privi di foto.
  - Scheda Prodotto (PDP): galleria immagini funzionante con visualizzazione ad alta risoluzione.

---

## 7. Piano di Collaudo, Criteri di Accettazione e Rollback

### 7.1 Riconciliazione Dati Storici (Pre vs Post Migrazione)
Lo script di migrazione eseguirà query di conteggio e controllo per garantire zero perdite:
| Entità | Controllo Pre-Migrazione (Dump 4.3) | Controllo Post-Migrazione (Spree 5.x) | Tolleranza |
|---|---|---|---|
| **Utenti / Clienti** | `SELECT count(*) FROM spree_users;` | `Spree::User.count` | 0 differenze |
| **Ordini Totali** | `SELECT count(*) FROM spree_orders;` | `Spree::Order.count` | 0 differenze |
| **Ordini Completati** | `SELECT count(*) FROM spree_orders WHERE completed_at IS NOT NULL;` | `Spree::Order.complete.count` | 0 differenze |
| **Line Items** | `SELECT count(*) FROM spree_line_items;` | `Spree::LineItem.count` | 0 differenze |
| **Pagamenti** | `SELECT count(*) FROM spree_payments;` | `Spree::Payment.count` | 0 differenze |
| **Totale Valore Ordini** | `SELECT sum(total) FROM spree_orders WHERE completed_at IS NOT NULL;` | Somma totale ordini completati | 0 differenze |
| **Prodotti Catalogo** | `SELECT count(*) FROM spree_products;` | `Spree::Product.count` | 0 differenze |
| **Immagini Media** | `SELECT count(*) FROM spree_assets;` | `Spree::Asset.count` | 0 differenze |

### 7.2 Test Automatici (RSpec)
1. **B2B Test**:
   - Richiesta `GET /api/v2/storefront/products` anonima: campi prezzo `null`.
   - Richiesta `GET /api/v2/storefront/products` autenticata: campi prezzo visibili con valori corretti.
   - Richiesta `POST /api/v2/storefront/cart/add_item` anonima: `401 Unauthorized`.
2. **Vendita a Peso Test**:
   - Aggiunta prodotto con peso 2.5 kg con quantità 5 -> Successo.
   - Aggiunta prodotto con peso 2.5 kg con quantità 3 -> Fallimento con errore di validazione esplicito.
3. **Media Image Test**:
   - Serializer restituisce array di immagini con URL validi e risolvibili.

### 7.3 Rollback e Sicurezza
- La directory `spree_43` esistente non viene mai modificata né rimossa.
- I file di dump SQL di produzione rimangono protetti in sola lettura.
- In caso di esito negativo o necessità di ripartenza da zero, il database PostgreSQL containerizzato può essere azzerato e ricaricato tramite `scripts/db_restore_and_migrate.sh` in pochi minuti.
