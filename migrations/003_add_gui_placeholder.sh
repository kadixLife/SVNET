#!/usr/bin/env bash
set -uo pipefail

dir="/opt/svobodanet-admin"
mkdir -p "$dir"
if [[ ! -f "$dir/.env.example" ]]; then
  cat > "$dir/.env.example" <<'ENV'
NODE_ENV=production
SVNET_BASE_DIR=/opt/svobodanet
ROUTEROS_HOST=10.88.0.2
ROUTEROS_API_PORT=8728
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
ENV
fi
