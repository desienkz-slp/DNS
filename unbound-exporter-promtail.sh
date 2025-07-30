#!/bin/bash

# ============================================
#  INSTALL UNBOUND RESOLVER + EXPORTER + PROMTAIL
# ============================================

echo -e "\033[1;34m[1/8] Downloading install scripts...\033[0m"
wget -q https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/install-resolver-unbound.sh -O install-resolver-unbound.sh
wget -q https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/promtail-install.sh -O promtail-install.sh
wget -q https://raw.githubusercontent.com/desienkz-slp/DNS/refs/heads/main/install_unbound_exporter.sh -O install_unbound_exporter.sh

echo -e "\033[1;34m[2/8] Setting executable permissions...\033[0m"
chmod +x install-resolver-unbound.sh promtail-install.sh install_unbound_exporter.sh

echo -e "\033[1;34m[3/8] Installing Unbound DNS Resolver...\033[0m"
bash install-resolver-unbound.sh
clear

echo -e "\033[1;34m[4/8] Installing Unbound Exporter...\033[0m"
bash install_unbound_exporter.sh
clear

echo -e "\033[1;34m[5/8] Installing Promtail...\033[0m"
bash promtail-install.sh
clear

echo -e "\033[1;34m[6/8] Cleaning up installation scripts...\033[0m"
rm -f install-resolver-unbound.sh promtail-install.sh install_unbound_exporter.sh

echo -e "\033[1;34m[7/8] All components installed successfully!\033[0m"
echo -e "\033[1;34m[8/8] Recommended: Reboot the system to apply everything properly.\033[0m"
