#!/bin/bash

# === Konfigurasi ===
CONF="/etc/unbound/unbound.conf"
INCLUDE_LINE='include: "/etc/unbound/blocklist/adult-redirect.conf"'
BLOCK_SCRIPT="/usr/local/bin/block_adult.sh"
UNBLOCK_SCRIPT="/usr/local/bin/unblock_adult.sh"

# === Buat script blokir ===
cat <<EOF > "$BLOCK_SCRIPT"
#!/bin/bash
if ! grep -qF "$INCLUDE_LINE" "$CONF"; then
    echo "$INCLUDE_LINE" >> "$CONF"
    systemctl restart unbound
fi
EOF

# === Buat script unblock ===
cat <<EOF > "$UNBLOCK_SCRIPT"
#!/bin/bash
if grep -qF "$INCLUDE_LINE" "$CONF"; then
    sed -i "\\|$INCLUDE_LINE|d" "$CONF"
    systemctl restart unbound
fi
EOF

# === Jadikan executable ===
chmod +x "$BLOCK_SCRIPT" "$UNBLOCK_SCRIPT"

# === Tambahkan crontab ===
(crontab -l 2>/dev/null; echo "0 6 * * * $BLOCK_SCRIPT") | sort -u | crontab -
(crontab -l 2>/dev/null; echo "0 21 * * * $UNBLOCK_SCRIPT") | sort -u | crontab -

echo "✅ Setup selesai. Filter dewasa aktif pukul 06:00 dan nonaktif pukul 21:00."
