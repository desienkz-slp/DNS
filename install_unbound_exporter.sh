#!/bin/bash

set -e

# === 1. Install GO versi terbaru ===
echo "[INFO] Downloading latest Go..."
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text)
wget -q https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go.tar.gz

echo "[INFO] Installing Go to /usr/local..."
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz

# Set PATH
echo "[INFO] Setting PATH for Go..."
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin' >> ~/.bashrc
source ~/.bashrc

# === 2. Install unbound_exporter ===
echo "[INFO] Installing unbound_exporter..."
/usr/local/go/bin/go install github.com/letsencrypt/unbound_exporter@latest

# === 3. Create systemd service ===
echo "[INFO] Creating systemd service..."
cat <<EOF > /etc/systemd/system/unbound_exporter.service
[Unit]
Description=Unbound Exporter (tanpa TLS)
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/unbound_exporter \\
  -unbound.host=tcp://127.0.0.1:8953 \\
  -unbound.key="" \\
  -unbound.cert="" \\
  -unbound.ca=""
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 4. Reload & Start ===
echo "[INFO] Enabling and starting service..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now unbound_exporter

echo "[DONE] unbound_exporter installed and running at http://localhost:9167/metrics"
