#!/usr/bin/env bash
# Serverni bir marta tayyorlaydi: paketlar, server/.env (PUBLIC_URL) va o'qituvchi kaliti (public.pem).
# Ishga tushirish: ./server_setup.sh   yoki   ./server_setup.sh https://domen.ngrok-free.app
set -euo pipefail
cd "$(dirname "$0")"

say() { printf '%s\n' "$*"; }
die() { printf '[XATO] %s\n' "$*" >&2; exit 1; }

# 1. Node.js 20.12+ (.env ni o'qish uchun)
command -v node >/dev/null || die "Node.js topilmadi. https://nodejs.org dan o'rnating (20.12 yoki yangi)."
command -v npm >/dev/null || die "npm topilmadi."
node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>20||(a===20&&b>=12)?0:1)' \
  || die "Node.js 20.12 yoki yangi kerak (hozir: $(node -v))."

# 2. Paketlar
say "[1/4] Paketlar o'rnatilmoqda..."
(cd server && npm install --no-audit --no-fund --silent)

# 3. server/.env va PUBLIC_URL
say "[2/4] Sozlamalar (server/.env)..."
[ -f server/.env ] || cp server/.env.example server/.env
current="$(grep -E '^PUBLIC_URL=' server/.env | head -1 | cut -d= -f2- || true)"
url="${1:-}"
if [ -z "$url" ]; then
  if [ -n "$current" ] && [ "$current" != "https://your-domain.ngrok-free.app" ]; then
    url="$current"
    say "  PUBLIC_URL: $url (o'zgarmadi)"
  else
    read -r -p "  Public URL (masalan https://nom.ngrok-free.app): " url
  fi
fi
url="${url%/}"
[[ "$url" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?$ ]] || die "PUBLIC_URL noto'g'ri: '$url' (https://domen.ngrok-free.app ko'rinishida bo'lsin)"
sed -i "s|^PUBLIC_URL=.*|PUBLIC_URL=$url|" server/.env
say "  PUBLIC_URL=$url"

# 4. O'qituvchi kaliti
say "[3/4] O'qituvchi kaliti (public.pem)..."
if [ -f public.pem ]; then
  say "  public.pem bor."
elif command -v veyon-cli >/dev/null && veyon-cli authkeys export teacher/public public.pem >/dev/null 2>&1; then
  say "  Veyon'dan chiqarib olindi: public.pem"
else
  say "  [OGOHLANTIRISH] public.pem yo'q. Shogirdlar kalit ola olmaydi."
  say "  Yaratish: veyon-cli authkeys create teacher && veyon-cli authkeys export teacher/public public.pem"
fi

# 5. ngrok
say "[4/4] ngrok..."
command -v ngrok >/dev/null && say "  ngrok bor." || say "  [OGOHLANTIRISH] ngrok topilmadi: https://ngrok.com/download (va 'ngrok config add-authtoken ...')"

say ""
say "Tayyor. Ishga tushirish:  ./start.sh"
