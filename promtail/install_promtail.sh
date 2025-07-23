\#!/bin/bash
set -e

# ========================================

# Promtail Installation & Configuration

# ========================================

# 1. Unduh dan Instal Promtail

VERSION="2.9.4"
echo "📥 Mengunduh Promtail versi \$VERSION..."
wget -q [https://github.com/grafana/loki/releases/download/v\$VERSION/promtail-linux-amd64.zip](https://github.com/grafana/loki/releases/download/v$VERSION/promtail-linux-amd64.zip)
unzip -o promtail-linux-amd64.zip
chmod +x promtail-linux-amd64
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

# 2. Buat Konfigurasi Promtail

CONFIG\_DIR="/etc/promtail"
echo "🛠️  Membuat konfigurasi di \$CONFIG\_DIR..."
sudo mkdir -p "\$CONFIG\_DIR"
cat <\<EOF | sudo tee \$CONFIG\_DIR/config.yml > /dev/null
server:
http\_listen\_port: 9080
grpc\_listen\_port: 0

positions:
filename: /var/log/positions.yaml

clients:

* url: [http://172.18.20.243:3100/loki/api/v1/push](http://172.18.20.243:3100/loki/api/v1/push)

scrape\_configs:

* job\_name: systemd-journal
  journal:
  path: /var/log/journal  # biarkan kosong jika default
  labels:
  job: systemd-journal-2
  relabel\_configs:

  * source\_labels: \['\_\_journal\_\_systemd\_unit']
    target\_label: 'unit'
    EOF

# 3. Buat User dan Berikan Izin Akses ke Journal

echo "👤 Menambahkan user promtail dan memberi akses ke journal..."
sudo useradd --no-create-home --shell /usr/sbin/nologin promtail || true
sudo usermod -a -G systemd-journal promtail
sudo chown -R promtail\:promtail "\$CONFIG\_DIR"
sudo touch /var/log/positions.yaml
sudo chown promtail\:promtail /var/log/positions.yaml

# 4. Buat Service Systemd untuk Promtail

SERVICE\_FILE="/etc/systemd/system/promtail.service"
echo "🔧 Membuat service file di \$SERVICE\_FILE..."
cat <\<EOF | sudo tee \$SERVICE\_FILE > /dev/null
\[Unit]
Description=Promtail service
After=network.target

\[Service]
User=promtail
Group=promtail
Type=simple
ExecStart=/usr/local/bin/promtail -config.file=\$CONFIG\_DIR/config.yml
Restart=on-failure

\[Install]
WantedBy=multi-user.target
EOF

# 5. Aktifkan dan Jalankan Promtail

echo "🚀 Menjalankan Promtail..."
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail

# 6. Tampilkan Status

echo "📡 Status Promtail:"
sudo systemctl status promtail --no-pager

# 7. (Opsional) Tambahkan Filter untuk Unbound

cat <<'NOTE'

📌 OPSIONAL: Jika ingin hanya membaca log dari unbound.service,
edit /etc/promtail/config.yml dan tambahkan:

relabel\_configs:

* source\_labels: \['\_\_journal\_\_systemd\_unit']
  regex: 'unbound.service'
  action: keep

Kemudian jalankan ulang:
sudo systemctl restart promtail
NOTE
