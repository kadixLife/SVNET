#!/usr/bin/env bash

SVNET_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SVNET_VERSION="$(tr -d '[:space:]' < "$SVNET_REPO_ROOT/VERSION")"
SVNET_GIT_URL="${SVNET_GIT_URL:-https://github.com/kadixLife/SVNET.git}"

if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

ok() { printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail() { printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$*"; }
info() { printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }
is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

require_root() {
  if ! is_root; then
    fail "Запустите команду от root: sudo $0"
    return 1
  fi
}

confirm() {
  local prompt="$1" answer
  read -r -p "$prompt [y/N] " answer || return 1
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

prompt_value() {
  local name="$1" current="$2" answer
  read -r -p "$name [$current]: " answer || true
  printf '%s\n' "${answer:-$current}"
}

load_defaults() {
  # shellcheck disable=SC1091
  source "$SVNET_REPO_ROOT/config/defaults.conf"
}

load_installed_config() {
  load_defaults
  if [[ -f "$CONFIG_DIR/svnet.conf" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_DIR/svnet.conf"
  fi
}

mkdirs() {
  mkdir -p "$CONFIG_DIR" "$LISTS_DIR" "$OUTPUT_DIR" "$CLIENTS_DIR" "$MIKROTIK_DIR" "$BACKUPS_DIR"
}

escape_sed_value() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

render_template() {
  local template="$1" output="$2"
  local content
  content="$(cat "$template")"
  shift 2
  while (($#)); do
    local key="$1" value="$2"
    shift 2
    content="$(printf '%s' "$content" | sed "s/{{${key}}}/$(escape_sed_value "$value")/g")"
  done
  printf '%s\n' "$content" > "$output"
}

write_config_file() {
  local file="$1"
  cat > "$file" <<CONF
SVNET_VERSION="$SVNET_VERSION"
BASE_DIR="$BASE_DIR"
CONFIG_DIR="$CONFIG_DIR"
LISTS_DIR="$LISTS_DIR"
OUTPUT_DIR="$OUTPUT_DIR"
CLIENTS_DIR="$CLIENTS_DIR"
MIKROTIK_DIR="$MIKROTIK_DIR"
BACKUPS_DIR="$BACKUPS_DIR"
REPO_DIR="$REPO_DIR"
SVNET_GIT_URL="$SVNET_GIT_URL"

SERVER_IP="$SERVER_IP"
WAN_IF="$WAN_IF"

OVPN_SERVICE="$OVPN_SERVICE"
OVPN_NAME="$OVPN_NAME"
OVPN_IF="$OVPN_IF"
OVPN_PROTO="$OVPN_PROTO"
OVPN_PORT="$OVPN_PORT"
VPN_NET="$VPN_NET"
VPN_SERVER_IP="$VPN_SERVER_IP"
MIKROTIK_VPN_IP="$MIKROTIK_VPN_IP"

HTTP_SERVICE="$HTTP_SERVICE"
HTTP_PORT="$HTTP_PORT"

CLIENT_NAME="$CLIENT_NAME"
MIKROTIK_LAN="$MIKROTIK_LAN"
MIKROTIK_LAN_DNS="$MIKROTIK_LAN_DNS"
MIKROTIK_WAN="$MIKROTIK_WAN"
MIKROTIK_OVPN_IF="$MIKROTIK_OVPN_IF"
CONF
}

cidr_network() {
  python3 - "$1" <<'PY'
import ipaddress, sys
print(ipaddress.ip_network(sys.argv[1], strict=False).network_address)
PY
}

cidr_netmask() {
  python3 - "$1" <<'PY'
import ipaddress, sys
print(ipaddress.ip_network(sys.argv[1], strict=False).netmask)
PY
}
