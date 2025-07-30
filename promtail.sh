#!/bin/bash

# === Variabel ===
PROMTAIL_VERSION="3.5.2"
CONFIG_PATH="/etc/promtail"
CONFIG_FILE="$CONFIG_PATH/config.yaml"
POSITION_FILE="/var/log/positions-unbound.yaml"
UNBOUND_LOG="/var/log/unbound/unbound.log"

# === 1. Unduh dan install Promtail ===
cd /tmp
wget -q https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
unzip -o promtail-linux-amd64.zip
chmod +x promtail-linux-amd64
mv -f promtail-linux-amd64 /usr/local/bin/promtail

# === 2. Buat direktori konfigurasi jika belum ada ===
mkdir -p "$CONFIG_PATH"

# === 3. Buat konfigurasi YAML untuk Unbound ===
cat > "$CONFIG_FILE" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: $POSITION_FILE

clients:
  - url: http://172.18.20.243:3100/loki/api/v1/push

scrape_configs:
  - job_name: unbound
    static_configs:
      - targets:
          - localhost
        labels:
          job: unbound
          __path__: $UNBOUND_LOG
EOF

# === 4. Buat systemd service untuk promtail ===
cat > /etc/systemd/system/promtail.service <<EOF
[Unit]
Description=Promtail service for Unbound
After=network.target

[Service]
ExecStart=/usr/local/bin/promtail -config.file=$CONFIG_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 5. Reload systemd dan aktifkan promtail ===
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now promtail

echo "✅ Promtail $PROMTAIL_VERSION terinstall dan berjalan. Cek: systemctl status promtail"
