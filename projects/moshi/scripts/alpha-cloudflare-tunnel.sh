#!/usr/bin/env bash
set -euo pipefail

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is not installed or not in PATH." >&2
  exit 1
fi

echo "MOSHI API must already be healthy at http://127.0.0.1:8010/health"
echo "Starting Cloudflare Quick Tunnel. Copy the https://*.trycloudflare.com URL into the MOSHI Alpha APK workflow."
exec cloudflared tunnel --url http://127.0.0.1:8010
