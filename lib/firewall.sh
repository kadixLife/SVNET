#!/usr/bin/env bash

setup_mikrotik_vpn_firewall() {
  load_installed_config
  sysctl -w net.ipv4.ip_forward=1 >/dev/null
  printf 'net.ipv4.ip_forward=1\n' > /etc/sysctl.d/99-mikrotik-vpn.conf

  iptables -C INPUT -i "$OVPN_IF" -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -i "$OVPN_IF" -j ACCEPT
  iptables -C INPUT -p "$OVPN_PROTO" --dport "$OVPN_PORT" -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -p "$OVPN_PROTO" --dport "$OVPN_PORT" -j ACCEPT
  iptables -C FORWARD -i "$OVPN_IF" -o "$WAN_IF" -j ACCEPT 2>/dev/null || iptables -I FORWARD 1 -i "$OVPN_IF" -o "$WAN_IF" -j ACCEPT
  iptables -C FORWARD -i "$WAN_IF" -o "$OVPN_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || iptables -I FORWARD 2 -i "$WAN_IF" -o "$OVPN_IF" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
  iptables -t nat -C POSTROUTING -s "$VPN_NET" -o "$WAN_IF" -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s "$VPN_NET" -o "$WAN_IF" -j MASQUERADE

  netfilter-persistent save >/dev/null 2>&1 || true
  ok "Firewall/NAT проверены и дополнены без очистки чужих правил."
}
