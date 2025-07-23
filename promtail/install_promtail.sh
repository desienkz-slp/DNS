#!/bin/bash

set -e

PROMTAIL_VERSION="3.5.2"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/"
SERVICE_FILE="/etc/systemd/system/promtail.service"

# Unduh dan ekstrak Promtail
echo "📥 Mengunduh Promtail versi $PROMTAIL_VERSION..."
curl -sL -o /tmp/promtail.tar.gz "https://github.com/grafana/loki/releases/download/v$PROMTAIL_VERSION/promtail-linux-amd64.zip"

# Instal unzip jika belum ada
if ! command -v unzip &>/dev/null; then
  echo "📦 Menginstal unzip..."
  apt update && apt install -y unzip
fi

unzip -o /tmp/promtail.tar.gz -d /tmp/
chmod +x /tmp/promtail-linux-amd64
mv /tmp/promtail-linux-amd64 "$INSTALL_DIR/promtail"

# Buat direktori konfigurasi
mkdir -p "$CONFIG_DIR"

# Buat file konfigurasi dasar
cat > "$CONFIG_DIR/promtail-config.yml" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/log/positions.yaml

clients:
  - url: http://localhost:3100/loki/api/v1/push

scrape_configs:
  - job_name: systemd-journal
    journal:
      path: /var/log/journal
    labels:
      job: systemd-journal
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        regex: 'unbound.service'
        action: keep
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'
EOF

# Buat service systemd
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Promtail - sends logs to Loki
After=network.target

[Service]
ExecStart=$INSTALL_DIR/promtail -config.file=$CONFIG_DIR/promtail-config.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd dan mulai service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable promtail
systemctl restart promtail

echo "✅ Promtail $PROMTAIL_VERSION terinstal dan berjalan."
