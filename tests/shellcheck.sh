#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck не установлен, проверка пропущена."
  exit 0
fi

find "$ROOT_DIR" -type f \( -name '*.sh' -o -name 'mikrotik-vpn' -o -name 'svnet' \) \
  ! -path '*/.git/*' \
  ! -path '*/output/*' \
  ! -path '*/backups/*' -print0 |
  xargs -0 shellcheck
