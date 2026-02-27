#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <domain> <email>"
  exit 1
fi

DOMAIN_NAME="$1"
LETSENCRYPT_EMAIL="$2"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

cd "${ROOT_DIR}"

mkdir -p deploy/certbot/www deploy/certbot/conf

if [[ ! -f .env ]]; then
  echo "Missing root .env file."
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
env_path = Path(".env")
content = env_path.read_text() if env_path.exists() else ""
updates = {
    "DOMAIN_NAME": None,
    "LETSENCRYPT_EMAIL": None,
    "HTTPS_PORT": "443",
}
lines = content.splitlines()
keys = {line.split("=", 1)[0] for line in lines if "=" in line}
for key, value in updates.items():
    if key not in keys:
        lines.append(f"{key}={value or ''}")
env_path.write_text("\n".join(lines).rstrip() + "\n")
PY

sed -i "s/^DOMAIN_NAME=.*/DOMAIN_NAME=${DOMAIN_NAME}/" .env
sed -i "s/^LETSENCRYPT_EMAIL=.*/LETSENCRYPT_EMAIL=${LETSENCRYPT_EMAIL}/" .env

docker compose up -d proxy

docker run --rm \
  -v "${ROOT_DIR}/deploy/certbot/www:/var/www/certbot" \
  -v "${ROOT_DIR}/deploy/certbot/conf:/etc/letsencrypt" \
  certbot/certbot certonly \
  --webroot -w /var/www/certbot \
  --email "${LETSENCRYPT_EMAIL}" \
  --agree-tos --no-eff-email \
  -d "${DOMAIN_NAME}"

docker compose -f docker-compose.yml -f docker-compose.https.yml up -d proxy certbot

echo "HTTPS enabled for ${DOMAIN_NAME}."
