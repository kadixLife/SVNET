port {{OVPN_PORT}}
proto {{OVPN_PROTO}}
dev {{OVPN_IF}}
topology subnet

server {{VPN_NETWORK}} {{VPN_NETMASK}}
ifconfig-pool-persist /var/log/openvpn/svnet-ipp.txt
client-config-dir /etc/openvpn/server/ccd

ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
crl-verify /etc/openvpn/easy-rsa/pki/crl.pem

cipher AES-128-GCM
data-ciphers AES-128-GCM:AES-256-GCM
data-ciphers-fallback AES-128-GCM
auth SHA256

keepalive 10 60
explicit-exit-notify 1

persist-key
persist-tun

user nobody
group nogroup

sndbuf 0
rcvbuf 0
push "sndbuf 0"
push "rcvbuf 0"

push "dhcp-option DNS 1.1.1.1"
push "dhcp-option DNS 8.8.8.8"

verb 3
status /var/log/openvpn/svnet-status.log
log-append /var/log/openvpn/svnet.log
