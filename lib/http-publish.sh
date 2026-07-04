#!/usr/bin/env bash

setup_http_publish() {
  load_installed_config
  cat > /etc/systemd/system/mikrotik-vpn-http.service <<SERVICE
[Unit]
Description=MikroTik VPN temporary config HTTP serve
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 -m http.server $HTTP_PORT --bind 0.0.0.0 --directory $OUTPUT_DIR
Restart=no

[Install]
WantedBy=multi-user.target
SERVICE
  systemctl daemon-reload
  systemctl disable mikrotik-vpn-http.service >/dev/null 2>&1 || true
  ok "HTTP publish service подготовлен, но не включён по умолчанию."
}
