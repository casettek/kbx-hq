#!/usr/bin/env bash
set -euo pipefail

if command -v filebrowser >/dev/null 2>&1; then
  echo "filebrowser already installed: $(command -v filebrowser)"
  filebrowser version || true
  exit 0
fi

echo "==> Installing File Browser (https://filebrowser.org)"

# Upstream installer installs to /usr/local/bin (uses sudo if not root).
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

echo
echo "==> Installed"
if command -v filebrowser >/dev/null 2>&1; then
  echo "filebrowser: $(command -v filebrowser)"
  filebrowser version || true
else
  echo "filebrowser not found on PATH after install" >&2
  exit 1
fi
