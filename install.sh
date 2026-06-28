#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/detect.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/backup.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/lists.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/openvpn.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/firewall.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/http-publish.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/mikrotik.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/upgrade.sh"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/gui-placeholder.sh"

usage() {
  cat <<'TEXT'
Usage:
  sudo ./install.sh
  sudo ./install.sh --safe-upgrade
  sudo ./install.sh --fresh
TEXT
}

collect_config() {
  load_defaults

  SERVER_IP="${SERVER_IP:-$(detect_public_ip)}"
  WAN_IF="${WAN_IF:-$(detect_wan_if)}"

  echo
  echo "Найдены параметры установки:"
  print_detected_values
  echo

  if confirm "Изменить параметры перед установкой?"; then
    SERVER_IP="$(prompt_value SERVER_IP "$SERVER_IP")"
    WAN_IF="$(prompt_value WAN_IF "$WAN_IF")"
    OVPN_PROTO="$(prompt_value OVPN_PROTO "$OVPN_PROTO")"
    OVPN_PORT="$(prompt_value OVPN_PORT "$OVPN_PORT")"
    VPN_NET="$(prompt_value VPN_NET "$VPN_NET")"
    VPN_SERVER_IP="$(prompt_value VPN_SERVER_IP "$VPN_SERVER_IP")"
    MIKROTIK_VPN_IP="$(prompt_value MIKROTIK_VPN_IP "$MIKROTIK_VPN_IP")"
    HTTP_PORT="$(prompt_value HTTP_PORT "$HTTP_PORT")"
    MIKROTIK_LAN="$(prompt_value MIKROTIK_LAN "$MIKROTIK_LAN")"
    MIKROTIK_LAN_DNS="$(prompt_value MIKROTIK_LAN_DNS "$MIKROTIK_LAN_DNS")"
    MIKROTIK_WAN="$(prompt_value MIKROTIK_WAN "$MIKROTIK_WAN")"
    MIKROTIK_OVPN_IF="$(prompt_value MIKROTIK_OVPN_IF "$MIKROTIK_OVPN_IF")"
  fi

  mkdirs
  write_config_file "$CONFIG_DIR/svnet.conf"
  ok "Конфиг сохранён: $CONFIG_DIR/svnet.conf"
}

preflight() {
  require_root || return 1
  supported_os || {
    fail "Поддерживаются Ubuntu 22.04 и 24.04."
    return 1
  }
  check_internet || {
    fail "Нет доступа в интернет. Fresh install не сможет поставить пакеты."
    return 1
  }
}

fresh_install() {
  preflight || return 1
  collect_config

  port_is_free "$OVPN_PROTO" "$OVPN_PORT" || {
    fail "OpenVPN port $OVPN_PROTO/$OVPN_PORT занят."
    return 1
  }
  port_is_free tcp "$HTTP_PORT" || {
    fail "HTTP port tcp/$HTTP_PORT занят."
    return 1
  }

  echo
  echo "СвободаNET не найден. Это чистый сервер."
  confirm "Установить СвободаNET с нуля?" || {
    info "Установка отменена."
    return 0
  }

  install_server_packages
  install_repo_files
  install_default_lists
  setup_easyrsa_and_openvpn
  setup_svnet_firewall
  setup_http_publish
  generate_mikrotik_ovpn
  setup_gui_placeholder
  run_migrations
  prepare_mikrotik_from_repo

  ok "СвободаNET установлен."
  echo
  echo "Команда для MikroTik:"
  print_mikrotik_command
  echo
  confirm "Перейти в основное меню svnet?" && /usr/local/bin/svnet
}

safe_upgrade() {
  require_root || return 1
  load_installed_config

  echo "Найдена существующая установка СвободаNET."
  echo "Режим: Safe Upgrade."
  confirm "Обновить проект без переустановки OpenVPN и без сброса настроек?" || {
    info "Safe Upgrade отменён."
    return 0
  }

  create_svnet_backup "pre-upgrade"
  mkdirs
  install_repo_files
  install_default_lists
  run_migrations
  setup_gui_placeholder
  prepare_mikrotik_from_repo

  /usr/local/bin/svnet --status || true
  ok "Safe Upgrade завершён. OpenVPN не переустанавливался."
  confirm "Перейти в основное меню svnet?" && /usr/local/bin/svnet
}

main() {
  case "${1:-}" in
    --help|-h)
      usage
      ;;
    --fresh)
      fresh_install
      ;;
    --safe-upgrade)
      safe_upgrade
      ;;
    "")
      if existing_install_detected; then
        safe_upgrade
      else
        fresh_install
      fi
      ;;
    *)
      fail "Неизвестный аргумент: $1"
      usage
      return 2
      ;;
  esac
}

main "$@"
