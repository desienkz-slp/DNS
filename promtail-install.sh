#!/bin/bash

set -e

# Variabel versi dan arsitektur
VERSION="3.5.3"
ARCH="amd64"

echo "=== Mengunduh Promtail v$VERSION untuk $ARCH ==="
wget https://github.com/grafana/loki/releases/download/v${VERSION}/promtail-linux-${ARCH}.zip -O promtail.zip

echo "=== Mengekstrak file ==="
unzip -o promtail.zip
rm promtail.zip

echo "=== Memindahkan binary ke /usr/local/bin dan beri izin eksekusi ==="
sudo mv promtail-linux-${ARCH} /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail

echo "=== Membuat direktori konfigurasi dan posisi ==="
sudo mkdir -p /etc/promtail
sudo mkdir -p /var/log/promtail

echo "=== Membuat file konfigurasi dasar /etc/promtail/promtail.yaml ==="
sudo tee /etc/promtail/promtail.yaml > /dev/null <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/promtail/positions.yaml

clients:
  - url: http://172.18.20.243:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/unbound/*.log
EOF

echo "=== Membuat systemd service file untuk promtail ==="
sudo tee /etc/systemd/system/promtail.service > /dev/null <<EOF
[Unit]
Description=Promtail Service
After=network.target

[Service]
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "=== Reload systemd daemon dan mulai service Promtail ==="
sudo systemctl daemon-reload
sudo systemctl enable --now promtail

echo "=== Instalasi Promtail v$VERSION selesai ==="
sudo systemctl status promtail --no-pager
