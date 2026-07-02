#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/admin/docker-compose.yml"
ENV_FILE="$ROOT_DIR/admin/.env.example"
failed=0

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "docker compose config"
  docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config >/dev/null || failed=1
else
  echo "docker compose not available, skipping v2 config check"
fi

if command -v docker-compose >/dev/null 2>&1 && docker-compose version >/dev/null 2>&1; then
  echo "docker-compose config"
  docker-compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" config >/dev/null || failed=1
else
  echo "docker-compose not available, skipping v1 config check"
fi

exit "$failed"
