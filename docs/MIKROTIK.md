# MikroTik

## Установка правил

После `sudo ./install.sh` или `sudo svnet --prepare-mikrotik` выполните на MikroTik:

```routeros
/tool fetch url="http://SERVER_IP:8088/mikrotik/svnet-mikrotik-install.rsc" dst-path="svnet-mikrotik-install.rsc"; /import file-name="svnet-mikrotik-install.rsc"
```

Используйте команду, которую показывает сам менеджер: там будут правильные `SERVER_IP` и `HTTP_PORT`.

## Проверка

```routeros
/interface ovpn-client print detail where name="ovpn-svnet"
/routing table print where name="to-vpn"
/ip route print where comment~"SVNET"
/ip firewall address-list print where list~"SVNET"
/ip firewall mangle print where comment~"SVNET"
/ip firewall nat print where comment~"SVNET"
/ip dns static print where comment~"SVNET"
/system script print where name~"svnet"
/log print where message~"SVNET"
/ping 10.88.0.1 count=4
```

## Безопасность RouterOS

Скрипты не делают reset и работают только с объектами, у которых есть `SVNET` в comment/name/list. Local bypass располагается выше VPN-first правил. DNS redirect и MSS clamp включены.
