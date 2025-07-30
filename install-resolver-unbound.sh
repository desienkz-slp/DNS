#!/bin/bash

# ===============================================
#  SETUP UNBOUND DNS RESOLVER + DoH + FILTERING
# ===============================================

echo " === 1. Install Unbound & Tools ===  "
apt update && apt install unbound curl wget -y
wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache
unbound-anchor -a /var/lib/unbound/root.key

echo " === 2. Siapkan Blocklist ===  "
mkdir -p /etc/unbound/blocklist
cd /etc/unbound/blocklist

curl -L https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/update-lists.sh -o /etc/unbound/blocklist/update-list.sh

chmod +x /etc/unbound/blocklist/update-list.sh
bash /etc/unbound/blocklist/update-list.sh

cat <<'EOF' > /etc/unbound/blocklist/gen-block.conf.sh
#!/bin/bash
ADS_SRC="/etc/unbound/blocklist/block-ads.txt"
MAL_SRC="/etc/unbound/blocklist/block-malware.txt"
ADS_SRC2="/etc/unbound/blocklist/block-mine.txt"
OUT="/etc/unbound/blocklist/ad-malware-block.conf"
TMP="/tmp/adblock-clean.tmp"

if [[ ! -f "$ADS_SRC" || ! -f "$MAL_SRC" ]]; then
    echo "❌ ERROR: File sumber $ADS_SRC atau $MAL_SRC tidak ditemukan!"
    exit 1
fi

> "$TMP"

echo "🔁 Memproses daftar iklan (ABP format)..."
grep '^||' "$ADS_SRC" \
  | sed -E 's/^\|\|([^\/\^$\*]+).*/\1/' \
  | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -Ev '[^a-zA-Z0-9.-]' \
  | sort -u \
  | awk '{print "local-zone: \"" $1 "\" static"}' >> "$TMP"

echo "🔁 Memproses daftar iklan (MINE format)..."
grep '^||' "$ADS_SRC2" \
  | sed -E 's/^\|\|([^\/\^$\*]+).*/\1/' \
  | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -Ev '[^a-zA-Z0-9.-]' \
  | sort -u \
  | awk '{print "local-zone: \"" $1 "\" static"}' >> "$TMP"

echo "🔁 Memproses daftar malware (hosts format)..."
grep -E '^(0\.0\.0\.0|127\.0\.0\.1)' "$MAL_SRC" \
  | awk '{print $2}' \
  | grep -Ev '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' \
  | grep -Ev '[^a-zA-Z0-9.-]' \
  | sort -u \
  | awk '{print "local-zone: \"" $1 "\" static"}' >> "$TMP"

sort -u "$TMP" > "$OUT"
rm -f "$TMP"

echo "🔍 Mengecek konfigurasi Unbound..."
if unbound-checkconf; then
    echo "✅ Konfigurasi OK! Me-restart Unbound..."
    systemctl restart unbound
    echo "✅ Blocklist berhasil diperbarui & Unbound di-restart."
else
    echo "❌ ERROR: Cek manual isi blocklist yang error!"
    head -n 10 "$OUT"
fi
EOF

chmod +x /etc/unbound/blocklist/gen-block.conf.sh
bash /etc/unbound/blocklist/gen-block.conf.sh

cat <<'EOF' > /etc/unbound/blocklist/gen-adult-block.sh
#!/bin/bash
OUT="/etc/unbound/blocklist/adult-redirect.conf"
REDIRECT_IP="172.18.20.234"
> "$OUT"

while read domain; do
  echo "local-data: \"$domain A $REDIRECT_IP\"" >> "$OUT"
  echo "local-data: \"www.$domain A $REDIRECT_IP\"" >> "$OUT"
done < /etc/unbound/blocklist/adult-domains.txt
EOF

chmod +x /etc/unbound/blocklist/gen-adult-block.sh
bash /etc/unbound/blocklist/gen-adult-block.sh

