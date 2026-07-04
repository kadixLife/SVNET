#!/usr/bin/env bash

MIKROTIK_VPN_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIKROTIK_VPN_VERSION="$(tr -d '[:space:]' < "$MIKROTIK_VPN_REPO_ROOT/VERSION")"
MIKROTIK_VPN_GIT_URL="${MIKROTIK_VPN_GIT_URL:-https://github.com/kadixLife/SVNET.git}"

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
    fail "Запустите команду от root."
    return 1
  fi
}

confirm() {
  local prompt="$1" answe
  read -r -p "$prompt [y/N] " answer || return 1
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

prompt_value() {
  local name="$1" current="$2" answe
  read -r -p "$name [$current]: " answer || true
  printf '%s\n' "${answer:-$current}"
}

load_defaults() {
  # shellcheck disable=SC1091
  source "$MIKROTIK_VPN_REPO_ROOT/config/defaults.conf"
}

load_installed_config() {
  load_defaults
  if [[ -f "$CONFIG_DIR/mikrotik-vpn.conf" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_DIR/mikrotik-vpn.conf"
  fi
}

mkdirs() {
  mkdir -p "$CONFIG_DIR" "$LISTS_DIR" "$OUTPUT_DIR" "$CLIENTS_DIR" "$MIKROTIK_DIR" "$BACKUPS_DIR" "$DEVICES_DIR"
}
