#!/bin/bash

echo "== 🔥 MENGHAPUS UNBOUND DAN SEMUA KOMPONENNYA =="

# === 1. Stop layanan ===
systemctl stop unbound 2>/dev/null
systemctl stop cloudflared 2>/dev/null



# === 2. Disable service cloudflared ===
systemctl disable cloudflared 2>/dev/null

# === 3. Hapus paket unbound ===
apt purge --autoremove unbound -y

# === 4. Hapus konfigurasi dan direktori terkait ===
rm -rf /etc/unbound/
rm -f /usr/local/bin/cloudflared
rm -rf /etc/cloudflared/
rm -rf /etc/unbound/blocklist/
rm -rf /usr/bin/cloudflared
rm -f /etc/systemd/system/cloudflared.service
dpkg -r cloudflared

# === 5. Bersihkan aturan firewall (jika pernah ditambahkan) ===
iptables -D INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null
iptables -D INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
iptables -D INPUT -p tcp --dport 5353 -j ACCEPT 2>/dev/null
iptables -D INPUT -p udp --dport 5353 -j ACCEPT 2>/dev/null
fuser -k 5053/udp
fuser -k 5353/udp
# === 6. Reload systemd dan firewall ===
systemctl daemon-reload

echo "✅ UNBOUND, CLOUDFLARED, DAN SEMUA SETTINGAN TELAH DIHAPUS"
