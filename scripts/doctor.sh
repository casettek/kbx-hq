#!/usr/bin/env bash
set -euo pipefail

echo "==> tailscale"
if command -v tailscale >/dev/null 2>&1; then
  tailscale status || true
  tailscale ip -4 || true
else
  echo "tailscale not installed"
fi

echo
echo "==> ufw"
if command -v ufw >/dev/null 2>&1; then
  sudo ufw status verbose || true
else
  echo "ufw not installed"
fi

echo
echo "==> docker"

# Best-effort load .env so compose selection matches scripts/up.sh.
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

if command -v docker >/dev/null 2>&1; then
  docker version || true
  docker compose -f compose.yml ps || true
else
  echo "docker not installed"
fi

echo
echo "==> opencode (host install)"
if command -v opencode >/dev/null 2>&1; then
  opencode --version || true
else
  echo "opencode not found on PATH"
fi
