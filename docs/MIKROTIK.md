# MikroTik

Безопасный порядок:

```bash
sudo mikrotik-vpn --publish-on
```

Вставьте в MikroTik Terminal:

```routeros
/tool fetch url="http://SERVER_IP:8088/mikrotik/mikrotik-vpn-install.rsc" dst-path="mikrotik-vpn-install.rsc"; /import file-name="mikrotik-vpn-install.rsc"
```

После импорта:

```bash
sudo mikrotik-vpn --publish-off
```

Проверка на MikroTik:

```routeros
/interface ovpn-client print detail where name="ovpn-mvpn"
/routing table print where name="to-vpn"
/ip route print where comment~"MikroTik_VPN"
/ip firewall address-list print where list~"MVPN"
/ip firewall mangle print where comment~"MikroTik_VPN"
/ip firewall nat print where comment~"MikroTik_VPN"
/system script print where name~"mikrotik-vpn"
/log print where message~"MikroTik_VPN"
```

Импорт идемпотентный: правила проекта пересоздаются по comment/name/list проекта и не требуют reset роутера.
