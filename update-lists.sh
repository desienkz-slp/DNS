#!/bin/bash
curl -s https://raw.githubusercontent.com/ABPindo/indonesianadblockrules/master/subscriptions/abpindo.txt -o /etc/unbound/blocklist/block-ads.txt
curl -s  https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts -o /etc/unbound/blocklist/block-malware.txt
