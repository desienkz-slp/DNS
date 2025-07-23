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

cat <<EOF | sudo tee /lib/systemd/system/unbound.service
[Unit]
Description=Unbound DNS server
Documentation=man:unbound(8)
After=network.target
Before=nss-lookup.target
Wants=nss-lookup.target

[Service]
Type=notify
Restart=on-failure
EnvironmentFile=-/etc/default/unbound
ExecStartPre=-/usr/libexec/unbound-helper chroot_setup
ExecStartPre=-/usr/libexec/unbound-helper root_trust_anchor_update
ExecStart=/usr/sbin/unbound -d -p
ExecStopPost=-/usr/libexec/unbound-helper chroot_teardown
ExecReload=+/bin/kill -HUP $MAINPID

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

# Download blocklist
sudo wget https://raw.githubusercontent.com/ABPindo/indonesianadblockrules/master/subscriptions/abpindo.txt -O /etc/unbound/blocklist/block-ads.txt
sudo wget  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -O /etc/unbound/blocklist/block-malware.txt

# Script auto-update blocklist
cat <<EOF | sudo tee /etc/unbound/blocklist/update-lists.sh
#!/bin/bash
curl -s https://raw.githubusercontent.com/ABPindo/indonesianadblockrules/master/subscriptions/abpindo.txt -o /etc/unbound/blocklist/block-ads.txt
curl -s  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -o /etc/unbound/blocklist/block-malware.txt
EOF
sudo chmod +x /etc/unbound/blocklist/update-lists.sh
sudo /etc/unbound/blocklist/update-lists.sh

# Script blok iklan & malware
wget -O /etc/unbound/blocklist/gen-block.conf.sh https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/gen-block.conf.sh?token=GHSAT0AAAAAADGC3RHNYK5WJG4FD54HSIRA2EAQUCQ
sudo chmod +x /etc/unbound/blocklist/gen-block.conf.sh
sudo /etc/unbound/blocklist/gen-block.conf.sh

# Script blok konten dewasa
cat <<EOF | sudo tee /etc/unbound/blocklist/adult-domains.txt
pornhub.com
EOF

wget -O /etc/unbound/blocklist/gen-adult-block.sh https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/gen-adult-block.sh?token=GHSAT0AAAAAADGC3RHNOVSKFG7ZBCQKX4WY2EAQYFQ
sudo chmod +x /etc/unbound/blocklist/gen-adult-block.sh
sudo /etc/unbound/blocklist/gen-adult-block.sh

# === 6. Konfigurasi Unbound ===
wget -O /etc/unbound/unbound.conf https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/unbound.conf?token=GHSAT0AAAAAADGC3RHND6M6XAZGZS2WH3VI2EAQ2HQ
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
