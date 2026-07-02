# SVNET Admin Panel v1.1.0-alpha.5

Первый MVP веб-панели для СвободаNET. Модуль живёт отдельно от стабильного CLI и вызывает только allowlist-команды `svnet`.

## Состав

- `frontend/` - Next.js, TypeScript, Tailwind CSS, shadcn-style UI components, Recharts.
- `backend/` - Fastify, TypeScript, JWT httpOnly cookie auth, first-run setup, safe `svnet` wrapper.
- `postgres` - хранит admin users и action log.
- `nginx/svnet-admin.conf.example` - reverse proxy пример без автоматического HTTPS.

## Быстрый старт на VPS

```bash
sudo svnet --admin-install
```

Если Docker или Docker Compose plugin отсутствуют, `svnet` предложит установить их автоматически через `apt`. После подготовки скрипт предложит сразу запустить containers и покажет локальный URL, способ включить домашний доступ и setup token.

## Первичная настройка

Откройте:

```text
http://127.0.0.1:3000/setup
```

Введите setup token из вывода `svnet --admin-install`, затем создайте admin username/password. Пароль хешируется backend-ом и сохраняется в PostgreSQL.

## Lifecycle

```bash
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

Панель после установки слушает только `127.0.0.1:3000` и `127.0.0.1:3001`.

Основной домашний доступ включается отдельно через OpenVPN tunnel:

```bash
sudo svnet --admin-enable-lan-access
sudo svnet --admin-access-status
```

После этого с домашней Wi-Fi/LAN сети откройте:

```text
http://svnet.local
```

Отключить домашний доступ, не останавливая контейнеры:

```bash
sudo svnet --admin-disable-lan-access
```

Аварийно исправить nginx bind, если после старой alpha-версии остался `0.0.0.0:80` или `[::]:80`:

```bash
sudo svnet --admin-fix-nginx-bind
```

SSH tunnel остаётся только developer fallback:

```bash
ssh -L 3000:127.0.0.1:3000 root@SERVER_IP
```

## Безопасность MVP

- Backend не принимает произвольные shell-команды.
- Все вызовы `svnet` идут через allowlist в `backend/src/svnetCli.ts`.
- `publish-on`, `publish-off`, `safe update`, `backup create` требуют confirmation.
- Dangerous actions пишутся в PostgreSQL `action_log`.
- HTTP publish должен оставаться в offline secure mode после настройки MikroTik.
- `.env` не хранится в Git и должен иметь права `600`.
- Admin Panel не открывается на `0.0.0.0` по умолчанию.
- Доступ из домашней сети работает только через nginx на `10.88.0.1:80` и firewall rule для `tun-svnet`.
- `default*` nginx sites должны быть вне `/etc/nginx/sites-enabled`, если они открывают wildcard/public TCP `80`.

## Что пока read-only

- Просмотр status/doctor/version.
- Просмотр route lists.
- Просмотр backups.
- MikroTik: ping `10.88.0.2` и проверка TCP `8728`.
- Restore backup и редактирование списков остаются только в CLI.

## Roadmap

- v1.2: безопасное редактирование списков с diff preview и backup.
- v1.3: RouterOS API integration, read-only inventory, traffic counters.
- v1.4: роли пользователей, audit export, restore workflow с отдельным подтверждением.
