# Hyprpaper wallpaper configuration
{ config, pkgs, lib, ... }:

{
  # Configure hyprpaper with simple wallpaper
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    # Preload wallpaper
    preload = ${config.home.homeDirectory}/Pictures/image.jpeg

    # Set wallpaper for all monitors
    wallpaper = DP-1,${config.home.homeDirectory}/Pictures/image.jpeg
    wallpaper = HDMI-A-1,${config.home.homeDirectory}/Pictures/image.jpeg
    wallpaper = eDP-1,${config.home.homeDirectory}/Pictures/image.jpeg

    # Fallback for any other monitor
    wallpaper = ,${config.home.homeDirectory}/Pictures/image.jpeg

    # Disable splash
    splash = false

    # Enable IPC for wallpaper switching
    ipc = on
  '';
}
