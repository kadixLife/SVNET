#!/usr/bin/env bash
set -uo pipefail

CONFIG_DIR="${CONFIG_DIR:-/opt/svobodanet/config}"
CONFIG_FILE="$CONFIG_DIR/svnet.conf"

mkdir -p "$CONFIG_DIR"
if [[ ! -f "$CONFIG_FILE" ]]; then
  cat > "$CONFIG_FILE" <<'CONF'
SVNET_VERSION="1.0.0"
BASE_DIR="/opt/svobodanet"
CONFIG_DIR="/opt/svobodanet/config"
LISTS_DIR="/opt/svobodanet/lists"
OUTPUT_DIR="/opt/svobodanet/output"
CLIENTS_DIR="/opt/svobodanet/output/clients"
MIKROTIK_DIR="/opt/svobodanet/output/mikrotik"
BACKUPS_DIR="/opt/svobodanet/backups"
REPO_DIR="/opt/svobodanet/repo"
CONF
fi

grep -q '^SVNET_VERSION=' "$CONFIG_FILE" || printf '\nSVNET_VERSION="1.0.0"\n' >> "$CONFIG_FILE"
