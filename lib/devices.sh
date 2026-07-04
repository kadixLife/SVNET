#!/usr/bin/env bash

devices_dir() {
  load_installed_config
  printf '%s\n' "${DEVICES_DIR:-/opt/mikrotik-vpn/devices}"
}
