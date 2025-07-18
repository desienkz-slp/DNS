# Step-by-step Install unbound_exporter untuk Prometheus + Grafana (build from source)

# 1. Install dependensi
sudo apt update
sudo apt install -y git golang make

# 2. Clone source code
cd /opt
git clone https://github.com/letsencrypt/unbound_exporter.git
cd unbound_exporter

# 3. Build binary secara manual
# (karena tidak ada Makefile, kita build langsung dengan `go build`)
go build -o unbound_exporter

# 4. Pindahkan ke lokasi binary system
sudo mv unbound_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/unbound_exporter

# 5. Buat systemd service
sudo tee /etc/systemd/system/unbound_exporter.service > /dev/null <<EOF
[Unit]
Description=Unbound Exporter for Prometheus
After=network.target

[Service]
ExecStart=/usr/local/bin/unbound_exporter \
  -unbound.host=tcp://127.0.0.1:8953 \
  -unbound.cert=/etc/unbound/unbound_control.pem \
  -unbound.key=/etc/unbound/unbound_control.key \
  -unbound.ca=/etc/unbound/unbound_server.pem
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 6. Reload systemd dan mulai service
sudo systemctl daemon-reload
sudo systemctl enable --now unbound_exporter

# 7. Cek apakah exporter aktif
# cara cek sudah aktif atau belum "curl http://localhost:9167/metrics"


