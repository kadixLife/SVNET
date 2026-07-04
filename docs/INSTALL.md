# Install

MikroTik_VPN ставится на Ubuntu VPS.

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/kadixLife/SVNET.git
cd SVNET
sudo ./install.sh
```

Installer:

- проверяет root;
- проверяет Ubuntu 22.04/24.04;
- сохраняет Git repo в `/opt/mikrotik-vpn/repo`;
- ставит `/usr/local/bin/mikrotik-vpn`;
- создаёт временный alias `/usr/local/bin/svnet`;
- запускает настройку OpenVPN;
- генерирует MikroTik `.ovpn` и `.rsc`;
- показывает одну команду для RouterOS Terminal.

Основная команда:

```bash
sudo mikrotik-vpn
```
