# Troubleshooting

## OpenVPN не стартует

```bash
sudo systemctl status openvpn-server@svnet --no-pager
sudo journalctl -u openvpn-server@svnet -n 120 --no-pager
sudo openvpn --config /etc/openvpn/server/svnet.conf --verb 4
```

Проверьте порт, сертификаты EasyRSA и синтаксис `/etc/openvpn/server/svnet.conf`.

## Порт занят

```bash
sudo ss -lunp | grep ':1194'
sudo ss -ltnp | grep ':8088'
```

Измените `OVPN_PORT` или `HTTP_PORT` в `/opt/svobodanet/config/svnet.conf` и пересоберите конфиги.

## HTTP 404

HTTP service должен использовать `--directory /opt/svobodanet/output`, а не только `WorkingDirectory`.

```bash
sudo systemctl cat svnet-http.service
curl -I http://127.0.0.1:8088/clients/mikrotik.ovpn
curl -I http://127.0.0.1:8088/mikrotik/svnet-mikrotik-split-vpnfirst.rsc
```

## MikroTik не скачивает `.rsc`

Проверьте public IP, firewall VPS, HTTP port и доступность URL из внешней сети.

## MikroTik OpenVPN не подключается

Проверьте `ovpn-svnet`, сертификат, proto/port, `route-nopull=yes`, дату/время на MikroTik и логи:

```routeros
/log print where message~"ovpn"
```

## RU сайты идут через VPN

Проверьте список российских сайтов и DNS static:

```routeros
/ip dns static print where comment~"SVNET-DOMAIN-DIRECT"
/ip firewall address-list print where list="SVNET_DIRECT_IP"
```

## Всё идёт напрямую

Проверьте, не запущен ли emergency direct:

```routeros
/ip firewall mangle print where comment~"SVNET-PBR"
```

## Локальная сеть не открывается

Проверьте `SVNET_LOCAL_BYPASS` и порядок mangle правил. Local bypass должен быть выше VPN-first default.

## Мало места на MikroTik hAP ac²

Не храните много `.rsc` на роутере. Используйте одну fetch/import команду и удаляйте старые файлы вручную при необходимости.
