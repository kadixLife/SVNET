# SVNET Admin Panel

SVNET Admin Panel v1.1.0-alpha.8 - отдельный web-модуль поверх стабильного CLI `svnet`. Он не меняет OpenVPN, MikroTik или firewall без явной команды. Все dangerous actions выполняются только через allowlist команд `svnet`.

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
- генерирует `JWT_SECRET` и `POSTGRES_PASSWORD`;
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
11) Сбросить первичную настройку
12) Настроить доступ из домашней сети
0) Назад
```

## Первичная настройка

Основной пользовательский сценарий - открыть панель из домашней сети как роутер:

```text
http://svnet.local/setup
```

или:

```text
http://10.88.0.1/setup
```

Страница `/setup` больше не требует setup token. При первом запуске она показывает поля:

- Admin username;
- Admin password;
- Repeat password.

Нажмите `Создать администратора`. Backend создаст первого admin только если:

- в PostgreSQL ещё нет admin user;
- запрос пришёл из trusted network: `127.0.0.1/32` или `10.88.0.0/24`;
- Host разрешён: `svnet.local`, `10.88.0.1`, `127.0.0.1`, `localhost`;
- нет признаков public/wildcard exposure для setup flow.

Пароль не хранится в `.env`: backend хеширует его bcrypt и сохраняет hash в PostgreSQL. После создания первого администратора `/setup` закрывается и показывает кнопку `Перейти ко входу`.

## Доступ из домашней сети

Admin Panel по умолчанию слушает только localhost VPS:

```text
127.0.0.1:3000
127.0.0.1:3001
```

Это режим `local-only`. Он безопасен после установки, но не удобен для обычного использования дома.

Основной пользовательский сценарий - открыть панель как роутер:

```text
http://svnet.local
```

Для этого включите режим `vpn-lan`:

```bash
sudo svnet --admin-enable-lan-access
sudo svnet --admin-access-status
```

Команда проверит OpenVPN, `tun-svnet` с IP `10.88.0.1`, запущенные admin containers, nginx и firewall. Если nginx не установлен, будет запрос подтверждения на установку через `apt`.

Что настраивается:

- nginx reverse proxy слушает только `10.88.0.1:80`;
- frontend проксируется на `127.0.0.1:3000`;
- backend `/api/` проксируется на `127.0.0.1:3001/api/`;
- firewall rule разрешает TCP `80` только на интерфейсе `tun-svnet` из VPN subnet;
- MikroTik `.rsc` получает DNS static `svnet.local -> 10.88.0.1`.

Public IP и `0.0.0.0:80` не должны слушать Admin Panel. Если `svnet --admin-access-status` видит wildcard/public listener, это warning, который нужно исправить перед production.

Аварийное исправление nginx bind после старой alpha-версии:

```bash
sudo svnet --admin-fix-nginx-bind
```

Команда переносит `default*` из `/etc/nginx/sites-enabled` в `/etc/nginx/svnet-disabled`, пересоздаёт `svnet-admin.conf`, проверяет `nginx -T`, reload nginx, `ss` и public IP curl.

Отключить домашний доступ:

```bash
sudo svnet --admin-disable-lan-access
```

Контейнеры при этом не останавливаются. Локальный доступ `127.0.0.1:3000` остаётся.

Режим `public-https` зарезервирован на будущее и сейчас отключён.

## SSH tunnel для разработчика

SSH tunnel больше не основной пользовательский flow. Используйте его только как developer fallback:

```bash
ssh -L 3000:127.0.0.1:3000 root@SERVER_IP
```

Затем в браузере на ПК:

```text
http://127.0.0.1:3000
```

## Почему не открываем GUI в интернет напрямую

Admin Panel управляет backup, update и HTTP publish. Даже с авторизацией её нельзя бездумно публиковать на `0.0.0.0`. Безопасный порядок:

1. По умолчанию держать `local-only`.
2. Для дома включать `vpn-lan`: `10.88.0.1:80` через OpenVPN tunnel.
3. Не открывать TCP `80` на public IP.
4. HTTPS/public-доступ рассматривать отдельно только в будущем режиме `public-https`.

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
sudo svnet --admin-reset-setup
sudo svnet --admin-cleanup-docker
sudo svnet --admin-access-status
sudo svnet --admin-enable-lan-access
sudo svnet --admin-disable-lan-access
sudo svnet --admin-fix-nginx-bind
sudo svnet --cleanup-legacy-services
```

`--admin-stop` выполняет `docker compose down`, но не удаляет volumes, `.env` и PostgreSQL данные.

`--admin-remove` требует два подтверждения. По умолчанию данные не удаляются; удаление volumes и `/opt/svobodanet-admin` спрашивается отдельно.

## Safe update и disk cleanup

```bash
sudo svnet --admin-update
```

Команда не делает `docker compose down` перед сборкой. Порядок безопасный:

1. Проверить свободное место: `df -h /`.
2. Показать Docker usage: `docker system df`.
3. Проверить `docker compose config`.
4. Собрать новые images: `docker compose build backend frontend`.
5. Только если build успешен: `docker compose up -d --force-recreate`.
6. Проверить `backend`/`frontend` running и health `200`.

Если build не прошёл, старые containers не останавливаются. Если после recreate health не прошёл, команда показывает последние logs и завершается с FAIL.

Если свободного места меньше 2 GB:

```bash
sudo svnet --admin-cleanup-docker
```

Cleanup очищает apt cache, npm cache, Docker builder cache, stopped containers, unused networks и dangling images. Docker volumes по умолчанию не удаляются.

## Как сбросить пароль

```bash
sudo svnet --admin-reset-password
```

Команда спросит username и новый пароль, затем обновит bcrypt hash в PostgreSQL через backend helper. Пароль не пишется в `.env`.

## Как сбросить первичную настройку

```bash
sudo svnet --admin-reset-setup
```

Это developer recovery. Команда требует подтверждение словом `RESET_SETUP`, удаляет существующих admin users из PostgreSQL и снова открывает `/setup`. Она не удаляет `.env`, Docker volumes, OpenVPN, MikroTik configs и firewall.

## Как удалить админку

```bash
sudo svnet --admin-remove
```

Удаление не трогает OpenVPN, MikroTik configs и firewall. Docker volumes и `/opt/svobodanet-admin` удаляются только после отдельных подтверждений.

## Функции MVP

- Login/logout через httpOnly cookie.
- First-run setup через `/setup` без setup token.
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
- Старый `kadi-routeros-http.service` нужно отключить через `sudo svnet --cleanup-legacy-services`, если он снова поднимает `0.0.0.0:8088`.
- Backend не принимает произвольные shell-команды.
- Docker install всегда требует подтверждение.

## Roadmap

- v1.2: редактирование списков, validation, diff preview, backup before apply.
- v1.3: RouterOS API read-only inventory и traffic counters.
- v1.4: restore workflow, роли, расширенный audit log.
