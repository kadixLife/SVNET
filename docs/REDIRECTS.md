# Redirects And Routing Lists

Списки лежат в `/opt/mikrotik-vpn/lists`.

Лучше менять их через меню:

```bash
sudo mikrotik-vpn
```

Пункт:

```text
3) Редиректы и списки маршрутизации
```

Файлы:

- `direct-domains.txt` - российские сайты напрямую без VPN.
- `vpn-domains.txt` - заблокированные сайты через VPN.
- `direct-ip.txt` - IP/подсети напрямую.
- `vpn-ip.txt` - IP/подсети принудительно через VPN.
- `local-bypass.txt` - локальная сеть без VPN.

После изменения выберите:

```text
4) Обновить списки на роутере
```

Менеджер создаст `mikrotik-vpn-update-lists.rsc`, временно включит publish и покажет команду для MikroTik.
