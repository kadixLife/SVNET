# Backup / Restore

## Создать backup

```bash
sudo svnet --backup
```

или через меню:

```text
6) Backup / Restore
1) Создать backup
```

## Что сохраняется

- `/opt/svobodanet/config`
- `/opt/svobodanet/lists`
- `/opt/svobodanet/output`
- `/etc/openvpn/server/svnet.conf`
- `/etc/systemd/system/svnet-http.service`
- `/usr/local/bin/svnet`
- `iptables-save`

## Restore

Restore доступен в меню `svnet`. Перед restore создаётся `pre-restore` backup. Восстановление требует явного подтверждения.
