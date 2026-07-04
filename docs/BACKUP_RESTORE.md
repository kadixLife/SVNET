# Backup / Restore

Создать backup:

```bash
sudo mikrotik-vpn --backup
```

Восстановить:

```bash
sudo mikrotik-vpn --restore
```

Backup сохраняет:

- `/opt/mikrotik-vpn/config`;
- `/opt/mikrotik-vpn/lists`;
- `/opt/mikrotik-vpn/devices`;
- `/opt/mikrotik-vpn/output`;
- `/etc/openvpn/server/mikrotik-vpn.conf`;
- `/etc/systemd/system/mikrotik-vpn-http.service`;
- `/usr/local/bin/mikrotik-vpn`.

Restore запускается только после подтверждения.
