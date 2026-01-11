#VERBOSE=1 darwin-rebuild switch --flake '~/nix#mac'
{
  description = "My macbook flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, home-manager, ... }:
  let
    system = "aarch64-darwin";
    linuxSystem = "x86_64-linux";

    pkgs = nixpkgs.legacyPackages.${system};

    configModule = { config, pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;

      # Setup scripts for Sketchybar and NvChad
      system.activationScripts.postActivation.text = ''
        # Create a separate script for NvChad setup that will run at first login
        mkdir -p "$HOME/.config/nixpkgs"
        cat > "$HOME/.config/nixpkgs/setup-nvchad.sh" << 'EOF'
#!/bin/bash
# Setup NvChad for Neovim if it's not already set up
if [ ! -d "$HOME/.config/nvim" ] || [ ! -f "$HOME/.config/nvim/init.lua" ]; then
  echo "Setting up NvChad configuration for Neovim..."
  # Clean any existing neovim configs
  rm -rf "$HOME/.config/nvim" 2>/dev/null || true
  rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
  rm -rf "$HOME/.local/share/nvim" 2>/dev/null || true
  
  # Clone NvChad repository
  git clone -b v2.0 https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1
  echo "NvChad has been installed. Launch nvim to complete setup."
else
  echo "NvChad configuration already exists."
fi
EOF
        chmod +x "$HOME/.config/nixpkgs/setup-nvchad.sh"
        
        # Add script to run at shell initialization
        grep -q "setup-nvchad" "$HOME/.zshrc" || echo '
# Run NvChad setup script if nvim is available
if command -v nvim >/dev/null 2>&1; then
  if [ -f "$HOME/.config/nixpkgs/setup-nvchad.sh" ]; then
    $HOME/.config/nixpkgs/setup-nvchad.sh
    # Remove the line to prevent future runs
    sed -i "" "/setup-nvchad/d" "$HOME/.zshrc"
  fi
fi
' >> "$HOME/.zshrc"
      '';

        # Note: If you manually hid the menu bar before, you'll need to manually show it again:
        # For macOS Sonoma: System Settings -> Control Center -> Automatically hide and show the menu bar -> Never
        # For macOS Ventura: System Settings -> Desktop & Dock -> Automatically hide and show the menu bar -> Never
        # For Pre-Ventura: System Preferences -> Dock & Menu Bar -> Automatically hide and show the menu bar (unchecked)
        
      # Replaced by ./modules/defaults.nix
      

      # Services moved to ./modules/services.nix
      # See ./modules/services.nix for openssh/yabai configs
      

      # Fonts configuration moved to ./modules/fonts.nix
      # See ./modules/fonts.nix for font packages
      

      # Nix settings - updated to use the correct optimization setting
      nix = {
        settings = {
          experimental-features = "nix-command flakes";
          trusted-users = ["root" "archer"];
        };
        optimise = {
          automatic = true;
        };
        gc = {
          automatic = true;
          interval = { Day = 7; };
          options = "--delete-older-than 30d";
        };
      };

      # System configuration
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 6;
      
      # Primary user for nix-darwin options that require it
      system.primaryUser = "archer";
      
      # Security
      security.pam.services.sudo_local.touchIdAuth = true;

      # Basic shell configuration without home-manager
      environment.shellAliases = {
        ll = "ls -la";
        update = "darwin-rebuild switch --flake ~/nix#mac";
        g = "git";
        gs = "git status";
        gc = "git commit";
        gp = "git push";
        gpl = "git pull";
        # Neovim aliases
        vim = "nvim";
        nv = "nvim";
        claer = "clear";
        npm = "pnpm";
        cd = "z";

      };
      
      # Powerlevel10k ZSH theme configuration
      programs.zsh = {
        enable = true;
        promptInit = ''
          # Source powerlevel10k
          source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
          # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
          [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        '';
        interactiveShellInit = ''
          # p10k instant prompt
          if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
            source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
          fi
          
          # Enable powerlevel10k instant prompt
          export ZSH_THEME="powerlevel10k/powerlevel10k"
          
          # Zim compatibility - ensure it doesn't interfere with p10k
          if [[ -f "$HOME/.zim/zimfw.zsh" ]]; then
            # Set ZIM_HOME only if it's not already set
            : ''${ZIM_HOME:="$HOME/.zim"}
            
            # Load Zim after p10k instant prompt 
            if [[ ! -o login ]]; then
              source "$ZIM_HOME/zimfw.zsh"
            fi
          fi
          
          # Common helpful aliases
          alias ls='ls --color=auto'
          alias grep='grep --color=auto'
          alias ..='cd ..'
          alias ...='cd ../..'
        '';
      };

    };

  in {
    darwinConfigurations = {
      mac = nix-darwin.lib.darwinSystem {
        system = system;
        modules = [
          configModule
          ./modules/defaults.nix
          ./modules/services.nix
          ./modules/homebrew.nix
          ./modules/activation.nix
          ./modules/apps.nix
          ./modules/packages.nix
          ./modules/fonts.nix
        ];
      };
    };

    # Expose the darwin-rebuild command as a flake app
    apps.aarch64-darwin.darwin-rebuild = {
      type = "app";
      program = "${nix-darwin.packages.aarch64-darwin.darwin-rebuild}/bin/darwin-rebuild";
    };

  };
}
