{ config, pkgs, ... }:
{
  fonts = {
    packages = [
      pkgs.jetbrains-mono
      pkgs.fira-code
      pkgs.nerd-fonts.fira-code
      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji
    ] ++ (builtins.filter pkgs.lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts));
  };
}