#!/bin/bash

# Output file
OUT="/etc/unbound/blocklist/adult-redirect.conf"

# IP tujuan redirect
REDIRECT_IP="172.18.20.234"

# File input
INPUT="/etc/unbound/blocklist/adult-domains.txt"

# Kosongkan output
> "$OUT"

# Gunakan associative array untuk deteksi duplikat
declare -A domain_seen

while read -r raw_domain; do
  raw_domain=$(echo "$raw_domain" | xargs)
  [ -z "$raw_domain" ] && continue

  # Bersihkan dari karakter ABP
  clean_domain=$(echo "$raw_domain" | sed -E 's/^\|\|//; s/\^$//; s/^\*\.\?//')

  # Lewati duplikat
  if [[ -n "${domain_seen[$clean_domain]}" ]]; then
    continue
  fi
  domain_seen[$clean_domain]=1

  # Tulis hanya jika unik
  echo "local-zone: \"$clean_domain.\" redirect" >> "$OUT"
  echo "local-data: \"$clean_domain. A $REDIRECT_IP\"" >> "$OUT"
  echo "local-data: \"www.$clean_domain. A $REDIRECT_IP\"" >> "$OUT"
done < "$INPUT"

echo "✅ File selesai dibuat tanpa duplikat: $OUT"
