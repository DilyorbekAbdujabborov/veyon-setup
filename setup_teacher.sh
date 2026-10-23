#!/usr/bin/env bash
# Linux o'qituvchi kompyuteri uchun: kompyuterlar ro'yxatini serverdan olib, xonalar bilan Veyon Master'ga qo'shadi.
set -euo pipefail

SERVER="https://true-ruling-vervet.ngrok-free.app"
ROOM=""   # bo'sh bo'lsa hamma xonalar olinadi

if ! command -v veyon-cli >/dev/null; then
  echo "[XATO] veyon-cli topilmadi. Avval Veyon o'rnating." >&2
  exit 1
fi

# Sozlamani yozish uchun root kerak
if [ "$(id -u)" -ne 0 ]; then
  exec sudo "$0" "$@"
fi

CSV="$(mktemp)"
trap 'rm -f "$CSV"' EXIT

echo "[1/3] Kompyuterlar ro'yxati serverdan olinmoqda ($SERVER)..."
url="$SERVER/computers.csv"
[ -n "$ROOM" ] && url="$url?room=$ROOM"
if ! curl -fsSL --max-time 15 -H 'ngrok-skip-browser-warning: 1' -o "$CSV" "$url"; then
  echo "[XATO] Serverga ulanib bo'lmadi. Server va ngrok ishlayotganini tekshiring." >&2
  exit 1
fi

count="$(grep -c . "$CSV" || true)"
if [ "$count" -eq 0 ]; then
  echo "[XATO] Serverda hali birorta kompyuter ro'yxatdan o'tmagan." >&2
  exit 1
fi
echo "  $count ta kompyuter topildi"

echo "[2/3] Eski xona va kompyuterlar tozalanmoqda..."
veyon-cli networkobjects clear

echo "[3/3] Xonalar yaratilib, kompyuterlar qo'shilmoqda..."
veyon-cli networkobjects import "$CSV" format '%location%;%name%;%host%;%mac%'

echo
veyon-cli networkobjects list
echo
echo "Tayyor! Veyon Master'ni qayta oching."
