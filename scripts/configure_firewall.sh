#!/usr/bin/env bash
set -euo pipefail

PORTS=("${OPENCODE_PORT:-4096}" "${LOGIN_PORTAL_PORT:-3001}")
if [[ "$#" -gt 0 ]]; then
  PORTS=("$@")
fi

echo "==> Enabling UFW (deny incoming by default)"
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

echo "==> Allowing SSH"
ufw allow OpenSSH

echo "==> Allowing Tailscale UDP (common port)"
ufw allow 41641/udp

echo "==> Allowing app ports on tailscale0 only: ${PORTS[*]}"
for p in "${PORTS[@]}"; do
  ufw allow in on tailscale0 to any port "$p" proto tcp
done

echo "==> Allowing dev port range on tailscale0 only: 8000-8999"
ufw allow in on tailscale0 to any port 8000:8999 proto tcp

ufw --force enable

echo
echo "UFW status:"
ufw status verbose
