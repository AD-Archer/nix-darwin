{ config, pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    mkalias  # Needed for application linking
    neovim
    git
    curl
    nodejs
    python3
    pipx      # python package runner
    wget
    btop
    tmux
    bat
    fzf
    fd
    jq        # moved from Homebrew
    gh
    ripgrep
    tree
    go
    lua
    luarocks
    rustc
    rsync
    neofetch
    figlet
    fastfetch
    ffmpeg    # multimedia CLI
    gcc
    pnpm
    zoxide
    gnupg
    libpq     # postgres client libs
  ];
}