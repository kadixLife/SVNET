#!/usr/bin/env bash

install_repo_files() {
  load_installed_config
  mkdirs
  mkdir -p "$REPO_DIR"
  if [[ "$(readlink -f "$SVNET_REPO_ROOT")" != "$(readlink -f "$REPO_DIR")" ]]; then
    if command_exists rsync; then
      rsync -a --delete \
        --exclude '.git' \
        --exclude 'config/svnet.conf' \
        --exclude 'output' \
        --exclude 'backups' \
        "$SVNET_REPO_ROOT/" "$REPO_DIR/"
    else
      tar --exclude='.git' --exclude='config/svnet.conf' --exclude='output' --exclude='backups' -C "$SVNET_REPO_ROOT" -cf - . | tar -C "$REPO_DIR" -xf -
    fi
  fi
  install -m 0755 "$SVNET_REPO_ROOT/svnet" /usr/local/bin/svnet
  ok "Менеджер установлен: /usr/local/bin/svnet"
}

run_migrations() {
  local migration
  mkdir -p "$CONFIG_DIR/migrations-applied"
  for migration in "$SVNET_REPO_ROOT"/migrations/*.sh; do
    [[ -f "$migration" ]] || continue
    local name
    name="$(basename "$migration")"
    if [[ -f "$CONFIG_DIR/migrations-applied/$name" ]]; then
      continue
    fi
    CONFIG_DIR="$CONFIG_DIR" LISTS_DIR="$LISTS_DIR" bash "$migration"
    touch "$CONFIG_DIR/migrations-applied/$name"
    ok "Migration applied: $name"
  done
}
