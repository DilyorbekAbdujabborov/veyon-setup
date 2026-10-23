#!/usr/bin/env bash
# Serverni va ngrok tunnelini birga ishga tushiradi (Ctrl+C - ikkalasini to'xtatadi).
set -euo pipefail
cd "$(dirname "$0")/server"

[ -f .env ] || { echo "[XATO] server/.env yo'q. Avval ./server_setup.sh ni ishga tushiring." >&2; exit 1; }
set -a; . ./.env; set +a
: "${PUBLIC_URL:?server/.env ichida PUBLIC_URL yozilmagan}"
domain="${PUBLIC_URL#*://}"; domain="${domain%%/*}"

node server.js &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT INT TERM

echo "Tunnel: $PUBLIC_URL -> localhost:${PORT:-3100}"
ngrok http "${PORT:-3100}" --url="$domain" --log=stdout
