# СвободаNET (SVNET)

СвободаNET - это менеджер для Ubuntu VPS и MikroTik. Он поднимает OpenVPN на сервере, готовит конфиги для MikroTik и помогает настроить split-routing: часть трафика идёт напрямую, часть через VPN.

Текущая версия проекта: `1.1.0-alpha.8`.

Важно: базовый CLI уже используется как рабочая основа. Web Admin Panel находится в alpha-ветке и должна включаться осознанно.

## Коротко

- VPS становится OpenVPN gateway.
- MikroTik подключается к VPS как OpenVPN client.
- Домашняя сеть может ходить в интернет напрямую или через VPN по правилам.
- Конфиги для MikroTik генерируются автоматически в виде `.rsc`.
- HTTP publish на `8088` нужен только временно, чтобы MikroTik скачал конфиги.
- Admin Panel доступна локально на VPS или через VPN/LAN, но не должна открываться на public IP.

## Содержание

- [Что умеет](#что-умеет)
- [Архитектура](#архитектура)
- [Требования](#требования)
- [Быстрый старт](#быстрый-старт)
- [Установка MikroTik](#установка-mikrotik)
- [HTTP publish](#http-publish)
- [Обновление](#обновление)
- [Admin Panel](#admin-panel)
- [Основные команды](#основные-команды)
- [Проверка после установки](#проверка-после-установки)
- [Безопасность](#безопасность)

## Что умеет

- Установка OpenVPN server на Ubuntu 22.04/24.04.
- Генерация клиента `mikrotik.ovpn`.
- Генерация RouterOS scripts для MikroTik.
- Режим Split VPN-First: неизвестный трафик идёт через VPN.
- Direct lists: выбранные домены и IP идут напрямую.
- Force VPN lists: выбранные домены и IP принудительно идут через VPN.
- Local bypass: локальная сеть, роутер, камеры, NAS и локальные панели не уходят в VPN.
- DNS redirect UDP/TCP 53 на MikroTik.
- MSS clamp для OpenVPN.
- Health-watch и emergency direct scripts для RouterOS.
- Backup и безопасное восстановление.
- Safe Upgrade через Git без переустановки OpenVPN.
- Диагностика: `svnet --status`, `svnet --doctor`.
- Временная публикация конфигов: `svnet --publish-on/off/status`.
- Очистка старых KADI services, которые могут снова открывать `8088`.
- Web Admin Panel: Next.js frontend, Fastify backend, PostgreSQL, Docker Compose.

## Что проект не делает

- Не делает reset MikroTik.
- Не удаляет чужие firewall rules.
- Не меняет UDP порт OpenVPN `1194` без вашей настройки.
- Не удаляет рабочие `.rsc` файлы при выключении HTTP publish.
- Не открывает Admin Panel в public HTTP, если включён безопасный LAN access mode.
- Не хранит приватные ключи и реальные клиентские конфиги в Git.

## Архитектура

```text
Ubuntu VPS
  /usr/local/bin/svnet                 основной CLI
  /opt/svobodanet                      рабочая директория
  /opt/svobodanet/repo                 Git repo проекта
  /opt/svobodanet/config/svnet.conf    локальные настройки
  /opt/svobodanet/lists                списки доменов и IP
  /opt/svobodanet/output               сгенерированные конфиги
  openvpn-server@svnet                 OpenVPN service
  tun-svnet                            VPN interface, обычно 10.88.0.1/24
  svnet-http.service                   временная публикация output на 8088

MikroTik
  ovpn-svnet                           OpenVPN client interface
  routing table: to-vpn
  address-lists:
    SVNET_DIRECT_IP
    SVNET_FORCE_VPN_IP
    SVNET_LOCAL_BYPASS
  generated scripts:
    svnet-mikrotik-install.rsc
    svnet-mikrotik-split-vpnfirst.rsc
    svnet-mikrotik-fullvpn.rsc
    svnet-mikrotik-direct.rsc
```

Admin Panel, если установлена:

```text
/opt/svobodanet-admin/.env             секреты и настройки Admin Panel
Docker Compose project: svnet-admin
Frontend: 127.0.0.1:3000
Backend:  127.0.0.1:3001
LAN access через nginx: 10.88.0.1:80 -> frontend/backend
```

## Требования

Для VPS:

- Ubuntu 22.04 LTS или Ubuntu 24.04 LTS.
- Root-доступ или пользователь с `sudo`.
- Публичный IPv4.
- Свободный UDP `1194` для OpenVPN.
- Свободный TCP `8088` для временной публикации конфигов.
- Git.

Для MikroTik:

- RouterOS 7.x.
- Доступ к Terminal или WinBox.
- Рабочий WAN interface.
- Понимание вашей LAN-сети, например `192.168.50.0/24`.

Для Admin Panel:

- Docker.
- Docker Compose v2 или legacy `docker-compose` v1.29.2.
- Nginx нужен только для доступа из домашней сети через `svnet.local`.

## Быстрый старт

На чистом VPS:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/kadixLife/SVNET.git
cd SVNET
sudo ./install.sh
```

Installer покажет найденные параметры:

- public IP сервера;
- WAN interface;
- OpenVPN port;
- HTTP publish port;
- VPN subnet;
- MikroTik LAN;
- MikroTik WAN interface;
- имя OpenVPN interface на MikroTik.

Если всё верно, подтвердите установку. Если нужно, измените значения прямо в installer.

После установки проверьте состояние:

```bash
sudo svnet --status
sudo svnet --doctor
```

## Установка MikroTik

Включите временную публикацию конфигов:

```bash
sudo svnet --publish-on
sudo svnet --publish-status
```

На MikroTik выполните команду, которую покажет installer или `svnet`. Пример:

```routeros
/tool fetch url="http://SERVER_IP:8088/mikrotik/svnet-mikrotik-install.rsc" dst-path="svnet-mikrotik-install.rsc"; /import file-name="svnet-mikrotik-install.rsc"
```

Не копируйте `SERVER_IP` из примера буквально. Используйте команду, которую вывел ваш сервер: там будет реальный IP и порт.

После импорта обязательно выключите публикацию:

```bash
sudo svnet --publish-off
sudo svnet --publish-status
```

Безопасное состояние после настройки MikroTik:

```text
[OK] HTTP publish: offline secure mode
[OK] port 8088: not listening
[OK] URL конфигов недоступны, публикация отключена
```

## Режимы маршрутизации

`Split VPN-First`

Основной режим. Локальная сеть и direct lists идут напрямую. Force VPN lists и всё неизвестное идут через VPN.

`FullVPN`

Почти весь LAN-трафик идёт через VPN. Local bypass остаётся напрямую, чтобы не ломать доступ к роутеру, локальным устройствам и сервисам.

`Direct`

SVNET policy routing отключён. Интернет идёт напрямую через обычный WAN.

## Списки доменов и IP

Файлы лежат на VPS:

```text
/opt/svobodanet/lists/direct-domains.txt
/opt/svobodanet/lists/direct-ip.txt
/opt/svobodanet/lists/vpn-domains.txt
/opt/svobodanet/lists/vpn-ip.txt
/opt/svobodanet/lists/local-bypass.txt
```

Управлять списками можно через меню:

```bash
sudo svnet
```

Пункт меню:

```text
Сайты, IP и правила маршрутизации
```

После изменений пересоберите MikroTik configs через меню или команду:

```bash
sudo svnet --prepare-mikrotik
```

Затем временно включите publish, импортируйте новый `.rsc` на MikroTik и снова выключите publish.

## HTTP publish

HTTP publish - это временный web-server на TCP `8088`. Он отдаёт файлы из:

```text
/opt/svobodanet/output
```

Он нужен только для установки или обновления MikroTik. В production его лучше держать выключенным, потому что `.ovpn` может содержать клиентские ключи.

Команды:

```bash
sudo svnet --publish-on
sudo svnet --publish-status
sudo svnet --publish-off
```

Что делают команды:

| Команда | Простыми словами |
| --- | --- |
| `--publish-on` | Временно открывает `http://SERVER_IP:8088`, чтобы MikroTik скачал конфиги. |
| `--publish-status` | Показывает, включена ли публикация, кто слушает порт `8088`, PID, CWD и systemd unit. |
| `--publish-off` | Останавливает публикацию и закрывает `8088`. OpenVPN и MikroTik configs не трогает. |

Если старый сервис снова поднимает `0.0.0.0:8088`, выполните:

```bash
sudo svnet --cleanup-legacy-services
sudo svnet --publish-off
```

Эта команда ищет известные старые KADI services, например:

```text
kadi-routeros-http.service
```

Она предлагает безопасно выполнить `stop`, `disable`, `mask`, но не удаляет данные.

Проверка после cleanup:

```bash
ss -ltnp | grep ':8088' || echo "OK: порт 8088 закрыт"
curl -I --connect-timeout 3 http://PUBLIC_IP:8088
```

Ожидаемый результат для `curl`: connection refused, timeout или HTTP code `000`.

## Обновление

Проверить доступные изменения:

```bash
sudo svnet --check-updates
```

Посмотреть, что изменится, без применения:

```bash
sudo svnet --update-dry-run
```

Применить обновление:

```bash
sudo svnet --update
```

Что такое dry run:

`--update-dry-run` ничего не меняет на сервере. Он только показывает, какие commits и файлы будут затронуты при обновлении. Это безопасная проверка перед реальным `--update`.

Как работает `--update`:

- делает `git fetch`;
- сравнивает VERSION и commit;
- создаёт `pre-update` backup;
- применяет только fast-forward update;
- проверяет bash syntax;
- обновляет `/usr/local/bin/svnet`;
- применяет миграции;
- запускает `svnet --status`.

Updater не переустанавливает OpenVPN, не удаляет certificates/keys, не сбрасывает firewall и не удаляет пользовательские lists.

Если `/opt/svobodanet/repo` есть, но там нет `.git`, восстановите Git repo:

```bash
sudo svnet --doctor
sudo svnet --repair-git-repo
```

Repair переименует старую папку в `repo.nogit.backup_YYYY-MM-DD_HH-MM-SS`, заново клонирует `https://github.com/kadixLife/SVNET.git` в `/opt/svobodanet/repo` и проверит bash syntax.

## Backup и Restore

Создать backup:

```bash
sudo svnet --backup
```

Backup сохраняет:

- config;
- lists;
- output;
- OpenVPN config;
- HTTP systemd service;
- `/usr/local/bin/svnet`;
- `iptables-save`.

Обычные backups ротируются. Перед upgrade и restore создаются отдельные `pre-*` backups.

Подробнее: [docs/BACKUP_RESTORE.md](docs/BACKUP_RESTORE.md).

## Admin Panel

Admin Panel - это web-интерфейс поверх CLI `svnet`.

Состав:

- Frontend: Next.js.
- Backend: Fastify.
- Database: PostgreSQL.
- Запуск: Docker Compose.
- Безопасность: backend вызывает только allowlist команд `svnet`.

Установка:

```bash
sudo svnet --admin-install
```

Статус:

```bash
sudo svnet --admin-status
```

По умолчанию панель доступна только на самом VPS:

```text
http://127.0.0.1:3000
```

Если нужен доступ из домашней сети через уже поднятый VPN tunnel:

```bash
sudo svnet --admin-enable-lan-access
sudo svnet --admin-access-status
```

После этого дома открывайте:

```text
http://svnet.local
```

При первом запуске панель сама откроет `/setup`. Setup token больше не нужен: создайте администратора прямо в браузере, указав `Admin username`, `Admin password` и `Repeat password`.

Безопасное состояние для LAN access:

```text
[OK] Mode: vpn-lan
[OK] 10.88.0.1:80 listening
[OK] Public IP:80 not listening
[OK] No wildcard :80 listener
```

Admin Panel не должна слушать:

```text
0.0.0.0:80
[::]:80
PUBLIC_IP:80
```

Если после старой alpha-версии nginx слушает public/wildcard, выполните:

```bash
sudo svnet --admin-fix-nginx-bind
sudo svnet --admin-access-status
```

Отключить доступ из домашней сети, не удаляя контейнеры:

```bash
sudo svnet --admin-disable-lan-access
```

Остановить Admin Panel containers без удаления данных:

```bash
sudo svnet --admin-stop
```

Полная инструкция: [docs/ADMIN_PANEL.md](docs/ADMIN_PANEL.md).

## Основные команды

| Команда | Что делает |
| --- | --- |
| `sudo svnet` | Открывает интерактивное меню. |
| `sudo svnet --status` | Быстро показывает состояние OpenVPN, tunnel, ports и output files. |
| `sudo svnet --doctor` | Более подробная диагностика сервера и Git repo. |
| `sudo svnet --backup` | Создаёт backup важных настроек и файлов. |
| `sudo svnet --prepare-mikrotik` | Пересобирает `.ovpn` и RouterOS `.rsc` файлы. |
| `sudo svnet --publish-on` | Временно включает HTTP publish на `8088`. |
| `sudo svnet --publish-off` | Выключает HTTP publish и закрывает `8088`. |
| `sudo svnet --publish-status` | Показывает состояние HTTP publish и listener на `8088`. |
| `sudo svnet --cleanup-legacy-services` | Находит старые KADI services и предлагает безопасно отключить их. |
| `sudo svnet --check-updates` | Проверяет VERSION и commit в GitHub. |
| `sudo svnet --update-dry-run` | Показывает будущие изменения без применения. |
| `sudo svnet --update` | Обновляет проект через safe fast-forward update. |
| `sudo svnet --repair-git-repo` | Восстанавливает `/opt/svobodanet/repo`, если там нет `.git`. |
| `sudo svnet --admin-install` | Устанавливает Admin Panel. |
| `sudo svnet --admin-status` | Показывает статус containers и health checks. |
| `sudo svnet --admin-start` | Запускает Admin Panel containers. |
| `sudo svnet --admin-stop` | Останавливает containers без удаления данных. |
| `sudo svnet --admin-logs` | Показывает логи Admin Panel. |
| `sudo svnet --admin-reset-password` | Сбрасывает пароль администратора. |
| `sudo svnet --admin-reset-setup` | Developer recovery: удаляет admin users и снова открывает `/setup` после подтверждения. |
| `sudo svnet --admin-cleanup-docker` | Освобождает место без удаления Docker volumes. |
| `sudo svnet --admin-enable-lan-access` | Включает доступ к панели из домашней сети через VPN. |
| `sudo svnet --admin-disable-lan-access` | Выключает LAN access к панели. |
| `sudo svnet --admin-fix-nginx-bind` | Исправляет небезопасный nginx bind на public/wildcard `:80`. |

## Проверка после установки

На VPS:

```bash
sudo svnet --status
sudo svnet --doctor
sudo svnet --publish-status
```

Проверка OpenVPN:

```bash
systemctl status openvpn-server@svnet --no-pager
ip -4 -o addr show dev tun-svnet
ss -lunp | grep ':1194'
```

Проверка HTTP publish, если он временно включён:

```bash
curl -I http://127.0.0.1:8088/clients/mikrotik.ovpn
curl -I http://127.0.0.1:8088/mikrotik/svnet-mikrotik-install.rsc
```

Проверка после выключения publish:

```bash
sudo svnet --publish-off
ss -ltnp | grep ':8088' || echo "OK: порт 8088 закрыт"
```

Проверка Admin LAN access:

```bash
sudo svnet --admin-access-status
curl -I http://10.88.0.1
curl -I --connect-timeout 3 http://PUBLIC_IP
```

Для public IP ожидается refused, timeout или HTTP code `000`.

## Production checklist

Перед тем как считать установку готовой:

- `sudo svnet --status` показывает OpenVPN active и `tun-svnet: 10.88.0.1`.
- UDP `1194` слушается только OpenVPN.
- MikroTik подключился через `ovpn-svnet`.
- Нужные `.rsc` файлы сгенерированы и не пустые.
- HTTP publish выключен: `sudo svnet --publish-status`.
- TCP `8088` не слушается на public/wildcard.
- Если включена Admin Panel, `sudo svnet --admin-access-status` не показывает `0.0.0.0:80`, `[::]:80` или `PUBLIC_IP:80`.
- Старые KADI services отключены, если они снова поднимали `8088`.

Если при Admin Panel rebuild не хватает места:

```bash
sudo svnet --admin-cleanup-docker
sudo svnet --admin-update
```

Cleanup не удаляет Docker volumes с PostgreSQL данными.

## Разработка и проверки

Локальные проверки shell scripts:

```bash
bash tests/bash-syntax.sh
bash tests/shellcheck.sh
```

Проверка Docker Compose config для Admin Panel:

```bash
bash tests/admin-compose-config.sh
```

Backend:

```bash
cd admin/backend
npm install
npm run build
```

Frontend:

```bash
cd admin/frontend
npm install
npm run lint
npm run build
```

## Безопасность

Не публикуйте в Git:

- приватные ключи;
- реальные `.ovpn`;
- `.env`;
- `/opt/svobodanet/config/svnet.conf`;
- `/opt/svobodanet/output`;
- backups.

`.gitignore` уже исключает:

```text
*.key
*.pem
*.p12
*.ovpn
.env
/output/
/backups/
/config/svnet.conf
```

После установки MikroTik держите HTTP publish выключенным:

```bash
sudo svnet --publish-off
```

Перед включением Admin LAN access проверьте, что старый publish не слушает public/wildcard:

```bash
sudo svnet --publish-status
sudo svnet --cleanup-legacy-services
```

## Документация

- [docs/INSTALL.md](docs/INSTALL.md) - установка.
- [docs/MIKROTIK.md](docs/MIKROTIK.md) - команды и проверка MikroTik.
- [docs/UPDATE.md](docs/UPDATE.md) - обновление.
- [docs/BACKUP_RESTORE.md](docs/BACKUP_RESTORE.md) - backup и restore.
- [docs/ADMIN_PANEL.md](docs/ADMIN_PANEL.md) - Admin Panel.
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - частые проблемы.
- [docs/ROADMAP.md](docs/ROADMAP.md) - план развития.

## Удаление

```bash
sudo ./uninstall.sh
```

Uninstall требует подтверждений и сначала создаёт backup.

## Лицензия

См. [LICENSE](LICENSE).
