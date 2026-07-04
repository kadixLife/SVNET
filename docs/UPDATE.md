# Update

Проверить обновления:

```bash
sudo mikrotik-vpn --check-updates
```

Dry-run:

```bash
sudo mikrotik-vpn --update-dry-run
```

Обновить:

```bash
sudo mikrotik-vpn --update
```

Safe update делает backup, проверяет локальные изменения, применяет только fast-forward, запускает bash syntax test и обновляет `/usr/local/bin/mikrotik-vpn`.

Если repo повреждён:

```bash
sudo mikrotik-vpn --repair-git-repo
```
