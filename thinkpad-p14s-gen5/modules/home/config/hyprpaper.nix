# Hyprpaper wallpaper configuration
{ config, ... }:

{
  # Configure hyprpaper to use custom wallpaper
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    # Preload the wallpaper
    preload = ${config.home.homeDirectory}/Pictures/image.jpeg

    # Set the wallpaper for all monitors
    wallpaper = DP-1,${config.home.homeDirectory}/Pictures/image.jpeg
    wallpaper = HDMI-A-1,${config.home.homeDirectory}/Pictures/image.jpeg
    wallpaper = eDP-1,${config.home.homeDirectory}/Pictures/image.jpeg

    # Fallback for any other monitor
    wallpaper = ,${config.home.homeDirectory}/Pictures/image.jpeg

    # Enable splash screen
    splash = false

    # Enable IPC
    ipc = on
  '';
}
