# 🧠 DNS Resolver Installer with Unbound + Exporter + Promtail

Script otomatis untuk menginstalasi **Unbound DNS Resolver**, **Unbound Exporter** (untuk Prometheus), dan **Promtail** (untuk Grafana Loki) dalam satu langkah praktis.

---

## 📦 Komponen yang Diinstal

| Komponen         | Deskripsi                                                                 |
|------------------|---------------------------------------------------------------------------|
| **Unbound**       | DNS Resolver Recursive lokal yang aman dan cepat.                        |
| **Unbound Exporter** | Monitoring DNS metrics via Prometheus.                                |
| **Promtail**       | Mengirim log Unbound ke Grafana Loki.                                   |

---
Butuh penyesuaian untuk
1. server loki
2. server redirect block adult

Jika kamu ingin pakai versi **dengan tombol Copy otomatis** saat dibuka di GitHub Pages atau dokumentasi berbasis HTML (misalnya pakai [Docsify](https://docsify.js.org) atau [MkDocs](https://www.mkdocs.org/)), kamu bisa pakai HTML di bawah:


<h3>untuk menjalankan instalasi otomatis</h3>

```html
wget https://raw.githubusercontent.com/desienkz-slp/DNS/main/unbound-exporter-promtail.sh
chmod +x unbound-exporter-promtail.sh
sudo ./unbound-exporter-promtail.sh
```
<h3>cek promtail</h3>

```html
sudo journalctl -u promtail -f
```

<h3>cek unbound_exporter</h3>

```html
curl http://localhost:9167/metrics
```
pastikan tampilan

```
# HELP unbound_up Was the last query of unbound successful.
# TYPE unbound_up gauge
unbound_up 1
...
```
❤️ Dukung Proyek Ini
Open-source butuh waktu dan energi. Jika kamu merasa skrip ini membantu, kamu bisa mendukung saya:

klik tombol di bawah ini:

<p align="center"> <a href="https://saweria.co/desienkz" target="_blank"> <img src="https://img.shields.io/badge/Donasi%20via-Saweria-orange?style=for-the-badge&logo=buymeacoffee" alt="Donasi via Saweria"> </a> </p>

