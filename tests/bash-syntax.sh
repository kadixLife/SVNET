#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failed=0

while IFS= read -r file; do
  echo "bash -n $file"
  bash -n "$file" || failed=1
done < <(find "$ROOT_DIR" -type f \( -name '*.sh' -o -name 'mikrotik-vpn' -o -name 'svnet' \) \
  ! -path '*/.git/*' \
  ! -path '*/node_modules/*' \
  ! -path '*/.next/*' \
  ! -path '*/dist/*' \
  ! -path '*/output/*' \
  ! -path '*/backups/*' | sort)

exit "$failed"
