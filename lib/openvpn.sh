#!/usr/bin/env bash

install_server_packages() {
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y openvpn easy-rsa iptables-persistent curl wget python3 rsync ca-certificates
}

setup_easyrsa_and_openvpn() {
  load_installed_config
  local easy="/etc/openvpn/easy-rsa"
  mkdir -p /etc/openvpn/server/ccd /var/log/openvpn

  if [[ ! -x "$easy/easyrsa" ]]; then
    mkdir -p "$easy"
    cp -a /usr/share/easy-rsa/* "$easy/"
  fi

  if [[ ! -d "$easy/pki" ]]; then
    (cd "$easy" && EASYRSA_BATCH=1 ./easyrsa init-pki)
    (cd "$easy" && EASYRSA_BATCH=1 EASYRSA_REQ_CN="SvobodaNET-CA" ./easyrsa build-ca nopass)
    (cd "$easy" && EASYRSA_BATCH=1 ./easyrsa gen-dh)
    (cd "$easy" && EASYRSA_BATCH=1 ./easyrsa build-server-full server nopass)
    (cd "$easy" && EASYRSA_BATCH=1 ./easyrsa build-client-full "$CLIENT_NAME" nopass)
    (cd "$easy" && EASYRSA_BATCH=1 ./easyrsa gen-crl)
  else
    warn "EasyRSA PKI уже существует, ключи и сертификаты не пересоздаются."
  fi

  local vpn_network vpn_netmask
  vpn_network="$(cidr_network "$VPN_NET")"
  vpn_netmask="$(cidr_netmask "$VPN_NET")"

  render_template "$SVNET_REPO_ROOT/templates/openvpn/svnet.conf.tpl" /etc/openvpn/server/svnet.conf \
    OVPN_PORT "$OVPN_PORT" OVPN_PROTO "$OVPN_PROTO" OVPN_IF "$OVPN_IF" VPN_NETWORK "$vpn_network" VPN_NETMASK "$vpn_netmask"

  printf 'ifconfig-push %s %s\n' "$MIKROTIK_VPN_IP" "$vpn_netmask" > "/etc/openvpn/server/ccd/$CLIENT_NAME"

  systemctl enable openvpn-server@svnet >/dev/null
  systemctl restart openvpn-server@svnet
  ok "OpenVPN service запущен: openvpn-server@svnet"
}

generate_mikrotik_ovpn() {
  load_installed_config
  local easy="/etc/openvpn/easy-rsa"
  mkdir -p "$CLIENTS_DIR" "$MIKROTIK_DIR"

  {
    cat <<OVPN
client
dev tun
proto $OVPN_PROTO
remote $SERVER_IP $OVPN_PORT
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-128-GCM
auth SHA256
auth-nocache
verb 3
route-nopull
pull-filter ignore "redirect-gateway"
tun-mtu 1500
mssfix 1360

<ca>
OVPN
    cat "$easy/pki/ca.crt"
    cat <<OVPN
</ca>
<cert>
OVPN
    cat "$easy/pki/issued/$CLIENT_NAME.crt"
    cat <<OVPN
</cert>
<key>
OVPN
    cat "$easy/pki/private/$CLIENT_NAME.key"
    cat <<OVPN
</key>
OVPN
  } > "$CLIENTS_DIR/mikrotik.ovpn"
  cp -a "$CLIENTS_DIR/mikrotik.ovpn" "$MIKROTIK_DIR/mikrotik.ovpn"
  chmod 0600 "$CLIENTS_DIR/mikrotik.ovpn" || true
  chmod 0644 "$MIKROTIK_DIR/mikrotik.ovpn" || true
  ok "MikroTik .ovpn создан."
}
