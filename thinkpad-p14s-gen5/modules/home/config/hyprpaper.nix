# Hyprpaper wallpaper configuration
{ pkgs, ... }:

let
  hyprlandPkg = pkgs.hyprland;
  wallDir = "${hyprlandPkg}/share/hypr";

  # Original Hyprland wallpaper (the cyan droplet logo). Static on purpose:
  # the hourly rotation was removed 2026-07-08 because every hyprpaper swap
  # exposes a frame of the bare compositor background, which is white on
  # light themes and read as a periodic "white flash".
  wallpaperPath = "${wallDir}/wall0.png";
in
{
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    wallpaper {
        monitor =
        path = ${wallpaperPath}
        fit_mode = cover
    }

    # Disable splash
    splash = false

    # Enable IPC for wallpaper switching
    ipc = on
  '';
}
