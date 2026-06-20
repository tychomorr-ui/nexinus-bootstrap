#!/usr/bin/env bash
rm -f /etc/resolv.conf
echo 'nameserver 1.1.1.1' > /etc/resolv.conf
printf 'deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse\ndeb http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse\ndeb http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse\n' > /etc/apt/sources.list
apt-get update -y
apt-get install -y curl openssl python3 ca-certificates
curl -fsSL https://raw.githubusercontent.com/tychomorr-ui/nexinus-bootstrap/main/setup.sh | bash
