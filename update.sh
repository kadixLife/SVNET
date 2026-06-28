#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/backup.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/lists.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/upgrade.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/gui-placeholder.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/mikrotik.sh"

usage() {
  cat <<'TEXT'
Usage:
  sudo ./update.sh

Обновляет СвободаNET из Git-репозитория с backup, changelog, миграциями и проверкой статуса.
TEXT
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    fail "Неизвестный аргумент: $1"
    usage
    exit 2
    ;;
esac

require_root || exit 1

if [[ ! -d "$ROOT_DIR/.git" ]]; then
  fail "update.sh должен запускаться из Git-репозитория."
  echo "Для ручного обновления скачайте новую версию и выполните: sudo ./install.sh"
  exit 1
fi

if ! command_exists git; then
  fail "git не найден."
  exit 1
fi

current_version="$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")"
branch="$(cd "$ROOT_DIR" && git rev-parse --abbrev-ref HEAD)"
upstream="$(cd "$ROOT_DIR" && git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"

if [[ -z "$upstream" ]]; then
  fail "Для ветки $branch не настроен upstream."
  echo "Пример: git branch --set-upstream-to=origin/$branch $branch"
  exit 1
fi

(cd "$ROOT_DIR" && git fetch --tags --prune)

remote_version="$(cd "$ROOT_DIR" && git show "$upstream:VERSION" 2>/dev/null || true)"
remote_version="${remote_version:-unknown}"

echo "Текущая версия: $current_version"
echo "Доступная версия: $remote_version"

if [[ "$remote_version" == "$current_version" ]]; then
  ok "Установлена актуальная версия."
  exit 0
fi

echo
echo "CHANGELOG:"
(cd "$ROOT_DIR" && git show "$upstream:CHANGELOG.md" 2>/dev/null | sed -n '1,120p') || warn "CHANGELOG в upstream не найден."
echo

confirm "Доступна новая версия: $remote_version. Обновить?" || {
  info "Обновление отменено."
  exit 0
}

create_svnet_backup "pre-upgrade"

if ! (cd "$ROOT_DIR" && git merge --ff-only "$upstream"); then
  fail "Не удалось применить обновление fast-forward."
  echo "Rollback: восстановите backup через svnet -> Backup / Restore."
  exit 1
fi

install_repo_files
install_default_lists
run_migrations
setup_gui_placeholder
prepare_mikrotik_from_repo || warn "MikroTik файлы не пересобраны автоматически."

/usr/local/bin/svnet --status || {
  warn "После обновления есть предупреждения в status."
  echo "При необходимости восстановите backup через svnet -> Backup / Restore."
}

ok "Обновление завершено."
