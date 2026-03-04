#!/usr/bin/env bash
set -euo pipefail

if command -v opencode >/dev/null 2>&1; then
  echo "opencode already installed: $(command -v opencode)"
  opencode --version || true
  exit 0
fi

echo "==> Installing OpenCode (https://opencode.ai/install)"

# Installer downloads release artifacts. Ensure common extract tools exist.
if [[ "$(uname -s)" == "Linux" ]]; then
  if ! command -v tar >/dev/null 2>&1; then
    echo "ERROR: tar not found (required by installer on Linux)" >&2
    exit 1
  fi
else
  if ! command -v unzip >/dev/null 2>&1; then
    echo "ERROR: unzip not found (required by installer on non-Linux)" >&2
    exit 1
  fi
fi

curl -fsSL https://opencode.ai/install | bash

echo
echo "==> Installed"
if command -v opencode >/dev/null 2>&1; then
  echo "opencode: $(command -v opencode)"
  opencode --version || true
else
  echo "opencode not on PATH yet. Re-open your shell or add ~/.opencode/bin to PATH." >&2
fi
