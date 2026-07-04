#!/usr/bin/env bash

install_server_packages() {
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y git openvpn easy-rsa iptables-persistent curl wget python3 rsync ca-certificates
}

setup_easyrsa_and_openvpn() {
  load_installed_config
  /usr/local/bin/mikrotik-vpn --install
}
