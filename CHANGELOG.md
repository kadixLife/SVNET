# CHANGELOG

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
