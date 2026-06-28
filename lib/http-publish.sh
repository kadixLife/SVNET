#!/usr/bin/env bash

setup_http_publish() {
  load_installed_config
  mkdir -p "$OUTPUT_DIR"
  render_template "$SVNET_REPO_ROOT/templates/systemd/svnet-http.service.tpl" /etc/systemd/system/svnet-http.service \
    HTTP_PORT "$HTTP_PORT" OUTPUT_DIR "$OUTPUT_DIR"
  systemctl daemon-reload
  systemctl enable svnet-http.service >/dev/null
  systemctl restart svnet-http.service
  ok "HTTP publish включён: http://$SERVER_IP:$HTTP_PORT/"
}
