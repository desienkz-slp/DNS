#!/bin/bash

# Output file untuk Unbound
OUT="/etc/unbound/blocklist/adult-redirect.conf"

# IP tujuan redirect (misalnya IP internal)
REDIRECT_IP="172.18.20.234"

# Kosongkan file output
> "$OUT"

# Baca file domain dan tulis config unbound
while read -r domain; do
  # Hilangkan spasi/kosong di awal/akhir
  domain=$(echo "$domain" | xargs)

  # Lewati baris kosong
  [ -z "$domain" ] && continue

  echo "local-zone: \"$domain.\" redirect" >> "$OUT"
  echo "local-data: \"$domain. A $REDIRECT_IP\"" >> "$OUT"
  echo "local-data: \"www.$domain. A $REDIRECT_IP\"" >> "$OUT"
done < /etc/unbound/blocklist/adult-domains.txt

echo "✅ File selesai dibuat: $OUT"
