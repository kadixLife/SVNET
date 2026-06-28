#!/usr/bin/env bash

install_default_lists() {
  load_installed_config
  mkdir -p "$LISTS_DIR"
  for file in direct-domains.txt vpn-domains.txt direct-ip.txt vpn-ip.txt local-bypass.txt; do
    if [[ ! -f "$LISTS_DIR/$file" ]]; then
      cp "$SVNET_REPO_ROOT/lists/$file" "$LISTS_DIR/$file"
    fi
  done
  ok "Списки подготовлены: $LISTS_DIR"
}
