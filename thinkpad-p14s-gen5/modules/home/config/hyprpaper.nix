# Hyprpaper wallpaper configuration
{ config, ... }:

let
  theme = config.theme;
  wallpaperPath = "${config.home.homeDirectory}/dotfiles/thinkpad-p14s-gen5/assets/wallpapers/${theme.appearance.wallpaper}";
in
{
  # Configure hyprpaper from the active system theme.
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
