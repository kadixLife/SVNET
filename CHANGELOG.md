# CHANGELOG

## 1.1.0-alpha.1 - 2026-07-01

- Начат новый этап SVNET Admin Panel: добавлен отдельный модуль `admin/` с Docker Compose, backend API, frontend dashboard skeleton, `.env.example` и Nginx example.
- Backend MVP использует Fastify, JWT httpOnly cookie auth, bcrypt password hash, PostgreSQL action log и allowlist wrapper для безопасного вызова `svnet`.
- Frontend MVP использует Next.js, TypeScript, Tailwind CSS, shadcn-style локальные UI components и Recharts для read-only dashboard.
- Добавлены endpoints для health, status, doctor, version, HTTP publish, updates, backups, lists viewer и MikroTik read-only checks.
- Добавлена документация `docs/ADMIN_PANEL.md` и `admin/README.md`.
- В CLI добавлены `--admin-install`, `--admin-status`, `--admin-start`, `--admin-stop`; пункт меню 4 теперь готовит GUI Admin Panel без автоматического запуска.

## 1.0.4 - 2026-07-01

- Убран шумный `[WARN] HTTP ...: 000` во время retry в `--publish-on`: теперь показываются INFO-сообщения ожидания и попыток, а WARN/FAIL выводятся только после исчерпания retry.
- `--publish-status` в безопасном offline-режиме больше не проверяет URL и показывает, что публикация отключена штатно.
- В диагностике listener добавлена отдельная строка `Served directory: /opt/svobodanet/output`, потому что CWD процесса Python может быть `/` при запуске с `--directory`.

## 1.0.3 - 2026-07-01

- Исправлена проверка listener на `8088` в `--publish-status`: порт определяется через полный вывод `ss -H -ltnp`.
- `--publish-status` теперь выводит `[OK] port 8088: listening`, PID и CWD процесса, а при active service без listener показывает FAIL.
- `--publish-on` ждёт до 10 попыток, пока обязательные HTTP URL начнут отдавать `200 OK`.
- `svnet --status` больше не предупреждает об offline HTTP publish: выключенная публикация считается secure mode.

## 1.0.2 - 2026-07-01

- Исправлен HTTP publish: `--publish-on` теперь очищает старый listener на `8088`, перезаписывает systemd unit и проверяет HTTP 200 для обязательных файлов.
- `svnet-http.service` теперь запускается временно с `Restart=no` и без автозапуска.
- `--publish-off` останавливает service, отключает autostart, убирает оставшийся listener на `8088` и проверяет, что порт закрыт.
- `--publish-status` и `--doctor` показывают service state, listener на `8088`, PID, cwd процесса и HTTP-коды URL.
- Добавлено предупреждение о постороннем HTTP process, если service inactive, но порт `8088` всё ещё слушается.

## 1.0.1 - 2026-07-01

- Исправлена установка `/opt/svobodanet/repo`: каталог теперь сохраняется как полноценный Git-репозиторий с `.git`.
- Добавлена команда `svnet --repair-git-repo` для восстановления repo без изменения OpenVPN, firewall, MikroTik configs, output и пользовательских списков.
- `svnet --doctor` теперь проверяет repo, `.git`, remote origin и `git fetch`.
- Добавлены безопасные команды HTTP publish: `--publish-on`, `--publish-off`, `--publish-status`.
- Исправлена проверка IP `tun-svnet` в `svnet --status`.
- Добавлены Git update-команды `--check-updates`, `--update-dry-run`, `--update`.
- Меню оформлены единообразно: у каждого пункта есть короткое описание.
- Добавлена release discipline: update-check отдельно показывает изменение VERSION и commit.

## 1.0.0 - 2026-06-28

- Первая production-ready структура Git-репозитория.
- Добавлены `install.sh`, `update.sh`, `uninstall.sh`.
- Добавлен менеджер `svnet` с меню, status, doctor, backup, update и prepare-mikrotik.
- Добавлены templates, migrations, docs и tests.
- Сохранена логика Split VPN-First, local bypass, DNS redirect, MSS clamp и HTTP publish через `--directory`.
