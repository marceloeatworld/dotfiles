# Hyprlauncher - Official Hyprland launcher
{ config, pkgs, lib, ... }:

let
  themeConfigs = import ../lib/theme-configs.nix { inherit lib; };
in
{
  home.packages = with pkgs; [
    hyprlauncher
  ];

  home.activation.clearHyprlauncherDesktopCache =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.coreutils}/bin/rm -f "$HOME/.local/share/hyprlauncher/desktop.cache"
    '';

  # Hyprtoolkit theme (hyprlauncher, hyprpwcenter, hyprsysteminfo). Build-time
  # fallback: theme-switch relinks this file to the runtime theme's copy.
  xdg.configFile."hypr/hyprtoolkit.conf" = {
    force = true;
    text = themeConfigs.hyprtoolkitConf config.theme;
  };
}
