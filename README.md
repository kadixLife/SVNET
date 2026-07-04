# MikroTik_VPN

MikroTik_VPN - это CLI-менеджер для автоматической настройки VPN на Ubuntu VPS и MikroTik.

Идея простая:

1. Вы ставите проект на VPS.
2. Выбираете OpenVPN.
3. Сервер сам настраивает VPN, firewall, NAT, сертификаты и конфиги.
4. Проект выдаёт одну команду для MikroTik.
5. Вы вставляете команду в RouterOS Terminal.
6. MikroTik сам скачивает `.rsc`, импортирует правила и настраивает split routing.

Без GUI. Без Docker. Без ручного редактирования конфигов.

## Что делает

- Поднимает OpenVPN UDP server на VPS.
- Создаёт MikroTik `.ovpn`.
- Генерирует RouterOS `.rsc` для автоматического импорта.
- Настраивает VPN-first split routing:
  - RU-сервисы идут напрямую без VPN;
  - заблокированные сервисы идут через VPN;
  - локальная сеть не уходит в VPN;
  - неизвестный трафик по умолчанию идёт через VPN.
- Добавляет DNS redirect и MSS clamp.
- Даёт понятное меню для списков доменов/IP.
- Временно публикует конфиги по HTTP `:8088` только на время установки.
- Поддерживает backup, restore и safe Git update.

## Установка

Требования:

- Ubuntu 22.04 или 24.04 на VPS.
- Root-доступ.
- Public IPv4.
- MikroTik RouterOS с поддержкой OpenVPN client.

Команды на VPS:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/kadixLife/SVNET.git
cd SVNET
sudo ./install.sh
```

После установки основная команда:

```bash
sudo mikrotik-vpn
```

Временный alias для совместимости:

```bash
sudo svnet
```

## Основные пути

```text
/usr/local/bin/mikrotik-vpn
/usr/local/bin/svnet                 compatibility alias
/opt/mikrotik-vpn
/opt/mikrotik-vpn/repo
/opt/mikrotik-vpn/config/mikrotik-vpn.conf
/opt/mikrotik-vpn/lists
/opt/mikrotik-vpn/output
/opt/mikrotik-vpn/backups
/opt/mikrotik-vpn/devices
```

OpenVPN:

```text
openvpn-server@mikrotik-vpn
/etc/openvpn/server/mikrotik-vpn.conf
tun-mvpn
UDP 1194
10.88.0.1/24
```

MikroTik:

```text
ovpn-mvpn
10.88.0.2
MVPN_DIRECT_IP
MVPN_FORCE_VPN_IP
MVPN_LOCAL_BYPASS
```

## Настройка MikroTik

После установки VPS покажет команду вида:

```routeros
/tool fetch url="http://SERVER_IP:8088/mikrotik/mikrotik-vpn-install.rsc" dst-path="mikrotik-vpn-install.rsc"; /import file-name="mikrotik-vpn-install.rsc"
```

Безопасный порядок:

```bash
sudo mikrotik-vpn --publish-on
```

Вставьте команду fetch/import в MikroTik Terminal.

После успешного импорта:

```bash
sudo mikrotik-vpn --publish-off
```

Важно: HTTP publish открывает `.ovpn` и `.rsc` публично на `8088`. Держите его включённым только на время установки.

## Меню

```text
1) Установить подключение MikroTik VPN
2) Управление MikroTik-устройствами
3) Редиректы и списки маршрутизации
4) Обновить списки на роутере
5) Проверить состояние сервера
6) Проверить обновления проекта
7) Перезагрузить VPN
8) Удалить подключение
9) Backup / Restore
0) Выход
```

У каждого пункта есть короткое описание прямо в меню.

## Списки маршрутизации

Файлы:

```text
/opt/mikrotik-vpn/lists/direct-domains.txt
/opt/mikrotik-vpn/lists/vpn-domains.txt
/opt/mikrotik-vpn/lists/direct-ip.txt
/opt/mikrotik-vpn/lists/vpn-ip.txt
/opt/mikrotik-vpn/lists/local-bypass.txt
```

Что они значат:

- `direct-domains.txt` - российские сайты напрямую без VPN.
- `vpn-domains.txt` - заблокированные сайты через VPN.
- `direct-ip.txt` - IP/подсети напрямую.
- `vpn-ip.txt` - IP/подсети принудительно через VPN.
- `local-bypass.txt` - домашняя сеть, роутеры, камеры, NAS, принтеры.

Лучше менять списки через меню:

```bash
sudo mikrotik-vpn
```

Пункт:

```text
3) Редиректы и списки маршрутизации
```

После изменения списков обновите MikroTik:

```text
4) Обновить списки на роутере
```

Менеджер пересоберёт `.rsc`, включит временную публикацию и покажет одну команду для RouterOS.

## HTTP publish

Команды:

```bash
sudo mikrotik-vpn --publish-on
sudo mikrotik-vpn --publish-status
sudo mikrotik-vpn --publish-off
```

Нормальное production-состояние:

```text
[OK] HTTP publish: offline secure mode
[OK] port 8088: not listening
```

Если старый service снова поднимает `8088`, выполните:

```bash
sudo mikrotik-vpn --cleanup-legacy-services
sudo mikrotik-vpn --publish-off
```

## Обновление проекта

Проверить:

```bash
sudo mikrotik-vpn --check-updates
```

Показать dry-run:

```bash
sudo mikrotik-vpn --update-dry-run
```

Обновить:

```bash
sudo mikrotik-vpn --update
```

Update делает:

- backup перед изменениями;
- `git fetch`;
- проверку локальных изменений;
- fast-forward only;
- bash syntax check;
- установку нового `/usr/local/bin/mikrotik-vpn`;
- показ версии и commit.

Если `/opt/mikrotik-vpn/repo` есть, но там нет `.git`:

```bash
sudo mikrotik-vpn --repair-git-repo
```

## Backup / Restore

Создать backup:

```bash
sudo mikrotik-vpn --backup
```

Восстановить из меню:

```bash
sudo mikrotik-vpn --restore
```

Backup включает:

- config;
- lists;
- devices;
- output;
- OpenVPN server config;
- HTTP publish unit;
- CLI file.

## Диагностика

Быстрый статус:

```bash
sudo mikrotik-vpn --status
```

Подробная диагностика:

```bash
sudo mikrotik-vpn --docto
```

Проверки вручную:

```bash
systemctl status openvpn-server@mikrotik-vpn --no-page
ip -4 -o addr show dev tun-mvpn
ss -lunp | grep ':1194'
sudo mikrotik-vpn --publish-status
```

## Миграция со старой установки

Если на сервере есть старый `/opt/svobodanet`, проект не удаляет его автоматически.

Рекомендуемый порядок:

1. Сделайте backup старой установки.
2. Перенесите нужные списки из старого `/opt/svobodanet/lists`.
3. Отключите старые temporary HTTP services, если они слушают `8088`.
4. Проверьте новую установку через `sudo mikrotik-vpn --status`.

Старый стабильный tag `v1.0.4` не трогается.

## Версия

Текущая линия:

```text
1.0.0-alpha.1
```

Это новый CLI-only старт проекта MikroTik_VPN на базе рабочей OpenVPN/MikroTik части.
