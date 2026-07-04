#!/usr/bin/env bash
set -uo pipefail

BASE_DIR="/opt/mikrotik-vpn"
CLI="/usr/local/bin/mikrotik-vpn"
ALIAS_CLI="/usr/local/bin/svnet"
HTTP_SERVICE="mikrotik-vpn-http.service"
OVPN_SERVICE="openvpn-server@mikrotik-vpn"

usage() {
  cat <<'TEXT'
Usage:
  sudo ./uninstall.sh

Stops temporary publish and optionally removes MikroTik_VPN files after backup.
TEXT
}

confirm() {
  local prompt="$1" answe
  read -r -p "$prompt [y/N] " answer || return 1
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

case "${1:-}" in
  --help|-h)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "[FAIL] Неизвестный аргумент: $1"
    usage
    exit 2
    ;;
esac

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[FAIL] Запустите от root: sudo ./uninstall.sh"
  exit 1
fi

cat <<TEXT
Uninstall MikroTik_VPN.

По умолчанию команда:
- остановит temporary HTTP publish;
- предложит остановить OpenVPN;
- предложит удалить CLI;
- не удалит $BASE_DIR без отдельного подтверждения.
TEXT

if [[ -x "$CLI" ]]; then
  "$CLI" --backup || true
fi

if confirm "Остановить $HTTP_SERVICE?"; then
  systemctl disable --now "$HTTP_SERVICE" >/dev/null 2>&1 || true
  rm -f "/etc/systemd/system/$HTTP_SERVICE"
  systemctl daemon-reload >/dev/null 2>&1 || true
fi

if confirm "Остановить $OVPN_SERVICE?"; then
  systemctl disable --now "$OVPN_SERVICE" >/dev/null 2>&1 || true
fi

if confirm "Удалить CLI $CLI и alias $ALIAS_CLI?"; then
  rm -f "$CLI" "$ALIAS_CLI"
fi

if confirm "Удалить $BASE_DIR полностью? Это удалит config/lists/output/backups/repo."; then
  read -r -p "Введите DELETE для подтверждения: " answer || answer=""
  if [[ "$answer" == "DELETE" ]]; then
    rm -rf "$BASE_DIR"
    echo "[OK] $BASE_DIR удалён."
  else
    echo "[WARN] $BASE_DIR оставлен на месте."
  fi
else
  echo "[WARN] $BASE_DIR оставлен на месте."
fi

echo "[OK] Uninstall завершён."
