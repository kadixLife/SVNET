# SVNET Admin Panel

SVNET Admin Panel v1.1.0-alpha.1 - отдельный web-модуль поверх стабильного CLI `svnet`. Он не меняет OpenVPN, MikroTik или firewall напрямую. Все действия выполняются через allowlist команд `svnet`.

## Установка

```bash
sudo svnet --admin-install
sudo nano /opt/svobodanet-admin/.env
sudo svnet --admin-status
sudo svnet --admin-start
```

`--admin-install` делает только подготовку:

- проверяет Docker;
- проверяет Docker Compose;
- проверяет `/opt/svobodanet/repo/admin`;
- создаёт `/opt/svobodanet-admin`;
- копирует `.env.example` в `/opt/svobodanet-admin/.env`, если `.env` ещё нет;
- не перезаписывает существующий `.env`;
- не запускает production без подтверждения.

## Настройка `.env`

Минимально замените:

```text
ADMIN_USER=admin
ADMIN_PASSWORD_HASH=...
JWT_SECRET=...
POSTGRES_PASSWORD=...
DATABASE_URL=postgres://svnet_admin:POSTGRES_PASSWORD@postgres:5432/svnet_admin
SVNET_CLI=/usr/local/bin/svnet
SVNET_BASE_DIR=/opt/svobodanet
```

Сгенерировать bcrypt hash:

```bash
cd /opt/svobodanet/repo/admin/backend
npm install
node -e "const bcrypt=require('bcryptjs'); bcrypt.hash(process.argv[1], 12).then(console.log)" 'CHANGE_STRONG_PASSWORD'
```

## Docker Compose

```bash
cd /opt/svobodanet/repo/admin
sudo docker compose --env-file /opt/svobodanet-admin/.env up -d --build
sudo docker compose --env-file /opt/svobodanet-admin/.env ps
```

Через CLI:

```bash
sudo svnet --admin-start
sudo svnet --admin-status
sudo svnet --admin-stop
```

## Nginx

Пример конфига:

```bash
sudo cp /opt/svobodanet/repo/admin/nginx/svnet-admin.conf.example /etc/nginx/sites-available/svnet-admin.conf
sudo ln -s /etc/nginx/sites-available/svnet-admin.conf /etc/nginx/sites-enabled/svnet-admin.conf
sudo nginx -t
sudo systemctl reload nginx
```

HTTPS auto-setup пока не входит в MVP. Подключите TLS отдельно, например через Certbot.

## Функции MVP

- Login/logout через httpOnly cookie.
- Dashboard: version, commit/update info, OpenVPN/tun/UDP 1194, HTTP publish, RAM/disk, backups.
- HTTP publish control: временно включить, отключить, проверить статус.
- Lists Viewer: только просмотр.
- Update Center: check, dry-run, safe update.
- Backup: список backups и создание backup.
- MikroTik read-only: ping `10.88.0.2`, TCP `8728`.

## MikroTik read-only API

Команды для RouterOS:

```routeros
/user group remove [find name="svnet-readonly"]
/user group add name=svnet-readonly policy=read,api,test

/user remove [find name="svnet-api-read"]
/user add name=svnet-api-read group=svnet-readonly password="CHANGE_STRONG_PASSWORD_HERE"

/ip service set api disabled=no port=8728 address=10.88.0.1/32
/ip service print where name="api"
```

На этапе v1.1 backend только проверяет доступность `10.88.0.2:8728`. Полное чтение RouterOS API планируется позже.

## Ограничения

- Restore backup не запускается из UI.
- Редактирование списков не входит в v1.1.
- HTTP publish должен оставаться выключенным после настройки MikroTik.
- Если Docker backend не имеет доступа к host systemd, некоторые CLI checks могут вернуть raw error. Старый CLI на VPS при этом не меняется.

## Roadmap

- v1.2: редактирование списков, validation, diff preview, backup before apply.
- v1.3: RouterOS API read-only inventory и traffic counters.
- v1.4: restore workflow, роли, расширенный audit log.
