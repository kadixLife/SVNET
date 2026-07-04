port {{OVPN_PORT}}
proto {{OVPN_PROTO}}
dev {{OVPN_IF}}
topology subnet

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
crl-verify /etc/openvpn/easy-rsa/pki/crl.pem

server {{VPN_NETWORK}} {{VPN_NETMASK}}
ifconfig-pool-persist /var/log/openvpn/mikrotik-vpn-ipp.txt
client-config-dir /etc/openvpn/server/ccd
client-to-client
keepalive 10 120

cipher AES-128-GCM
auth SHA256
user nobody
group nogroup
persist-key
persist-tun
verb 3
status /var/log/openvpn/mikrotik-vpn-status.log
log-append /var/log/openvpn/mikrotik-vpn.log
explicit-exit-notify 1
