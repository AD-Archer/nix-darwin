{ config, pkgs, ... }:
{
  # NvChad setup that runs at first login
  system.activationScripts.postActivation.text = ''
    mkdir -p "$HOME/.config/nixpkgs"
    cat > "$HOME/.config/nixpkgs/setup-nvchad.sh" << 'EOF'
#!/bin/bash
# Setup NvChad for Neovim if it's not already set up
if [ ! -d "$HOME/.config/nvim" ] || [ ! -f "$HOME/.config/nvim/init.lua" ]; then
  echo "Setting up NvChad configuration for Neovim..."
  rm -rf "$HOME/.config/nvim" 2>/dev/null || true
  rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
  rm -rf "$HOME/.local/share/nvim" 2>/dev/null || true
  git clone -b v2.0 https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1
  echo "NvChad has been installed. Launch nvim to complete setup."
else
  echo "NvChad configuration already exists."
fi
EOF
    chmod +x "$HOME/.config/nixpkgs/setup-nvchad.sh"

    grep -q "setup-nvchad" "$HOME/.zshrc" || echo '
# Run NvChad setup script if nvim is available
if command -v nvim >/dev/null 2>&1; then
  if [ -f "$HOME/.config/nixpkgs/setup-nvchad.sh" ]; then
    $HOME/.config/nixpkgs/setup-nvchad.sh
    sed -i "" "/setup-nvchad/d" "$HOME/.zshrc"
  fi
fi
' >> "$HOME/.zshrc"
  '';

  # Debug info for Homebrew integration
  system.activationScripts.homebrewDebug = {
    text = ''
      echo "===== Debugging Homebrew Integration ====="
      echo "Homebrew location: $(which brew)"
      echo "Homebrew version: $(brew --version)"
      mkdir -p $HOME/.config/homebrew-debug
      env | grep HOMEBREW > $HOME/.config/homebrew-debug/env.txt
      echo "Checking Homebrew directories:" >> $HOME/.config/homebrew-debug/dirs.txt
      ls -la /opt/homebrew/Library >> $HOME/.config/homebrew-debug/dirs.txt 2>&1
      ls -la /opt/homebrew/Library/Taps >> $HOME/.config/homebrew-debug/dirs.txt 2>&1
      echo "Debug info saved to $HOME/.config/homebrew-debug/"
    '';
    deps = [];
  };
}