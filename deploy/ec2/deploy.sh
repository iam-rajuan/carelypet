#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

COMPOSE_FILES=(-f docker-compose.yml)

if [[ "${1:-}" == "--https" ]]; then
  COMPOSE_FILES+=(-f docker-compose.https.yml)
fi

if [[ ! -f ".env" ]]; then
  echo "Missing root .env file."
  exit 1
fi

if [[ ! -f "carelypet-backend/.env" ]]; then
  echo "Missing carelypet-backend/.env file."
  exit 1
fi

docker compose "${COMPOSE_FILES[@]}" pull || true
docker compose "${COMPOSE_FILES[@]}" up -d --build --remove-orphans
docker image prune -f

echo "Deployment complete."
