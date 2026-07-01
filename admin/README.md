# SVNET Admin Panel v1.1.0-alpha.1

Первый MVP веб-панели для СвободаNET. Модуль живёт отдельно от стабильного CLI и вызывает только allowlist-команды `svnet`.

## Состав

- `frontend/` - Next.js, TypeScript, Tailwind CSS, shadcn-style UI components, Recharts.
- `backend/` - Fastify, TypeScript, JWT httpOnly cookie auth, bcrypt password hash, safe `svnet` wrapper.
- `postgres` - хранит action log: кто нажал dangerous action, когда и с каким результатом.
- `nginx/svnet-admin.conf.example` - reverse proxy пример без автоматического HTTPS.

## Быстрый старт на VPS

```bash
sudo svnet --admin-install
sudo nano /opt/svobodanet-admin/.env
sudo svnet --admin-status
sudo svnet --admin-start
```

Панель слушает только `127.0.0.1:3000` и `127.0.0.1:3001`. Для доступа из браузера поставьте Nginx перед сервисами.

## Пароль администратора

В `.env` хранится только bcrypt hash:

```bash
cd /opt/svobodanet/repo/admin/backend
npm install
node -e "const bcrypt=require('bcryptjs'); bcrypt.hash(process.argv[1], 12).then(console.log)" 'CHANGE_STRONG_PASSWORD'
```

Полученный hash вставьте в:

```text
ADMIN_PASSWORD_HASH=...
```

Также обязательно замените `JWT_SECRET` и `POSTGRES_PASSWORD`.

## Безопасность MVP

- Backend не принимает произвольные shell-команды.
- Все вызовы `svnet` идут через allowlist в `backend/src/svnetCli.ts`.
- `publish-on`, `publish-off`, `safe update`, `backup create` требуют confirmation.
- Dangerous actions пишутся в PostgreSQL `action_log`.
- HTTP publish должен оставаться в offline secure mode после настройки MikroTik.
- `.env` не хранится в Git.

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
