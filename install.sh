#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="/opt/mikrotik-vpn"
REPO_DIR="/opt/mikrotik-vpn/repo"
CLI="/usr/local/bin/mikrotik-vpn"
ALIAS_CLI="/usr/local/bin/svnet"
GIT_URL="${MIKROTIK_VPN_GIT_URL:-https://github.com/kadixLife/SVNET.git}"

if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

ok() { printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*"; }
fail() { printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$*"; }
info() { printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*"; }

usage() {
  cat <<'TEXT'
Usage:
  sudo ./install.sh
  sudo ./install.sh --fresh
  sudo ./install.sh --safe-upgrade

Installs MikroTik_VPN CLI-only manager and starts OpenVPN setup.
TEXT
}

confirm() {
  local prompt="$1" answe
  read -r -p "$prompt [y/N] " answer || return 1
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]]
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    fail "Запустите от root: sudo ./install.sh"
    exit 1
  fi
}

supported_os() {
  [[ -r /etc/os-release ]] || return 1
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ "${ID:-}" == "ubuntu" && ( "${VERSION_ID:-}" == "22.04" || "${VERSION_ID:-}" == "24.04" ) ]]
}

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

clone_repo() {
  command -v git >/dev/null 2>&1 || {
    fail "git не найден. Установите git и повторите установку."
    return 1
  }
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$GIT_URL" "$REPO_DIR"
}

sync_source_repo() {
  mkdir -p "$(dirname "$REPO_DIR")"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
      --exclude 'output' \
      --exclude 'backups' \
      "$ROOT_DIR/" "$REPO_DIR/"
  else
    mkdir -p "$REPO_DIR"
    tar --exclude='output' --exclude='backups' -C "$ROOT_DIR" -cf - . | tar -C "$REPO_DIR" -xf -
  fi
}

prepare_repo_dir() {
  if [[ -d "$REPO_DIR/.git" ]]; then
    if command -v git >/dev/null 2>&1; then
      git -C "$REPO_DIR" fetch origin || return 1
      git -C "$REPO_DIR" pull --ff-only origin main || return 1
    fi
    return 0
  fi

  if [[ -e "$REPO_DIR" ]]; then
    if repo_dir_has_entries "$REPO_DIR"; then
      backup_nogit_repo_di
      clone_repo
      return $?
    fi
    rmdir "$REPO_DIR" 2>/dev/null || {
      backup_nogit_repo_di
      clone_repo
      return $?
    }
  fi

  if [[ -d "$ROOT_DIR/.git" ]]; then
    sync_source_repo
  else
    clone_repo
  fi

  if [[ ! -d "$REPO_DIR/.git" ]]; then
    fail "$REPO_DIR создан без .git. Update-система зависит от Git."
    return 1
  fi
}

install_cli() {
  install -m 0755 "$REPO_DIR/mikrotik-vpn" "$CLI" || return 1
  cat > "$ALIAS_CLI" <<'ALIAS'
#!/usr/bin/env bash
exec /usr/local/bin/mikrotik-vpn "$@"
ALIAS
  chmod 0755 "$ALIAS_CLI"
  ok "CLI установлен: $CLI"
  ok "Compatibility alias установлен: $ALIAS_CLI"
}

detect_existing_install() {
  [[ -f /opt/mikrotik-vpn/config/mikrotik-vpn.conf ]] && return 0
  [[ -f /etc/openvpn/server/mikrotik-vpn.conf ]] && return 0
  [[ -x "$CLI" ]] && return 0
  return 1
}

main() {
  case "${1:-}" in
    --help|-h)
      usage
      exit 0
      ;;
    ""|--fresh|--safe-upgrade)
      ;;
    *)
      fail "Неизвестный аргумент: $1"
      usage
      exit 2
      ;;
  esac

  require_root
  supported_os || {
    fail "Поддерживаются Ubuntu 22.04 и 24.04."
    exit 1
  }

  if detect_existing_install; then
    echo "Найдена существующая установка MikroTik VPN."
    confirm "Обновить CLI/repo и открыть установку без destructive reinstall?" || {
      info "Установка отменена."
      exit 0
    }
  else
    echo "MikroTik VPN не найден. Это чистый сервер."
    confirm "Установить MikroTik VPN с нуля?" || {
      info "Установка отменена."
      exit 0
    }
  fi

  prepare_repo_dir || exit 1
  install_cli || exit 1
  "$CLI" --install
}

main "$@"
