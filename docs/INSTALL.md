# Установка

## Быстрый старт

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/OWNER/svobodanet.git
cd svobodanet
sudo ./install.sh
```

## Что делает installer

1. Проверяет root.
2. Проверяет Ubuntu 22.04/24.04.
3. Проверяет интернет.
4. Определяет public IPv4.
5. Определяет WAN interface.
6. Проверяет занятость портов.
7. Определяет Fresh Install или Safe Upgrade.
8. Показывает параметры и даёт их изменить.
9. Сохраняет `/opt/svobodanet/config/svnet.conf`.

## Fresh Install

Fresh Install устанавливает пакеты, создаёт EasyRSA PKI, серверный и клиентский сертификат, запускает OpenVPN, настраивает firewall/NAT, HTTP publish и генерирует MikroTik файлы.

## Safe Upgrade

Safe Upgrade создаёт `pre-upgrade` backup, обновляет код, шаблоны и миграции, не пересоздаёт сертификаты и не меняет рабочий port/proto/interface без явного изменения конфига.