echo  " === 3. Konfigurasi Unbound resolver  === "
curl -L https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/resolver-unbound.conf -o /etc/unbound/unbound.conf

echo " === 4. Remote Control Certificate === "
unbound-control-setup

rm /etc/resolv.conf
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf

systemctl stop systemd-resolved
systemctl disable systemd-resolved

echo "aktifkan log"
mkdir -p /var/log/unbound
touch /var/log/unbound/unbound.log
chown unbound:unbound /var/log/unbound/unbound.log

#========
set -e

echo "🛡️  Menambahkan izin AppArmor untuk Unbound..."

# 2. Tambahkan rule ke override profile
APPARMOR_LOCAL="/etc/apparmor.d/local/usr.sbin.unbound"

mkdir -p "$(dirname "$APPARMOR_LOCAL")"

if ! grep -q "/var/log/unbound/" "$APPARMOR_LOCAL"; then
  cat <<'EOF' >> "$APPARMOR_LOCAL"
/var/log/unbound/ rw,
/var/log/unbound/** rwk,
EOF

  echo "✅ Rule AppArmor ditambahkan ke $APPARMOR_LOCAL"
else
  echo "ℹ️  Rule sudah ada di $APPARMOR_LOCAL"
fi

# 3. Reload profil AppArmor
echo "🔁 Reload AppArmor profile..."
apparmor_parser -r /etc/apparmor.d/usr.sbin.unbound

# 4. Restart unbound (opsional)
echo "🔄 Restart Unbound service..."
systemctl restart unbound

echo "✅ Selesai! Periksa log di /var/log/unbound/unbound.log"

#========


#=======
set -e

LOGROTATE_FILE="/etc/logrotate.d/unbound"

echo "📝 Membuat konfigurasi logrotate untuk Unbound..."

# Cek apakah file sudah ada
if [ -f "$LOGROTATE_FILE" ]; then
  echo "⚠️  File logrotate sudah ada di $LOGROTATE_FILE, tidak diubah."
  exit 1
fi

# Buat file konfigurasi logrotate
cat <<'EOF' > "$LOGROTATE_FILE"
/var/log/unbound/unbound.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 640 unbound unbound
    postrotate
        systemctl restart unbound > /dev/null 2>&1 || true
    endscript
}
EOF

echo "✅ Logrotate Unbound berhasil dibuat di $LOGROTATE_FILE"

# Tampilkan isi konfigurasi
echo "📂 Konfigurasi logrotate:"
cat "$LOGROTATE_FILE"

# Uji coba rotasi manual
echo "🔄 Uji coba rotasi log secara manual..."
logrotate -f "$LOGROTATE_FILE"

echo "✅ Selesai! Cek file di /var/log/unbound/"

#=======

echo "=== 5. Aktifkan Unbound ==="
systemctl restart unbound
systemctl enable unbound

echo "=== 6. Cronjob untuk auto-update blocklist ==="
(crontab -l 2>/dev/null; echo "0 3 * * * /etc/unbound/blocklist/update-list.sh && /etc/unbound/blocklist/gen-block.conf.sh && /etc/unbound/blocklist/gen-adult-block.sh && systemctl restart unbound") | crontab -
(crontab -l 2>/dev/null; echo "0 2 */3 * * /usr/local/bin/update-unbound-roothints.sh >> /var/log/unbound/update-roothints.log 2>&1") | crontab -

echo "=== 7. Statistik Cache ==="
echo "📊 Gunakan: unbound-control stats_noreset | grep -E 'cache.*hits|cache.*misses'"
echo "📈 Semua statistik: unbound-control stats"
echo "📜 Log: journalctl -u unbound -f"

echo -e "\n✅ Unbound DoH + Filter Iklan/Malware + SafeSearch + Blokir Dewasa Aktif!"
echo "🧪 Tes: dig @127.0.0.1 google.com"
