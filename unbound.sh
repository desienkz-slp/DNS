#!/bin/bash

# ===============================================
#  SETUP UNBOUND DNS RESOLVER + DoH + FILTERING
#  FITUR:
#   - DNS-over-HTTPS (Cloudflare + Google via cloudflared)
#   - Blok iklan & malware (StevenBlack + CEDIA)
#   - Safe Search
#   - Blokir konten dewasa + redirect ke IP lokal
#   - Monitoring statistik cache (hit/miss/log)
#   - Static record lokal
#   - Auto update blocklist via cron
# ===============================================

# === 1. Install Unbound & Tools ===
sudo apt update && sudo apt install unbound curl wget -y

# === 2. Install cloudflared ===
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
sudo mkdir -p /etc/cloudflared

# === 3. Konfigurasi cloudflared ===

## Cloudflare DoH (port 5053)
cat <<EOF | sudo tee /etc/cloudflared/cloudflare-doh.yml
proxy-dns: true
proxy-dns-port: 5053
upstream:
 - https://1.1.1.1/dns-query
 - https://1.0.0.1/dns-query
EOF

## Google DoH (port 5353)
cat <<EOF | sudo tee /etc/cloudflared/google-doh.yml
proxy-dns: true
proxy-dns-port: 5353
upstream:
 - https://dns.google/dns-query
EOF

# === 4. Systemd cloudflared service ===

## Cloudflare
cat <<EOF | sudo tee /etc/systemd/system/cloudflared-cloudflare.service
[Unit]
Description=cloudflared DoH - Cloudflare
After=network.target

[Service]
ExecStart=/usr/local/bin/cloudflared --config /etc/cloudflared/cloudflare-doh.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

## Google
cat <<EOF | sudo tee /etc/systemd/system/cloudflared-google.service
[Unit]
Description=cloudflared DoH - Google
After=network.target

[Service]
ExecStart=/usr/local/bin/cloudflared --config /etc/cloudflared/google-doh.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Aktifkan kedua service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared-cloudflare.service
sudo systemctl enable --now cloudflared-google.service

# === 5. Siapkan Blocklist ===
sudo mkdir -p /etc/unbound/blocklist
cd /etc/unbound/blocklist

# Script auto-update blocklist
curl -s -H "Authorization: token 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"  -L "https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/update-list.sh"   -o /etc/unbound/blocklist/update-list.sh
sudo chmod +x /etc/unbound/blocklist/update-lists.sh
sudo /etc/unbound/blocklist/update-lists.sh

# Script blok iklan & malware
cat <<EOF | sudo tee /etc/unbound/blocklist/gen-block.conf.sh
#!/bin/bash

# Sumber data
ADS_SRC="/etc/unbound/blocklist/block-ads.txt"
MAL_SRC="/etc/unbound/blocklist/block-malware.txt"
ADS_SRC2="/etc/unbound/blocklist/block-mine.txt"

# Output konfigurasi Unbound
OUT="/etc/unbound/blocklist/ad-malware-block.conf"
TMP="/tmp/adblock-clean.tmp"

# Pastikan file input ada
if [[ ! -f "$ADS_SRC" || ! -f "$MAL_SRC" ]]; then
    echo "❌ ERROR: File sumber $ADS_SRC atau $MAL_SRC tidak ditemukan!"
    exit 1
fi

# Kosongkan file sementara
> "$TMP"

echo "🔁 Memproses daftar iklan (ABP format)..."
grep '^||' "$ADS_SRC" \
  | sed -E 's/^\|\|([^\/\^$\*]+).*/\1/' \
  | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -Ev '[^a-zA-Z0-9.-]' \
  | sort -u \
  | awk '{print "local-zone: \"" $1 "\" static"}' >> "$TMP"

echo "🔁 Memproses daftar iklan (MINE format)..."
grep '^||' "$ADS_SRC2" \
  | sed -E 's/^\|\|([^\/\^$\*]+).*/\1/' \
  | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -Ev '[^a-zA-Z0-9.-]' \
  | sort -u \
  | awk '{print "local-zone: \"" $1 "\" static"}' >> "$TMP"


echo "🔁 Memproses daftar malware (hosts format)..."
grep -E '^(0\.0\.0\.0|127\.0\.0\.1)' "$MAL_SRC" \
  | awk '{print $2}' \
  | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -Ev '[^a-zA-Z0-9.-]' \
  | sort -u \
  | awk '{print "local-zone: \"" $1 "\" static"}' >> "$TMP"

# Hapus duplikat akhir
sort -u "$TMP" > "$OUT"
rm -f "$TMP"

echo "🔍 Mengecek konfigurasi Unbound..."
if unbound-checkconf; then
    echo "✅ Konfigurasi OK! Me-restart Unbound..."
    systemctl restart unbound
    echo "✅ Blocklist berhasil diperbarui & Unbound di-restart."
else
    echo "❌ ERROR: Cek manual isi blocklist yang error!"
    head -n 10 "$OUT"
fi


EOF
sudo chmod +x /etc/unbound/blocklist/gen-block.conf.sh
sudo /etc/unbound/blocklist/gen-block.conf.sh

# Script blok konten dewasa
cat <<EOF | sudo tee /etc/unbound/blocklist/gen-adult-block.sh
#!/bin/bash
OUT="/etc/unbound/blocklist/adult-redirect.conf"
REDIRECT_IP="172.18.20.234"
> "\$OUT"

while read domain; do
  echo "local-data: \"\$domain A \$REDIRECT_IP\"" >> "\$OUT"
  echo "local-data: \"www.\$domain A \$REDIRECT_IP\"" >> "\$OUT"
done < /etc/unbound/blocklist/adult-domains.txt
EOF

cat <<EOF | sudo tee /etc/unbound/blocklist/adult-domains.txt
pornhub.com
EOF

sudo chmod +x /etc/unbound/blocklist/gen-adult-block.sh
sudo /etc/unbound/blocklist/gen-adult-block.sh

# === 6. Konfigurasi Unbound ===
curl -s -H "Authorization: token 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"  -L "https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/unbound.conf"   -o /etc/unbound/unbound.conf

# === 7. Setup Remote Control Certificate ===
sudo unbound-control-setup

sudo rm /etc/resolv.conf
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved


# === 8. Aktifkan Unbound ===
sudo systemctl restart unbound
sudo systemctl enable unbound

# === 9. Cronjob untuk perbarui blocklist ===
(crontab -l 2>/dev/null; echo "0 3 * * * /etc/unbound/blocklist/update-lists.sh && /etc/unbound/blocklist/gen-block.conf.sh && /etc/unbound/blocklist/gen-adult-block.sh && systemctl restart unbound") | crontab -

# === 10. Monitoring Statistik Cache ===
echo "📊 Gunakan: sudo unbound-control stats_noreset | grep -E 'cache.*hits|cache.*misses'"
echo "📈 Untuk semua statistik: sudo unbound-control stats"
echo "📜 Untuk log permintaan: sudo journalctl -u unbound -f"

# === DONE ===
echo -e "\n📅 Unbound DoH + Filter Iklan/Malware + SafeSearch + Blokir Dewasa Aktif!"
echo "Coba: dig @127.0.0.1 google.com"
