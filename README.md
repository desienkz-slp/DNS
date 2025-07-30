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

```html
<h3>🛠️ Instalasi Cepat</h3>
<p>Jalankan perintah di bawah ini di terminal:</p>

<pre>
<code class="language-bash">
wget https://raw.githubusercontent.com/desienkz-slp/DNS/main/unbound-exporter-promtail.sh
chmod +x unbound-exporter-promtail.sh
sudo ./unbound-exporter-promtail.sh
</code>
</pre>
