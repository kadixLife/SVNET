# Troubleshooting

## OpenVPN не active

```bash
sudo systemctl status openvpn-server@mikrotik-vpn --no-page
sudo journalctl -u openvpn-server@mikrotik-vpn -n 120 --no-page
sudo openvpn --config /etc/openvpn/server/mikrotik-vpn.conf --verb 4
```

Проверьте порт, сертификаты EasyRSA и синтаксис OpenVPN config.

## tun interface не поднялся

```bash
ip -4 -o addr show dev tun-mvpn
ss -lunp | grep ':1194'
```

Ожидается `10.88.0.1/24`.

## HTTP publish отдаёт 404

Проверьте, что service использует правильную директорию:

```bash
sudo systemctl cat mikrotik-vpn-http.service
sudo mikrotik-vpn --publish-status
curl -I http://127.0.0.1:8088/mikrotik/mikrotik-vpn-install.rsc
```

ExecStart должен содержать:

```text
--directory /opt/mikrotik-vpn/output
```

## Порт 8088 остался открытым

```bash
sudo mikrotik-vpn --publish-off
sudo mikrotik-vpn --cleanup-legacy-services
ss -ltnp | grep ':8088' || echo "OK: port 8088 closed"
```

## MikroTik не подключается

Проверьте:

- interface `ovpn-mvpn`;
- public IP и UDP port `1194`;
- дату/время на MikroTik;
- что `.ovpn` импортировался;
- firewall VPS разрешает UDP `1194`.

## Списки не применились

На VPS:

```bash
sudo mikrotik-vpn --prepare-mikrotik
sudo mikrotik-vpn --publish-on
```

На MikroTik импортируйте `mikrotik-vpn-update-lists.rsc`, затем:

```bash
sudo mikrotik-vpn --publish-off
```
