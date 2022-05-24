#!/bin/bash

nordvpn connect $@ || {
    echo "Unable to connect to NordVPN."
    exit 1
}

MYIP=$(ifconfig nordlynx | grep inet | awk '{print $2}')
PRIVATE=$(sudo wg show nordlynx private-key)
PUBKEY=$(sudo wg show nordlynx | grep peer | awk '{print $2}')
ENDPOINT=$(nordvpn status | grep 'Current server' | awk '{print $3}')

nordvpn disconnect &

cat <<EOF > wg0.conf
[Interface]
Address = ${MYIP}
PrivateKey = ${PRIVATE}
ListenPort = 51820
DNS = 103.86.96.100, 103.86.99.100

[Peer]
PublicKey = ${PUBKEY}
AllowedIPs = 0.0.0.0/0, ::0/0
Endpoint = ${ENDPOINT}:51820
EOF
