#!/usr/bin/env bash

prepare_mikrotik_from_repo() {
  load_installed_config
  if [[ -x /usr/local/bin/svnet ]]; then
    /usr/local/bin/svnet --prepare-mikrotik
  else
    "$SVNET_REPO_ROOT/svnet" --prepare-mikrotik
  fi
}

print_mikrotik_command() {
  load_installed_config
  echo "/tool fetch url=\"http://$SERVER_IP:$HTTP_PORT/mikrotik/svnet-mikrotik-install.rsc\" dst-path=\"svnet-mikrotik-install.rsc\"; /import file-name=\"svnet-mikrotik-install.rsc\""
}
