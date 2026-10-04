#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ $UID != 0 ]]; then
	echo "[-] Script must run as root"
	exit 1
fi

hostname="$(hostname)"
auth_key=""
exit_node_tag="default-exit-node"

if [[ -z "$auth_key" ]]; then
    read -rp "[?] Tailscale Auth key not specified. Insert the key now: " auth_key
fi


apt update
apt install -y \
    curl \
	python3-venv \
	wget \
	ansible \
	ca-certificates \
	nftables \
    dnsutils \
    iproute2

curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

cat > /etc/apt/sources.list.d/docker.sources << EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt update
apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

systemctl enable --now docker

ansible-galaxy collection install -r ./ansible/requirements.yml
python3 -m venv ./.venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
pip install -r requirements.txt
