#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MOSHI_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$MOSHI_DIR/backend"
SECRET_FILE="$BACKEND_DIR/.alpha-smoke-jwt"

cd "$BACKEND_DIR"

if [[ ! -f "$SECRET_FILE" ]]; then
  python -c 'import secrets; print(secrets.token_urlsafe(48))' > "$SECRET_FILE"
  chmod 600 "$SECRET_FILE"
fi

export MOSHI_ENVIRONMENT="alpha-smoke"
export MOSHI_DATABASE_URL="${MOSHI_DATABASE_URL:-sqlite:///./moshi-alpha.db}"
export MOSHI_JWT_SECRET="$(cat "$SECRET_FILE")"
export MOSHI_UPLOADS_DIR="${MOSHI_UPLOADS_DIR:-./moshi-alpha-uploads}"

mkdir -p "$MOSHI_UPLOADS_DIR"
python -m pip install -r requirements.txt

exec python -m uvicorn app.main:app \
  --host 127.0.0.1 \
  --port 8010 \
  --proxy-headers \
  --forwarded-allow-ips='*' \
  --no-server-header
