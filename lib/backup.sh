#!/usr/bin/env bash

create_mikrotik_vpn_backup() {
  local kind="${1:-manual}" ts archive stage
  load_installed_config
  mkdirs

  ts="$(date +%Y-%m-%d_%H-%M-%S)"
  archive="$BACKUPS_DIR/mikrotik-vpn-backup-${kind}-${ts}.tar.gz"
  stage="$BACKUPS_DIR/.staging-${kind}-${ts}-$$"

  mkdir -p "$stage/opt/mikrotik-vpn"
  [[ -d "$CONFIG_DIR" ]] && cp -a "$CONFIG_DIR" "$stage/opt/mikrotik-vpn/config"
  [[ -d "$LISTS_DIR" ]] && cp -a "$LISTS_DIR" "$stage/opt/mikrotik-vpn/lists"
  [[ -d "$OUTPUT_DIR" ]] && cp -a "$OUTPUT_DIR" "$stage/opt/mikrotik-vpn/output"
  [[ -d "$DEVICES_DIR" ]] && cp -a "$DEVICES_DIR" "$stage/opt/mikrotik-vpn/devices"
  [[ -f /etc/openvpn/server/mikrotik-vpn.conf ]] && mkdir -p "$stage/etc/openvpn/server" && cp -a /etc/openvpn/server/mikrotik-vpn.conf "$stage/etc/openvpn/server/mikrotik-vpn.conf"
  [[ -f /etc/systemd/system/mikrotik-vpn-http.service ]] && mkdir -p "$stage/etc/systemd/system" && cp -a /etc/systemd/system/mikrotik-vpn-http.service "$stage/etc/systemd/system/mikrotik-vpn-http.service"
  [[ -f /usr/local/bin/mikrotik-vpn ]] && mkdir -p "$stage/usr/local/bin" && cp -a /usr/local/bin/mikrotik-vpn "$stage/usr/local/bin/mikrotik-vpn"

  if tar -czf "$archive" -C "$stage" .; then
    rm -rf "$stage"
    ok "Backup создан: $archive"
    return 0
  fi

  rm -rf "$stage"
  fail "Backup создать не удалось."
  return 1
}
