# Hyprlauncher - Official Hyprland launcher
{ config, pkgs, ... }:

let
  theme = config.theme;

  # Convert hex color to hyprtoolkit format (0xAARRGGBB)
  toHyprColor = hex: "0xFF${builtins.substring 1 6 hex}";
in
{
  # Install hyprlauncher
  home.packages = with pkgs; [
    hyprlauncher
  ];

  home.activation.clearHyprlauncherDesktopCache =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.coreutils}/bin/rm -f "$HOME/.local/share/hyprlauncher/desktop.cache"
    '';

  # Hyprtoolkit theme configuration (used by hyprlauncher and other hypr apps)
  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    # Hyprtoolkit Theme - from theme.nix

    background = ${toHyprColor theme.colors.background}
    base = ${toHyprColor theme.colors.background}
    alternate_base = ${toHyprColor theme.colors.surface}

    text = ${toHyprColor theme.colors.foreground}
    bright_text = ${toHyprColor theme.colors.brightWhite}

    accent = ${toHyprColor theme.colors.accent}
    accent_secondary = ${toHyprColor theme.colors.accentSecondary}

    font_size = 12
    h1_size = 17
    h2_size = 14
    h3_size = 12
    small_font_size = 10

    # Hyprtoolkit crashes if the configured icon theme cannot be resolved.
    # hicolor is always present in the system profile and is enough here.
    icon_theme = hicolor
  '';
}
