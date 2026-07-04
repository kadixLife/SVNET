#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'TEXT'
Usage:
  sudo ./update.sh

Runs safe MikroTik_VPN update through the CLI.
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
    echo "[FAIL] Неизвестный аргумент: $1"
    usage
    exit 2
    ;;
esac

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "[FAIL] Запустите от root: sudo ./update.sh"
  exit 1
fi

if [[ -x /usr/local/bin/mikrotik-vpn ]]; then
  exec /usr/local/bin/mikrotik-vpn --update
fi

if [[ -x "$ROOT_DIR/mikrotik-vpn" ]]; then
  exec "$ROOT_DIR/mikrotik-vpn" --update
fi

echo "[FAIL] mikrotik-vpn CLI не найден."
echo "Сначала выполните: sudo ./install.sh"
exit 1
