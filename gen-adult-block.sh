#!/bin/bash

OUT="/etc/unbound/blocklist/adult-redirect.conf"
REDIRECT_IP="172.18.20.234"
INPUT="/etc/unbound/blocklist/adult-domains.txt"

> "$OUT"
declare -A zone_seen

while read -r line; do
  domain=$(echo "$line" | xargs | sed -E 's/^\|\|//; s/\^$//; s/\*$//; s/^\*\.?//')
  [ -z "$domain" ] && continue

  fqdn="${domain}."
  if [[ -n "${zone_seen[$fqdn]}" ]]; then
    continue
  fi
  zone_seen[$fqdn]=1

  echo "local-zone: \"$fqdn\" redirect" >> "$OUT"
  echo "local-data: \"$fqdn A $REDIRECT_IP\"" >> "$OUT"
done < "$INPUT"

echo "✅ File selesai dibuat tanpa subdomain dalam redirect zone: $OUT"
