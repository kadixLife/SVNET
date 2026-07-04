client
dev tun
proto {{OVPN_PROTO}}
remote {{SERVER_IP}} {{OVPN_PORT}}
nobind
persist-key
persist-tun
remote-cert-tls serve
cipher AES-128-GCM
auth SHA256
auth-nocache
verb 3
route-nopull
pull-filter ignore "redirect-gateway"
tun-mtu 1500
mssfix 1360

<ca>
{{CA_CERT}}
</ca>
<cert>
{{CLIENT_CERT}}
</cert>
<key>
{{CLIENT_KEY}}
</key>
