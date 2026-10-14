#!/usr/bin/env bash
# ==============================================================================
# Script di Deploy Automatico AWS (EC2 Graviton / Lightsail) per Retebio 5.x
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

echo "=================================================================="
echo "    RETEBIO 5.x - Script di Deploy Produzione AWS / Test"
echo "=================================================================="

# 1. Verifica Prerequisiti Docker
if ! command -v docker &> /dev/null; then
  echo "ERRORE: Docker non risulta installato sul server."
  echo "Installa Docker con: curl -fsSL https://get.docker.com | sh"
  exit 1
fi

if ! docker compose version &> /dev/null; then
  echo "ERRORE: Docker Compose non risulta installato o abilitato."
  exit 1
fi

# 2. Verifica del file .env di produzione
if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "ATTENZIONE: File .env non trovato. Generazione da .env.example..."
  cp "$ROOT_DIR/.env.example" "$ROOT_DIR/.env"
  # Genera una SECRET_KEY_BASE casuale sicura
  RANDOM_SECRET=$(openssl rand -hex 64 2>/dev/null || date +%s | sha256sum | base64 | head -c 64)
  sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$RANDOM_SECRET/" "$ROOT_DIR/.env"
  echo "File .env creato con nuova SECRET_KEY_BASE casuale."
  echo "IMPORTANTE: Modifica '$ROOT_DIR/.env' inserendo i domini effettivi e le credenziali prima di proseguire."
fi

# 3. Costruzione e Avvio Container Produzione
echo ""
echo "[1/4] Build e preparazione container di produzione (Caddy, Backend, Frontend, Postgres, Redis)..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml build

echo ""
echo "[2/4] Avvio stack di produzione con Caddy reverse proxy e SSL automatico..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 4. Attesa avvio e Healthcheck
echo ""
echo "[3/4] Verifica dello stato dei servizi..."
sleep 5
docker compose -f docker-compose.yml -f docker-compose.prod.yml ps

# 5. Ripristino del database se richiesto
if [[ "$*" == *"--restore-dump"* ]]; then
  echo ""
  echo "[Opzionale] Esecuzione ripristino database dal dump di produzione..."
  "$SCRIPT_DIR/db_restore_and_migrate.sh"
fi

echo ""
echo "=================================================================="
echo " Deploy completato con successo!"
echo " Servizi attivi:"
echo " - Storefront:    https://${STORE_DOMAIN:-store.retebio.it}"
echo " - Spree Admin:   https://${API_DOMAIN:-api.retebio.it}/admin"
echo " - Caddy Proxy:   Porte 80 / 443 con certificati Let's Encrypt SSL"
echo "=================================================================="
