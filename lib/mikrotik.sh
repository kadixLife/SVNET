#!/usr/bin/env bash

prepare_mikrotik_from_repo() {
  load_installed_config
  if [[ -x /usr/local/bin/mikrotik-vpn ]]; then
    /usr/local/bin/mikrotik-vpn --prepare-mikrotik
  else
    "$MIKROTIK_VPN_REPO_ROOT/mikrotik-vpn" --prepare-mikrotik
  fi
}

print_mikrotik_command() {
  load_installed_config
  echo "/tool fetch url=\"http://$SERVER_IP:$HTTP_PORT/mikrotik/mikrotik-vpn-install.rsc\" dst-path=\"mikrotik-vpn-install.rsc\"; /import file-name=\"mikrotik-vpn-install.rsc\""
}
