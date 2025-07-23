#!/bin/bash

echo "🔁 Mengupdate daftar blocklist..."

# Update daftar iklan
curl -s https://raw.githubusercontent.com/ABPindo/indonesianadblockrules/master/subscriptions/abpindo.txt -o /etc/unbound/blocklist/block-ads.txt

# Update daftar malware
curl -s https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -o /etc/unbound/blocklist/block-malware.txt

# Update daftar domain dewasa
curl -s https://raw.githubusercontent.com/alexsannikov/adguardhome-filters/refs/heads/master/porn.txt -o /etc/unbound/blocklist/adult-domains.txt

# Update daftar tambahan dari kamu sendiri
curl -s -H "Authorization: token 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" "https://raw.githubusercontent.com/desienkz-slp/DNS/main/gen-adult-block.sh" -o /etc/unbound/blocklist/gen-adult-block.sh


echo "✅ Semua blocklist diperbarui!"
