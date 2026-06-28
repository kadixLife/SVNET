#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/backup.sh"

usage() {
  cat <<'TEXT'
Usage:
  sudo ./uninstall.sh

Удаляет менеджер и HTTP publish только после backup и явных подтверждений.
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
load_installed_config

cat <<'TEXT'
Uninstall удалит менеджер СвободаNET и systemd HTTP publish.
OpenVPN ключи, сертификаты и /opt/svobodanet можно оставить на месте.
iptables не очищаются и iptables -F не выполняется.
TEXT

confirm "Создать backup и продолжить uninstall?" || {
  info "Uninstall отменён."
  exit 0
}

create_svnet_backup "pre-uninstall"

if confirm "Остановить svnet-http.service?"; then
  systemctl disable --now svnet-http.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/svnet-http.service
  systemctl daemon-reload
fi

if confirm "Удалить /usr/local/bin/svnet?"; then
  rm -f /usr/local/bin/svnet
fi

if confirm "Удалить /opt/svobodanet полностью? Это удалит config/lists/output/backups."; then
  read -r -p "Введите DELETE для подтверждения: " answer || answer=""
  if [[ "$answer" == "DELETE" ]]; then
    rm -rf /opt/svobodanet
  else
    warn "/opt/svobodanet оставлен на месте."
  fi
else
  warn "/opt/svobodanet оставлен на месте."
fi

ok "Uninstall завершён."
