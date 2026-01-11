{ config, pkgs, ... }:
{
  services = {
    openssh.enable = true;

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
      };
    };
  };
}