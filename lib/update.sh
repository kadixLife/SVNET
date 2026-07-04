#!/usr/bin/env bash

install_repo_files() {
  load_installed_config
  mkdirs
  install -m 0755 "$MIKROTIK_VPN_REPO_ROOT/mikrotik-vpn" /usr/local/bin/mikrotik-vpn
  cat > /usr/local/bin/svnet <<'ALIAS'
#!/usr/bin/env bash
exec /usr/local/bin/mikrotik-vpn "$@"
ALIAS
  chmod 0755 /usr/local/bin/svnet
  ok "CLI установлен: /usr/local/bin/mikrotik-vpn"
}
