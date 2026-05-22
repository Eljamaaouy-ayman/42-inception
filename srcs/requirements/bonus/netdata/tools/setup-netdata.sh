#!/bin/bash

set -e

echo "[+] Installing Netdata"

curl -sSL https://get.netdata.cloud/kickstart.sh | \
  bash -s -- \
  --dont-wait \
  --disable-telemetry \
  --stable-channel

echo "[+] Netdata installed"

mkdir -p /etc/netdata

cat <<EOF > /etc/netdata/go.d/docker.conf
jobs:
  - name: docker
    url: unix:///var/run/docker.sock
EOF

echo "[+] Docker collector enabled"
