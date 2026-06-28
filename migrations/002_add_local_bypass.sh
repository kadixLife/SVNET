#!/usr/bin/env bash
set -uo pipefail

LISTS_DIR="${LISTS_DIR:-/opt/svobodanet/lists}"
file="$LISTS_DIR/local-bypass.txt"
mkdir -p "$LISTS_DIR"
touch "$file"

add_once() {
  grep -qxF "$1" "$file" || printf '%s\n' "$1" >> "$file"
}

add_once "192.168.50.0/24"
add_once "192.168.0.0/16"
add_once "10.0.0.0/8"
add_once "172.16.0.0/12"
add_once "127.0.0.0/8"
add_once "169.254.0.0/16"
