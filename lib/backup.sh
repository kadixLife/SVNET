#!/usr/bin/env bash

create_svnet_backup() {
  local kind="${1:-manual}"
  load_installed_config
  mkdirs

  local ts archive stage
  ts="$(date +%Y-%m-%d_%H-%M-%S)"
  archive="$BACKUPS_DIR/svnet-backup-${kind}-${ts}.tar.gz"
  stage="$BACKUPS_DIR/.staging-${kind}-${ts}-$$"
  mkdir -p "$stage"

  [[ -d "$CONFIG_DIR" ]] && mkdir -p "$stage/opt/svobodanet" && cp -a "$CONFIG_DIR" "$stage/opt/svobodanet/config"
  [[ -d "$LISTS_DIR" ]] && mkdir -p "$stage/opt/svobodanet" && cp -a "$LISTS_DIR" "$stage/opt/svobodanet/lists"
  [[ -d "$OUTPUT_DIR" ]] && mkdir -p "$stage/opt/svobodanet" && cp -a "$OUTPUT_DIR" "$stage/opt/svobodanet/output"
  [[ -f /etc/openvpn/server/svnet.conf ]] && mkdir -p "$stage/etc/openvpn/server" && cp -a /etc/openvpn/server/svnet.conf "$stage/etc/openvpn/server/svnet.conf"
  [[ -f /etc/systemd/system/svnet-http.service ]] && mkdir -p "$stage/etc/systemd/system" && cp -a /etc/systemd/system/svnet-http.service "$stage/etc/systemd/system/svnet-http.service"
  [[ -f /usr/local/bin/svnet ]] && mkdir -p "$stage/usr/local/bin" && cp -a /usr/local/bin/svnet "$stage/usr/local/bin/svnet"
  command_exists iptables-save && iptables-save > "$stage/iptables-save.rules" 2>/dev/null || true

  tar -czf "$archive" -C "$stage" .
  case "$stage" in
    "$BACKUPS_DIR"/.staging-*) rm -rf -- "$stage" ;;
    *) warn "Временная директория backup не удалена: $stage" ;;
  esac
  ok "Backup создан: $archive"

  if [[ "$kind" == "manual" ]]; then
    find "$BACKUPS_DIR" -maxdepth 1 -type f -name 'svnet-backup-manual-*.tar.gz' | sort | head -n -3 | xargs -r rm -f
  fi
}
