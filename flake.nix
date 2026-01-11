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

      # Homebrew configuration with all packages consolidated here
      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;
          cleanup = "zap"; # Removes all unmanaged homebrew packages
          upgrade = true;
        };
        global = {
          brewfile = true;
          lockfiles = false;  # Disable lockfiles - --no-lock is deprecated in newer brew
        };
        taps = [
          "siderolabs/tap"
          "tw93/tap"
          # "FelixKratz/formulae" # Removed Sketchybar tap
          # "homebrew/cask-fonts" # This tap is deprecated according to Homebrew
        ];
        brews = [
          # Development tools
          "mas"
          "node"
          "python@3.13"
          "pipx"
          "zsh-completions"
          "bitwarden-cli"
          "neovim"
          "git"
          "curl"
          "jq"
          "fd"
          "fzf"
          "bat"
          "htop"
          "tmux"
          "gh"           # GitHub CLI
          "ffmpeg"
          "ripgrep"
          "btop"
          "tree"
          "go"
          "lua"
          "luarocks"
          "watch"
          "rsync"
          "neofetch"
          "ollama"
          "fastfetch"
          "figlet"
          "gcc"
          "gemini-cli"
          "gnupg"
          "infisical"
          "libpq"
          "opencode"
          "pnpm"
          "siderolabs/tap/talosctl"
          "tw93/tap/mole"
          "uv"
          "zoxide"
          # Removed Sketchybar
        ];
        casks = [
          # Utilities
          "altserver"
          "mist"
          "vlc"
          "ghostty"
          "obs"
          "latest"
          "the-unarchiver"
          "tailscale"
          "raycast"       # Productivity
          "appcleaner"    # App uninstaller
          "zoom"
          "dbvisualizer"
          "gimp"
          "iina"
          "jordanbaird-ice"
          "lens"
          "obsidian"
          "postman"
          "raspberry-pi-imager"
          "slack"
          "transmission"
          "vesktop"
          "vivaldi"

          # Fonts for development
          "font-jetbrains-mono-nerd-font"      # JetBrains Mono Nerd Font for NvChad
          "font-fira-mono-nerd-font"           # Fira Mono Nerd Font
          "sf-symbols"                         # Keeping SF Symbols as it's generally useful
        ];
        masApps = {
          # "AnkiApp-Flashcards" = 1366312254;  # No longer available in App Store
          # "eero" = 1498025513;  # No longer available in App Store
          "bitwarden"= 1352778147;
          # "live-wallpapers"= 1552826194;
        };
      };

      # System packages installed via Nix - keeping only what's necessary for system functionality
      # and not available via Homebrew
      environment.systemPackages = with pkgs; [
        mkalias  # Needed for application linking
        zsh-powerlevel10k  # For Powerlevel10k ZSH theme
        neovim  # Add Neovim through Nix to ensure it's available during activation
      ];

      # Improved application linking
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = [ "/Applications" ];
        };
      in ''
        echo "Setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "Copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

      # Enhanced system defaults for better Mac experience
      system.defaults = {
        # Dock settings
        dock = {
          autohide = true;
          show-recents = false;
          mru-spaces = false;
          minimize-to-application = true;
          orientation = "right";
          tilesize = 48;
        };
        
        # Finder settings
        finder = {
          AppleShowAllExtensions = true;
          FXEnableExtensionChangeWarning = false;
          QuitMenuItem = true;
          _FXShowPosixPathInTitle = true;
          CreateDesktop = true;
          ShowPathbar = true;
          ShowStatusBar = true;
        };
        
        # Trackpad settings
        trackpad = {
          Clicking = true;
          TrackpadThreeFingerDrag = false;
          TrackpadRightClick = true;
        };
        
        # General UI/UX
        NSGlobalDomain = {
          AppleKeyboardUIMode = 3;
          ApplePressAndHoldEnabled = false;
          InitialKeyRepeat = 15;
          KeyRepeat = 2;
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticDashSubstitutionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticQuoteSubstitutionEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          NSNavPanelExpandedStateForSaveMode = true;
          NSNavPanelExpandedStateForSaveMode2 = true;
          "com.apple.swipescrolldirection" = false;
          "com.apple.keyboard.fnState" = true;
        };
        
        # Menu bar settings - restored to show the default menu bar
        menuExtraClock.Show24Hour = false;
        menuExtraClock.ShowSeconds = false;
        
        # For macOS Sonoma and newer - uncomment if you're on Sonoma
        # controlCenter.AutoHide = false;
        
        # Note: If you manually hid the menu bar before, you'll need to manually show it again:
        # For macOS Sonoma: System Settings -> Control Center -> Automatically hide and show the menu bar -> Never
        # For macOS Ventura: System Settings -> Desktop & Dock -> Automatically hide and show the menu bar -> Never
        # For Pre-Ventura: System Preferences -> Dock & Menu Bar -> Automatically hide and show the menu bar (unchecked)
        
        loginwindow.LoginwindowText = "Archer's Macbook 215-437-2912";
        screencapture.location = "~/Pictures/screenshots";
        screensaver.askForPasswordDelay = 10;
      };

      # System services
      services = {
        openssh.enable = true;
        # nix-daemon.enable is now managed by nix.enable
        yabai = {
          enable = false; # Set to true if you want a tiling window manager
          package = pkgs.yabai;
          enableScriptingAddition = true;
          config = {
            layout = "bsp";
            auto_balance = "on";
            window_placement = "second_child";
            window_gap = 10;
            top_padding = 10;
            bottom_padding = 10;
            left_padding = 10;
            right_padding = 10;
            external_bar = "off"; # Menu bar is now handled by macOS
          };
        };
        skhd = {
          enable = false; # Set to true if you want keyboard shortcuts for yabai
          package = pkgs.skhd;
        };
       
      };

      # Fonts - updated to use the new nerd-fonts namespace structure
      fonts = {
        packages = [
          pkgs.jetbrains-mono
          pkgs.fira-code
          pkgs.nerd-fonts.fira-code
          pkgs.noto-fonts
          pkgs.noto-fonts-color-emoji
        ] ++ (builtins.filter pkgs.lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts));
      };

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
          # nix-homebrew.darwinModules.nix-homebrew
          # {
          #   nix-homebrew = {
          #     enable = true;
          #     enableRosetta = true;
          #     user = "archer";
          #     autoMigrate = true;
          #     mutableTaps = false;
          #     taps = {
          #       "homebrew/homebrew-core" = homebrew-core;
          #       "homebrew/homebrew-cask" = homebrew-cask;
          #       "homebrew/homebrew-bundle" = homebrew-bundle;
          #     };
          #   };
          # }
        ];
      };
    };

    # Expose the darwin-rebuild command as a flake app
    apps.aarch64-darwin.darwin-rebuild = {
      type = "app";
      program = "${nix-darwin.packages.aarch64-darwin.darwin-rebuild}/bin/darwin-rebuild";
    };

    nixosConfigurations.arch = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      modules = [
        ./nixos/arch.nix
      ];
    };

    nixosConfigurations.ubuntu-server = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      modules = [
        ./nixos/server.nix
      ];
    };
  };
}
