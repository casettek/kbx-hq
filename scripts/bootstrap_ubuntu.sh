#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Please run as a normal user (no sudo). The script will sudo as needed." >&2
  exit 1
fi

echo "==> Installing base packages"
sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release \
  ufw

echo "==> Installing Docker (Ubuntu packages)"
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get install -y docker.io docker-compose-plugin
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER" || true
  echo "Docker installed. You may need to log out/in for docker group changes." >&2
fi

echo "==> Installing Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

echo "==> Creating host directories"
sudo mkdir -p \
  /srv/agent/opencode-workspace \
  /srv/agent/dropbox \
  /srv/agent/browser-profile

sudo chown -R "$USER":"$USER" /srv/agent

echo "==> Done"
echo
echo "Next steps:"
echo "  1) sudo tailscale up"
echo "  2) sudo ./scripts/configure_firewall.sh"
echo "  3) ./scripts/up.sh"
