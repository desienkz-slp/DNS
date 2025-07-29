List isi setting

  1. redirect adult 172.18.20.234
  2. hostname ip dns 172.18.20.x
  3. local-data: "media.sornongko.net. A 172.18.20.240"
  4. local-data: "isolir.sornongko.net. A 172.18.20.20"
  5. local-data: "acs.sornongko.net. A 172.18.20.233"
  6. local-data: "wa-gate.sornongko.net. A 172.18.20.241"
  7. port unbound 9168

===sebagai resolver===
wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.cache

unbound-anchor -a /var/lib/unbound/root.key
