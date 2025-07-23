#!/bin/bash
OUT="/etc/unbound/blocklist/adult-redirect.conf"
REDIRECT_IP="172.18.20.234"
> "\$OUT"

while read domain; do
  echo "local-data: \"\$domain A \$REDIRECT_IP\"" >> "\$OUT"
  echo "local-data: \"www.\$domain A \$REDIRECT_IP\"" >> "\$OUT"
done < /etc/unbound/blocklist/adult-domains.txt
