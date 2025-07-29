#!/bin/bash

echo "🔁 Mengupdate daftar blocklist..."

# Update daftar iklan
curl -s https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/popupads.txt -o /etc/unbound/blocklist/block-ads.txt

# Update daftar malware
curl -s https://raw.githubusercontent.com/hagezi/dns-blocklists/main/hosts/light.txt -o /etc/unbound/blocklist/block-malware.txt

# Update daftar domain dewasa
curl -s https://raw.githubusercontent.com/alexsannikov/adguardhome-filters/refs/heads/master/porn.txt -o /etc/unbound/blocklist/adult-domains.txt

# Update daftar tambahan dari kamu sendiri
curl -s -H "Authorization: token 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"  -L "https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/block_mine.txt"   -o /etc/unbound/blocklist/block-mine.txt

echo "✅ Semua blocklist diperbarui!"
