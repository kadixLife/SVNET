#!/usr/bin/env bash

supported_os() {
  [[ -f /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" ]] || return 1
  [[ "${VERSION_ID:-}" == "22.04" || "${VERSION_ID:-}" == "24.04" ]]
}

check_internet() {
  if command_exists curl; then
    curl -fsS --max-time 5 https://api.ipify.org >/dev/null
  elif command_exists wget; then
    wget -qO- --timeout=5 https://api.ipify.org >/dev/null
  else
    ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1
  fi
}

detect_public_ip() {
  if command_exists curl; then
    curl -fsS4 --max-time 8 https://api.ipify.org 2>/dev/null && return 0
  fi
  if command_exists wget; then
    wget -qO- --timeout=8 https://api.ipify.org 2>/dev/null && return 0
  fi
  hostname -I | awk '{print $1}'
}

detect_wan_if() {
  ip -o -4 route show to default 2>/dev/null | awk '{print $5; exit}'
}

port_is_free() {
  local proto="$1" port="$2"
  if [[ "$proto" == "udp" ]]; then
    ! ss -lun 2>/dev/null | grep -Eq ":${port}\b"
  else
    ! ss -ltn 2>/dev/null | grep -Eq ":${port}\b"
  fi
}

existing_install_detected() {
  [[ -d /opt/svobodanet ]] && return 0
  [[ -x /usr/local/bin/svnet ]] && return 0
  [[ -f /etc/openvpn/server/svnet.conf ]] && return 0
  systemctl list-unit-files openvpn-server@svnet.service >/dev/null 2>&1 && return 0
  ip link show tun-svnet >/dev/null 2>&1 && return 0
  return 1
}

print_detected_values() {
  echo "SERVER_IP=$SERVER_IP"
  echo "WAN_IF=$WAN_IF"
  echo "OVPN_PROTO=$OVPN_PROTO"
  echo "OVPN_PORT=$OVPN_PORT"
  echo "VPN_NET=$VPN_NET"
  echo "VPN_SERVER_IP=$VPN_SERVER_IP"
  echo "MIKROTIK_VPN_IP=$MIKROTIK_VPN_IP"
  echo "HTTP_PORT=$HTTP_PORT"
  echo "MIKROTIK_LAN=$MIKROTIK_LAN"
  echo "MIKROTIK_LAN_DNS=$MIKROTIK_LAN_DNS"
  echo "MIKROTIK_WAN=$MIKROTIK_WAN"
  echo "MIKROTIK_OVPN_IF=$MIKROTIK_OVPN_IF"
}
