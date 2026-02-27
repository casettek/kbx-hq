#!/usr/bin/env bash
set -euo pipefail

if ! command -v tailscale >/dev/null 2>&1; then
  echo "tailscale not installed" >&2
  exit 1
fi

echo "Tailscale IPs:"
tailscale ip || true

echo
echo "Tip: access services like http://<magicdns>:PORT or http://<tailscale-ip>:PORT"
