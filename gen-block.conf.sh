#!/bin/bash

# Sumber data
ADS_SRC="/etc/unbound/blocklist/block-ads.txt"
MAL_SRC="/etc/unbound/blocklist/block-malware.txt"

# Output konfigurasi Unbound
OUT="/etc/unbound/blocklist/ad-malware-block.conf"
TMP="/tmp/adblock-clean.tmp"

# Pastikan file input ada
if [[ ! -f "$ADS_SRC" || ! -f "$MAL_SRC" ]]; then
    echo "❌ ERROR: File sumber $ADS_SRC atau $MAL_SRC tidak ditemukan!"
    exit 1
fi

# Kosongkan file sementara
> "$TMP"

echo "🔁 Memproses daftar iklan (ABP format)..."
grep '^||' "$ADS_SRC" \
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

# Hapus duplikat akhir
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
