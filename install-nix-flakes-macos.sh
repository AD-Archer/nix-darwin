#!/usr/bin/env bash
set -euo pipefail

echo "[*] Checking OS..."
if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script is for macOS (Darwin) only." >&2
  exit 1
fi

echo "[*] Checking for Xcode Command Line Tools..."
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools not found. Triggering install..."
  xcode-select --install || true
  echo
  echo "Please complete the GUI installer, then re-run this script."
  exit 1
fi

if command -v nix >/dev/null 2>&1; then
  echo "[*] Nix is already installed, skipping install step."
else
  echo "[*] Installing Nix (multi-user, official installer)..."
  curl -L https://nixos.org/nix/install | sh -s -- --daemon

  echo
  echo "[*] Nix installer finished."
  echo "You may need to log out and back in, or open a new terminal,"
  echo "so that the Nix environment is loaded before using 'nix'."
fi

echo
echo "[*] Ensuring /etc/nix/nix.conf enables flakes..."
sudo mkdir -p /etc/nix

if [ -f /etc/nix/nix.conf ]; then
  if grep -q '^experimental-features' /etc/nix/nix.conf; then
    echo "[*] Updating existing experimental-features line in /etc/nix/nix.conf..."
    sudo perl -pi -e 's/^experimental-features.*/experimental-features = nix-command flakes/' /etc/nix/nix.conf
  else
    echo "[*] Appending experimental-features line to /etc/nix/nix.conf..."
    echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf >/dev/null
  fi
else
  echo "[*] Creating /etc/nix/nix.conf with experimental-features..."
  echo 'experimental-features = nix-command flakes' | sudo tee /etc/nix/nix.conf >/dev/null
fi

echo
echo "[*] Done."
echo "Next steps:"
echo "  1) Open a NEW terminal (or log out/in)."
echo "  2) Verify Nix and flakes:"
echo "       nix --version"
echo "       nix show-config | grep experimental-features"
echo "     You should see: experimental-features = nix-command flakes"
echo
echo "Once that works, you can apply your macOS config with:"
echo "  nix run nix-darwin -- switch --flake ~/nix#mac"
