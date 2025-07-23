#!/bin/bash

# Output file untuk Unbound
OUT="/etc/unbound/blocklist/adult-redirect.conf"

# IP tujuan redirect
REDIRECT_IP="172.18.20.234"

# Input file domain ABP-style
INPUT="/etc/unbound/blocklist/adult-domains.txt"

# Kosongkan file output
> "$OUT"

# Proses setiap baris domain
while read -r raw_domain; do
  # Hilangkan whitespace
  raw_domain=$(echo "$raw_domain" | xargs)

  # Lewati baris kosong
  [ -z "$raw_domain" ] && continue

  # Bersihkan domain dari karakter ABP: ||, ^, *.
  clean_domain=$(echo "$raw_domain" | sed -E 's/^\|\|//; s/\^$//; s/^\*\.\?//')

  # Lewati jika setelah dibersihkan tetap kosong
  [ -z "$clean_domain" ] && continue

  # Tulis ke file konfigurasi Unbound
  echo "local-zone: \"$clean_domain.\" redirect" >> "$OUT"
  echo "local-data: \"$clean_domain. A $REDIRECT_IP\"" >> "$OUT"
  echo "local-data: \"www.$clean_domain. A $REDIRECT_IP\"" >> "$OUT"
done < "$INPUT"

echo "✅ File selesai dibuat: $OUT"
