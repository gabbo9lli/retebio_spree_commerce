# Guida al Deploy AWS per Retebio 5.x

Questa guida descrive la procedura completa per distribuire la nuova piattaforma containerizzata **Retebio 5.x** (Spree 5.1 Rails 8 + Vue Storefront 2 + Caddy + PostgreSQL + Redis) su un'istanza cloud **AWS a basso costo** ottimizzata per i test degli utenti o per la produzione.

---

## 1. Architettura e Dimensionamento Consigliato

Per contenere al minimo i costi di hosting (~$15 - $25 / mese) mantenendo ottime performance:

### Opzione A: AWS Lightsail (Scelta più semplice ed economica)
- **Tipo Istanza:** Lightsail Linux (Ubuntu 22.04 o 24.04 LTS)
- **Piano consigliato:**
  - Per test utenti: **2 GB RAM / 1 vCPU / 60 GB SSD** ($10/mese) oppure **4 GB RAM / 2 vCPU / 80 GB SSD** ($20/mese).
- **Vantaggi:** IP statico gratuito, traffico dati incluso (fino a 3 TB), firewall integrato nella console.

### Opzione B: AWS EC2 Graviton (ARM64 - Massimo rapporto prezzo/prestazioni)
- **Tipo Istanza:** `t4g.small` (2 GB RAM) oppure `t4g.medium` (4 GB RAM, 2 vCPU).
- **Disco:** 40-60 GB gp3 SSD.
- **Costo stimato:** ~$15-25/mese.

---

## 2. Configurazione Security Group / Firewall

Aprire le seguenti porte in ingresso (**Inbound Rules**):
- **Porta 22 (SSH):** Accesso per amministrazione server (limitabile al proprio IP).
- **Porta 80 (HTTP):** Richiesta da Caddy per la challenge ACME / redirect HTTPS.
- **Porta 443 (HTTPS):** Traffico web sicuro per storefront, API e admin.

---

## 3. Preparazione Server (Una Tantum)

Collegarsi via SSH all'istanza:
```bash
ssh -i ~/.ssh/tua_chiave.pem ubuntu@IP_PUBBLICO_AWS
```

Installare Docker e Docker Compose:
```bash
# Aggiornamento pacchetti
sudo apt-get update && sudo apt-get upgrade -y

# Installazione Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Riavviare la sessione per applicare i permessi di gruppo
exit
```

---

## 4. Clonazione Progetto e Configurazione `.env`

Ricollegarsi via SSH:
```bash
git clone git@github.com-gabbo9lli:gabbo9lli/retebio_5x.git retebio_5x
cd retebio_5x

# Creare il file .env di produzione partendo dal template
cp .env.example .env

# Generare una SECRET_KEY_BASE casuale e sicura
RANDOM_SECRET=$(openssl rand -hex 64)
sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$RANDOM_SECRET/" .env

# Configurare i propri domini e password nel file .env
nano .env
```

### Variabili chiave in `.env`:
```ini
POSTGRES_USER=postgres
POSTGRES_PASSWORD=una_password_robusta_qui
SECRET_KEY_BASE=la_chiave_esadecimale_generata

# Domini per certificati SSL automatici
STORE_DOMAIN=store.tuodominio.it
API_DOMAIN=api.tuodominio.it
SPREE_STORE_URL=api.tuodominio.it

# S3 (opzionale se si usa disco locale EBS)
ACTIVE_STORAGE_SERVICE=local
```

---

## 5. Esecuzione Deploy con Caddy & SSL

Eseguire lo script di deploy automatizzato:
```bash
./scripts/deploy_aws.sh
```

Lo script:
1. Compila le immagini Docker di produzione per Rails 8 e Nuxt.
2. Avvia i container: `retebio_caddy`, `retebio_backend`, `retebio_frontend`, `retebio_postgres`, `retebio_redis`.
3. Caddy ottiene automaticamente i certificati **SSL gratuiti Let's Encrypt** appena i record DNS puntano all'IP del server.

---

## 6. Ripristino Dati Storici di Produzione

Per caricare il dump di produzione con l'intero storico ordini, clienti e catalogo:
```bash
# Copiare il dump dal proprio computer locale al server
scp -i ~/.ssh/tua_chiave.pem dump_prod_241006.sql ubuntu@IP_PUBBLICO_AWS:~/retebio_5x/

# Eseguire lo script di ripristino automatico e migrazione
./scripts/db_restore_and_migrate.sh ./dump_prod_241006.sql
```

Lo script provvederà in autonomia a:
- Ripristinare tutti i 12.639 ordini, i 223 clienti e il catalogo.
- Eseguire le migrazioni a Spree 5.1.
- Allineare i ruoli admin per `admin@retebio.it`.
- Ricreare le viste di confine `listinoaccess` e `ordiniaccess`.

---

## 7. Manutenzione, Backup e Riavvio

- **Stato dei servizi:**
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.prod.yml ps
  ```
- **Log in tempo reale:**
  ```bash
  docker compose -f docker-compose.yml -f docker-compose.prod.yml logs -f
  ```
- **Backup giornaliero del database:**
  ```bash
  docker exec retebio_postgres pg_dump -U postgres retebio_production | gzip > backup_$(date +%Y%m%d).sql.gz
  ```
