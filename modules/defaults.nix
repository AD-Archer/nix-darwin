{ config, pkgs, lib, ... }:
{
  # Primary user for nix-darwin options that require it
  system.primaryUser = "archer"; 

  # Security
  security.pam.services.sudo_local.touchIdAuth = true;

  # Basic shell configuration
  environment.shellAliases = lib.mkDefault {
    ll = "ls -la";
    update = "cd /etc/nix && sudo darwin-rebuild switch --flake ~/nix#mac";
    g = "git";
    gs = "git status";
    gc = "git commit";
    gp = "git push";
    gpl = "git pull";
    vim = "nvim";
    nv = "nvim";
    claer = "clear";
    npm = "pnpm";
    cd = "z";
    rebuild = "cd /etc/nix && sudo darwin-rebuild switch --flake ~/nix#mac";
  };

  # Powerlevel10k ZSH theme configuration and other zsh setup
  programs.zsh = {
    enable = true;
    promptInit = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
    '';
    interactiveShellInit = ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
      export ZSH_THEME="powerlevel10k/powerlevel10k"
      if [[ -f "$HOME/.zim/zimfw.zsh" ]]; then
        : ''${ZIM_HOME:="$HOME/.zim"}
        if [[ ! -o login ]]; then
          source "$ZIM_HOME/zimfw.zsh"
        fi
      fi
      alias ls='ls --color=auto'
      alias grep='grep --color=auto'
      alias ..='cd ..'
      alias ...='cd ../..'
    '';
  };

  # Nix settings and GC/optimise
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "archer" ];
    };
    optimise = { automatic = true; };
    gc = { automatic = true; interval = { Day = 7; }; options = "--delete-older-than 30d"; };
  };
}