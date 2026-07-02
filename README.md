# СвободаNET

СвободаNET — bash-менеджер для безопасного split-routing через VPS и MikroTik. Проект поднимает OpenVPN server на Ubuntu, публикует конфиги через простой HTTP-сервис и готовит RouterOS `.rsc` файлы для MikroTik.

## Что умеет

- OpenVPN server на Ubuntu 22.04/24.04.
- MikroTik OpenVPN client.
- Режим Split VPN-First: неизвестный трафик идёт через VPN.
- Российские сайты и IP можно отправлять напрямую без VPN.
- Заблокированные сайты и IP можно принудительно отправлять через VPN.
- Локальная сеть всегда bypass без VPN.
- DNS redirect UDP/TCP 53 на MikroTik.
- MSS clamp для OpenVPN.
- Health-watch и emergency direct scripts для RouterOS.
- Backup / Restore.
- Safe Upgrade без переустановки OpenVPN.
- HTTP publish через Python:
  `/usr/bin/python3 -m http.server 8088 --bind 0.0.0.0 --directory /opt/svobodanet/output`

## Архитектура

```text
Ubuntu VPS
  openvpn-server@svnet
  tun-svnet: 10.88.0.1/24
  HTTP publish: /opt/svobodanet/output

MikroTik
  ovpn-svnet: 10.88.0.2
  LAN: 192.168.50.0/24
  routing table: to-vpn
  address-lists: SVNET_DIRECT_IP, SVNET_FORCE_VPN_IP, SVNET_LOCAL_BYPASS
```

## Требования

- Ubuntu 22.04 LTS или 24.04 LTS.
- Root-доступ.
- Публичный IPv4.
- Свободный UDP port для OpenVPN, по умолчанию `1194`.
- Свободный TCP port для HTTP publish, по умолчанию `8088`.
- MikroTik RouterOS 7.x.

## Быстрый старт

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/kadixLife/SVNET.git
cd svobodanet
sudo ./install.sh
```

Installer покажет найденные параметры: public IP, WAN interface, OpenVPN port, HTTP port, VPN subnet и MikroTik LAN. Значения можно изменить перед установкой.

## Чистая установка

На чистом сервере installer покажет:

```text
СвободаNET не найден. Это чистый сервер.
Установить СвободаNET с нуля? [y/N]
```

После подтверждения он установит пакеты, создаст `/opt/svobodanet`, поднимет OpenVPN, настроит firewall/NAT, включит HTTP publish, создаст `mikrotik.ovpn` и RouterOS `.rsc`.

## Обновление существующей установки

Если уже найдены `/opt/svobodanet`, `/usr/local/bin/svnet`, `openvpn-server@svnet`, `tun-svnet` или `/etc/openvpn/server/svnet.conf`, installer переходит в Safe Upgrade:

```text
Найдена существующая установка СвободаNET.
Режим: Safe Upgrade.
Обновить проект без переустановки OpenVPN и без сброса настроек? [y/N]
```

Safe Upgrade создаёт backup, обновляет менеджер/шаблоны/миграции, пересобирает MikroTik `.rsc`, но не удаляет ключи, сертификаты, списки и рабочий OpenVPN.

## Настройка MikroTik

После установки выполните на MikroTik команду, которую покажет installer:

```routeros
/tool fetch url="http://SERVER_IP:8088/mikrotik/svnet-mikrotik-install.rsc" dst-path="svnet-mikrotik-install.rsc"; /import file-name="svnet-mikrotik-install.rsc"
```

`SERVER_IP` и порт будут подставлены installer-ом. Скрипты работают только с объектами `SVNET` и не делают reset роутера.

Важно: HTTP publish нужен только на время установки MikroTik. После импорта конфигов рекомендуется отключить публикацию, потому что `.ovpn` может содержать клиентские ключи:

```bash
sudo svnet --publish-off
```

## Режимы

FullVPN: весь LAN-трафик, кроме локального bypass, идёт через VPN.

Direct: SVNET PBR правила отключены, интернет идёт напрямую.

Split VPN-First: локальная сеть и direct-списки идут напрямую, force-vpn списки и всё неизвестное идут через VPN.

Local bypass: домашние устройства, роутер, камеры, принтеры, NAS и локальные панели не уходят в VPN.

## Управление сайтами и IP

Запустите:

```bash
sudo svnet
```

Пункт меню:

```text
5) Сайты, IP и правила маршрутизации
```

В интерфейсе используются понятные названия: российские сайты напрямую, заблокированные сайты через VPN, локальная сеть без VPN. Технические файлы лежат в `/opt/svobodanet/lists`.

## Backup / Restore

```bash
sudo svnet --backup
```

Backup сохраняет config, lists, output, OpenVPN config, HTTP systemd service, `/usr/local/bin/svnet` и `iptables-save`. Обычных backup хранится 3 последних. Перед restore и upgrade создаются отдельные `pre-*` backups.

## Диагностика

```bash
sudo svnet --status
sudo svnet --doctor
```

Проверяются OpenVPN, tunnel interface, ports, ip_forward, iptables, HTTP publish, output-файлы, public IP и WAN interface.

## HTTP publish

Публикация конфигов работает через `svnet-http.service` и порт `8088`. Включайте её только на время установки или обновления MikroTik:

```bash
sudo svnet --publish-on
sudo svnet --publish-status
sudo svnet --publish-off
```

`--publish-off` останавливает HTTP publish и не трогает OpenVPN, UDP `1194`, firewall rules и сгенерированные `.rsc` файлы.

## GUI Admin Panel

Начиная с `v1.1.0-alpha.4` в репозитории есть отдельный MVP-модуль `admin/`: Next.js frontend, Fastify backend, PostgreSQL action log, first-run setup wizard и безопасный wrapper вокруг `svnet`.

```bash
sudo svnet --admin-install
sudo svnet --admin-status
sudo svnet --admin-access-status
```

`--admin-install` сам проверяет Docker/Compose, генерирует секреты, создаёт `.env`, предлагает запуск и показывает локальный URL для VPS: `http://127.0.0.1:3000`.

