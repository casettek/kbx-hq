#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example to .env and set passwords." >&2
  exit 1
fi

docker compose --env-file .env -f compose.yml up -d

echo
echo "==> Running containers"
docker compose -f compose.yml ps

echo
echo "==> Tailscale endpoints (if connected)"
if command -v tailscale >/dev/null 2>&1; then
  TS_IP="$(tailscale ip -4 2>/dev/null || true)"
  if [[ -n "$TS_IP" ]]; then
    echo "Tailscale IP: $TS_IP"
    echo "OpenCode:     http://$TS_IP:${OPENCODE_PORT:-4096}"
    echo "Login Portal: http://$TS_IP:${LOGIN_PORTAL_PORT:-3001}"
  else
    echo "(tailscale not up yet)"
  fi
fi
