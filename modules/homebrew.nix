{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    global = {
      brewfile = true;
      lockfiles = false;  # kept false to avoid `--no-lock` incompat issues
    };
    # Taps - only add custom taps; avoid tapping homebrew/core or homebrew/cask (Homebrew handles them automatically)
    taps = [
      "siderolabs/tap"       # custom taps
      "tw93/tap"
    ];
    brews = [
      "mas"  # Mac App Store CLI - kept in Homebrew for managing MAS apps
      "mole"
      "openssl@3"
      "libiconv"
    ];

    # GUI apps (casks). Keep these as casks since they are apps (not CLI tools).
    casks = [
      # Media & multimedia
      "vlc"
      #"iina"
      "altserver"
      # Productivity & communication
      "slack"
      "vesktop"
      "zoom"                     
      "raycast"
      "postman"
      "obsidian"
      "joplin"
      "vivaldi"
      "jordanbaird-ice"
      "visual-studio-code"

      # Utilities
      "tailscale-app"
      "obs"
      "appcleaner"                # comment out to skip
      "the-unarchiver"            # comment out to skip
      "raspberry-pi-imager"       # comment out to skip
      "dbvisualizer"              # verify availability before enabling

      # Networking
      "tailscale-app"                 
    ];

    masApps = {
    #   "Slack" = 803453959;
      "bitwarden" = 1352778147;
    };
  };
}