По умолчанию Admin Panel работает в режиме `local-only`: только `127.0.0.1`, без доступа из интернета и без доступа из домашней сети.

Чтобы открыть панель из домашней Wi-Fi/LAN сети через уже поднятый OpenVPN tunnel:

```bash
sudo svnet --admin-enable-lan-access
```

После включения откройте на телефоне или ПК дома:

```text
http://svnet.local
```

Команда включает nginx reverse proxy только на `10.88.0.1:80`, добавляет firewall allow rule только для `tun-svnet`/VPN и добавляет DNS static `svnet.local -> 10.88.0.1` в генерируемые MikroTik `.rsc`. Public IP не должен слушать TCP `80`.

Отключить домашний доступ, не останавливая контейнеры:

```bash
sudo svnet --admin-disable-lan-access
```

SSH tunnel остаётся только developer fallback:

```bash
ssh -L 3000:127.0.0.1:3000 root@SERVER_IP
```

Подробная инструкция: [docs/ADMIN_PANEL.md](docs/ADMIN_PANEL.md). Admin Panel не меняет OpenVPN и MikroTik без явной команды; dangerous actions выполняются только через allowlist CLI-команд и требуют подтверждения.

## Безопасность

В Git нельзя публиковать приватные ключи и реальные клиентские конфиги. `.gitignore` исключает:

- `*.key`
- `*.pem`
- `*.p12`
- `*.ovpn`
- `/output/`
- `/backups/`
- `/config/svnet.conf`
- `.env`

В репозитории должны быть только templates, example configs, docs и код.

## Частые ошибки

См. [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Удаление

```bash
sudo ./uninstall.sh
```

Удаление требует подтверждений и сначала создаёт backup.

## Обновление через Git

```bash
sudo svnet --check-updates
sudo svnet --update-dry-run
sudo svnet --update
```

`--check-updates` делает `git fetch`, показывает установленную версию, версию в `origin/main`, commit, remote и путь репозитория.

`--update-dry-run` показывает список файлов, которые изменятся при обновлении. Сервисы не перезапускаются и файлы не меняются.

`--update` создаёт `pre-update` backup, применяет только fast-forward update через `git pull --ff-only origin main`, проверяет bash-синтаксис, обновляет `/usr/local/bin/svnet`, сохраняет пользовательские параметры в `/opt/svobodanet/config/svnet.conf`, применяет новые миграции и запускает `svnet --status`.

Если локальные изменения конфликтуют с GitHub или история разошлась, автоматическое обновление останавливается. Updater не делает destructive reinstall, не удаляет `/opt/svobodanet`, сертификаты, ключи, списки, UDP `1194`, firewall rules и рабочие MikroTik `.rsc`.

Если `/opt/svobodanet/repo` существует, но это обычная папка без `.git`, обновления через Git работать не будут. Проверьте диагностику и восстановите repo:

```bash
sudo svnet --doctor
sudo svnet --repair-git-repo
```

Repair переносит старую папку в `repo.nogit.backup_YYYY-MM-DD_HH-MM-SS`, заново клонирует `https://github.com/kadixLife/SVNET.git` в `/opt/svobodanet/repo` и проверяет bash-синтаксис. OpenVPN, firewall, MikroTik configs, пользовательские списки и output не меняются.

Старый wrapper также доступен:

```bash
sudo ./update.sh
```

## Roadmap

См. [docs/ROADMAP.md](docs/ROADMAP.md).
