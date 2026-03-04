#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example to .env and set passwords." >&2
  exit 1
fi

# Load .env so port values apply to this script.
set -a
source .env
set +a

run_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

echo "==> OpenCode (host service)"
if command -v systemctl >/dev/null 2>&1; then
  LOAD_STATE="$(systemctl show -p LoadState --value opencode.service 2>/dev/null || true)"
  if [[ "$LOAD_STATE" == "loaded" ]]; then
    run_sudo systemctl start opencode.service || true
    if systemctl is-active --quiet opencode.service; then
      echo "opencode.service: active"
    else
      echo "opencode.service: not active (check: systemctl status opencode --no-pager)" >&2
    fi
  else
    echo "opencode.service: not installed (see systemd/opencode.service)" >&2
  fi
else
  echo "systemctl not available" >&2
fi

echo
echo "==> File Browser (host service)"
if command -v systemctl >/dev/null 2>&1; then
  LOAD_STATE="$(systemctl show -p LoadState --value filebrowser.service 2>/dev/null || true)"
  if [[ "$LOAD_STATE" == "loaded" ]]; then
    run_sudo systemctl start filebrowser.service || true
    if systemctl is-active --quiet filebrowser.service; then
      echo "filebrowser.service: active"
    else
      echo "filebrowser.service: not active (check: systemctl status filebrowser --no-pager)" >&2
    fi
  else
    echo "filebrowser.service: not installed (see systemd/filebrowser.service)" >&2
  fi
else
  echo "systemctl not available" >&2
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
    echo "File Browser: http://$TS_IP:${FILEBROWSER_PORT:-8001}"
  else
    echo "(tailscale not up yet)"
  fi
fi

echo
echo "Tip: if ports are unreachable over Tailscale, run: sudo ./scripts/configure_firewall.sh"
