#!/usr/bin/env bash

repo_dir_has_entries() {
  [[ -d "$1" ]] && find "$1" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null | grep -q .
}

backup_nogit_repo_dir() {
  local ts backup
  ts="$(date +%Y-%m-%d_%H-%M-%S)"
  backup="${REPO_DIR}.nogit.backup_${ts}"
  mv "$REPO_DIR" "$backup"
  warn "Repo folder exists, but it is not a Git repository."
  warn "Старый repo перенесён в: $backup"
}

clone_origin_repo() {
  if ! command_exists git; then
    fail "git не найден. Установите git и повторите команду."
    return 1
  fi

  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "${SVNET_GIT_URL:-https://github.com/kadixLife/SVNET.git}" "$REPO_DIR"
}

sync_source_git_repo() {
  mkdir -p "$(dirname "$REPO_DIR")"
  if command_exists rsync; then
    rsync -a --delete \
      --exclude 'config/svnet.conf' \
      --exclude 'output' \
      --exclude 'backups' \
      "$SVNET_REPO_ROOT/" "$REPO_DIR/"
  else
    mkdir -p "$REPO_DIR"
    tar --exclude='config/svnet.conf' --exclude='output' --exclude='backups' -C "$SVNET_REPO_ROOT" -cf - . | tar -C "$REPO_DIR" -xf -
  fi
}

prepare_git_repo_dir() {
  local source_root target_root
  source_root="$(readlink -f "$SVNET_REPO_ROOT")"

  if [[ -d "$REPO_DIR/.git" ]]; then
    if ! command_exists git; then
      fail "git не найден. Невозможно обновить $REPO_DIR."
      return 1
    fi

    git -C "$REPO_DIR" fetch origin || return 1
    git -C "$REPO_DIR" pull --ff-only origin main || return 1
    return 0
  fi

  if [[ -e "$REPO_DIR" ]]; then
    if repo_dir_has_entries "$REPO_DIR"; then
      backup_nogit_repo_dir
      clone_origin_repo
      return $?
    fi

    rmdir "$REPO_DIR" 2>/dev/null || {
      backup_nogit_repo_dir
      clone_origin_repo
      return $?
    }
  fi

  if [[ -d "$SVNET_REPO_ROOT/.git" ]]; then
    sync_source_git_repo
  else
    clone_origin_repo
  fi

  target_root="$(readlink -f "$REPO_DIR")"
  if [[ "$source_root" != "$target_root" && ! -d "$REPO_DIR/.git" ]]; then
    fail "$REPO_DIR создан без .git. Обновление через Git работать не будет."
    return 1
  fi
}

install_repo_files() {
  load_installed_config
  mkdirs

  prepare_git_repo_dir || return 1
  install -m 0755 "$REPO_DIR/svnet" /usr/local/bin/svnet
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
