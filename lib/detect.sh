#!/usr/bin/env bash

detect_public_ip() {
  if command_exists curl; then
    curl -fsS4 --max-time 4 https://api.ipify.org 2>/dev/null && return 0
  fi
  hostname -I 2>/dev/null | awk '{print $1}'
}

detect_wan_if() {
  ip -o -4 route show to default 2>/dev/null | awk '{print $5; exit}'
}

existing_install_detected() {
  [[ -f /opt/mikrotik-vpn/config/mikrotik-vpn.conf ]] && return 0
  [[ -x /usr/local/bin/mikrotik-vpn ]] && return 0
  [[ -f /etc/openvpn/server/mikrotik-vpn.conf ]] && return 0
  systemctl list-unit-files openvpn-server@mikrotik-vpn.service >/dev/null 2>&1 && return 0
  ip link show tun-mvpn >/dev/null 2>&1 && return 0
  return 1
}
