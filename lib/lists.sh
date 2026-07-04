#!/usr/bin/env bash

install_default_lists() {
  load_installed_config
  mkdir -p "$LISTS_DIR"
  for file in direct-domains.txt vpn-domains.txt direct-ip.txt vpn-ip.txt local-bypass.txt; do
    if [[ ! -f "$LISTS_DIR/$file" && -f "$MIKROTIK_VPN_REPO_ROOT/lists/$file" ]]; then
      cp "$MIKROTIK_VPN_REPO_ROOT/lists/$file" "$LISTS_DIR/$file"
      ok "Список установлен: $LISTS_DIR/$file"
    fi
  done
}
