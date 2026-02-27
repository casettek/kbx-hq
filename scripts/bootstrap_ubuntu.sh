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

echo "==> Installing Docker (official convenience script)"
if ! command -v docker >/dev/null 2>&1; then
  # Ubuntu's packaged Docker can lag and may not include the compose plugin.
  # The official installer provides docker-ce + docker compose plugin.
  curl -fsSL https://get.docker.com | sudo sh
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER" || true
  echo "Docker installed. You may need to log out/in for docker group changes." >&2
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose plugin not available after install" >&2
  echo "Try: sudo apt-get install -y docker-compose-plugin" >&2
  exit 1
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
