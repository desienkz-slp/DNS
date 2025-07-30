#!/bin/bash

set -euo pipefail

GO_VERSION="1.24.5"
GO_TAR="go${GO_VERSION}.linux-amd64.tar.gz"
GO_URL="https://go.dev/dl/${GO_TAR}"
INSTALL_DIR="/usr/local"
PROFILE_FILE="/etc/profile.d/go.sh"
GOBIN="/root/go/bin"

log() {
  echo -e "[INFO] $1"
}

# === 0. Harus dijalankan sebagai root ===
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Skrip ini harus dijalankan sebagai root. Gunakan: sudo $0"
  exit 1
fi

# === 1. Install Go ===
log "Menghapus instalasi Go sebelumnya..."
rm -rf ${INSTALL_DIR}/go /root/go /home/*/go

log "Mengunduh Go ${GO_VERSION} dari ${GO_URL}..."
wget -q --show-progress ${GO_URL}

log "Mengekstrak Go ke ${INSTALL_DIR}..."
tar -C ${INSTALL_DIR} -xzf ${GO_TAR}
rm -f ${GO_TAR}

log "Menambahkan PATH Go ke ${PROFILE_FILE}..."
cat <<EOF > ${PROFILE_FILE}
export PATH=\$PATH:/usr/local/go/bin
EOF
chmod 644 ${PROFILE_FILE}
source ${PROFILE_FILE}

# === 2. Verifikasi Go ===
log "Verifikasi instalasi Go..."
go version || { echo "[ERROR] Go tidak berhasil diinstal."; exit 1; }

# === 3. Install unbound_exporter ===
log "Menginstall unbound_exporter..."
go install github.com/letsencrypt/unbound_exporter@latest

# === 4. Buat systemd service ===
log "Membuat systemd service untuk unbound_exporter..."
cat <<EOF > /etc/systemd/system/unbound_exporter.service
[Unit]
Description=Unbound Exporter (tanpa TLS)
After=network.target

[Service]
User=root
ExecStart=${GOBIN}/unbound_exporter \\
  -unbound.host=tcp://127.0.0.1:8953 \\
  -unbound.key="" \\
  -unbound.cert="" \\
  -unbound.ca=""
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# === 5. Jalankan service ===
log "Menjalankan dan mengaktifkan unbound_exporter..."
systemctl daemon-reload
systemctl enable --now unbound_exporter

log "[✅ SELESAI] unbound_exporter aktif di http://localhost:9167/metrics"
