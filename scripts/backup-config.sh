#!/usr/bin/env bash

set -euo pipefail

backup_dir="/var/backups/linux-network-lab"
timestamp="$(date +%Y%m%d-%H%M%s)"
archive="$backup_dir/server-config-$timestamp.tar.gz"

if [[ "$EUID" -ne 0 ]]; then
   echo "Uruchom skrypt przez sudo."
   exit 1
fi

umask 077
mkdir -p "$backup_dir"

tar -czf "$archive" -C /etc \
   netplan \
   dnsmasq.conf \
   dnsmasq.d \
   nftables.conf \
   sysctl.d/90-lab-router.conf

echo "Zapisano kopie: $archive"
