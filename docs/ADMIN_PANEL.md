# SVNET Admin Panel

SVNET Admin Panel v1.1.0-alpha.2 - отдельный web-модуль поверх стабильного CLI `svnet`. Он не меняет OpenVPN, MikroTik или firewall напрямую. Все dangerous actions выполняются только через allowlist команд `svnet`.

## Автоматическая установка

```bash
sudo svnet --admin-install
```

Команда сама:

- проверяет Ubuntu 22.04/24.04;
- проверяет `/opt/svobodanet/repo/admin`;
- проверяет Docker и предлагает установить его через `apt`;
- проверяет Docker Compose plugin и предлагает установить его через `apt`;
- создаёт `/opt/svobodanet-admin`;
- создаёт `/opt/svobodanet-admin/.env`, если его нет;
- генерирует `JWT_SECRET`, `POSTGRES_PASSWORD`, `ADMIN_SETUP_TOKEN`;
- ставит права `600` на `.env`;
- проверяет `docker compose config`;
- предлагает сразу запустить Admin Panel;
- проверяет frontend/backend health.

`.env` не перезаписывается без необходимости. Реальные секреты сохраняются, placeholder-значения заменяются автоматически.

## Запуск через меню

```bash
sudo svnet
```

Пункт:

```text
4) GUI Admin Panel
```

Внутри меню доступны:

```text
1) Установить Admin Panel
2) Статус Admin Panel
3) Запустить Admin Panel
4) Перезапустить Admin Panel
5) Остановить Admin Panel
6) Обновить Admin Panel
7) Переустановить Admin Panel
8) Удалить Admin Panel
9) Показать логи
10) Сбросить пароль администратора
0) Назад
```

## Первичная настройка

После установки откройте:

```text
http://127.0.0.1:3000/setup
```

Введите setup token, который `svnet --admin-install` показал после первого создания `.env`, затем создайте admin username/password. Пароль не хранится в `.env`: backend хеширует его bcrypt и сохраняет hash в PostgreSQL.

## SSH tunnel

Admin Panel по умолчанию слушает только localhost VPS:

```text
127.0.0.1:3000
127.0.0.1:3001
```

Откройте безопасный туннель с вашего ПК:

```bash
ssh -L 3000:127.0.0.1:3000 root@SERVER_IP
```

Затем в браузере на ПК:

```text
http://127.0.0.1:3000
```

## Почему не открываем GUI в интернет напрямую

Admin Panel управляет backup, update и HTTP publish. Даже с авторизацией её нельзя бездумно публиковать на `0.0.0.0`. Безопасный порядок:

1. По умолчанию используйте SSH tunnel.
2. Если нужен постоянный доступ, поставьте Nginx reverse proxy.
3. Подключите HTTPS.
4. Ограничьте доступ firewall/IP allowlist.

Пример Nginx:

```bash
sudo cp /opt/svobodanet/repo/admin/nginx/svnet-admin.conf.example /etc/nginx/sites-available/svnet-admin.conf
sudo ln -s /etc/nginx/sites-available/svnet-admin.conf /etc/nginx/sites-enabled/svnet-admin.conf
sudo nginx -t
sudo systemctl reload nginx
```

HTTPS auto-setup пока не входит в MVP.

## Lifecycle CLI

```bash
sudo svnet --admin-install
sudo svnet --admin-status
sudo svnet --admin-start
sudo svnet --admin-stop
sudo svnet --admin-restart
sudo svnet --admin-update
sudo svnet --admin-reinstall
sudo svnet --admin-remove
sudo svnet --admin-logs
sudo svnet --admin-reset-password
```

`--admin-stop` выполняет `docker compose down`, но не удаляет volumes, `.env` и PostgreSQL данные.

`--admin-remove` требует два подтверждения. По умолчанию данные не удаляются; удаление volumes и `/opt/svobodanet-admin` спрашивается отдельно.

## Как сбросить пароль

```bash
sudo svnet --admin-reset-password
```

Команда спросит username и новый пароль, затем обновит bcrypt hash в PostgreSQL через backend helper. Пароль не пишется в `.env`.

## Как удалить админку

```bash
sudo svnet --admin-remove
```

Удаление не трогает OpenVPN, MikroTik configs и firewall. Docker volumes и `/opt/svobodanet-admin` удаляются только после отдельных подтверждений.

## Функции MVP

- Login/logout через httpOnly cookie.
- First-run setup через `/setup`.
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
- Backend не принимает произвольные shell-команды.
- Docker install всегда требует подтверждение.

## Roadmap

- v1.2: редактирование списков, validation, diff preview, backup before apply.
- v1.3: RouterOS API read-only inventory и traffic counters.
- v1.4: restore workflow, роли, расширенный audit log.
