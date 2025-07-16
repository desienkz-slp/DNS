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

# Download blocklist
sudo wget https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -O /etc/unbound/blocklist/block-ads.txt
sudo wget https://raw.githubusercontent.com/laksa19/indoads-mikrotik/refs/heads/master/adlists.rsc -O /etc/unbound/blocklist/block-malware.txt

# Script auto-update blocklist
cat <<EOF | sudo tee /etc/unbound/blocklist/update-lists.sh
#!/bin/bash
curl -s https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -o /etc/unbound/blocklist/block-ads.txt
curl -s https://raw.githubusercontent.com/laksa19/indoads-mikrotik/refs/heads/master/adlists.rsc -o /etc/unbound/blocklist/block-malware.txt
EOF
sudo chmod +x /etc/unbound/blocklist/update-lists.sh
sudo /etc/unbound/blocklist/update-lists.sh

# Script blok iklan & malware
cat <<EOF | sudo tee /etc/unbound/blocklist/gen-block.conf.sh
#!/bin/bash
OUT="/etc/unbound/blocklist/ad-malware-block.conf"
> "\$OUT"

grep "^0.0.0.0" /etc/unbound/blocklist/block-ads.txt | awk '{print "local-zone: \""\$2"\" static"}' >> "\$OUT"
cat /etc/unbound/blocklist/block-malware.txt | grep -v "^#" | awk '{print "local-zone: \""\$1"\" static"}' >> "\$OUT"
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
xvideos.com
xnxx.com
EOF

sudo chmod +x /etc/unbound/blocklist/gen-adult-block.sh
sudo /etc/unbound/blocklist/gen-adult-block.sh

# === 6. Konfigurasi Unbound ===
cat <<EOF | sudo tee /etc/unbound/unbound.conf
server:
  chroot: ""
  interface: 0.0.0.0
  port: 53
  do-ip4: yes
  do-ip6: no
  do-udp: yes
  do-tcp: yes
  access-control: 0.0.0.0/0 allow
  access-control: 192.168.168.0/24 allow
  hide-identity: yes
  hide-version: yes
  prefetch: yes
  cache-max-ttl: 86400
  cache-min-ttl: 3600
  qname-minimisation: yes
  log-queries: yes
  log-replies: yes
  statistics-interval: 0
  extended-statistics: yes
  use-syslog: yes
  msg-cache-size: 1024m
  rrset-cache-size: 2048m
  key-cache-size: 512m
  neg-cache-size: 512m
  msg-cache-slabs: 8
  rrset-cache-slabs: 8
  key-cache-slabs: 8
  infra-cache-slabs: 8
  do-not-query-localhost: no
  verbosity: 2

  include: "/etc/unbound/blocklist/ad-malware-block.conf"
  include: "/etc/unbound/blocklist/adult-redirect.conf"

  # SafeSearch
  local-zone: "www.google.com." redirect
  local-data: "www.google.com. A 216.239.38.120"

  local-zone: "www.bing.com." redirect
  local-data: "www.bing.com. A 204.79.197.220"

  # Reverse PTR agar hostname DNS muncul di NSLookup
  local-zone: "20.18.172.in-addr.arpa." static
  local-data: "11.20.18.172.in-addr.arpa. PTR dns.srnk."
  local-data: "dns.srnk. A 172.18.20.11"

  # Static A Records
  local-data: "media.sornongko.net. A 172.18.20.240"
  local-data: "isolir.sornongko.net. A 172.18.20.20"
  local-data: "acs.sornongko.net. A 172.18.20.233"
  local-data: "wa-gate.sornongko.net. A 172.18.20.241"

remote-control:
  control-enable: yes
  control-use-cert: yes
  control-interface: 127.0.0.1

forward-zone:
  name: "."
  forward-addr: 127.0.0.1@5053
  forward-addr: 127.0.0.1@5353
EOF

# === 7. Setup Remote Control Certificate ===
sudo unbound-control-setup

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
