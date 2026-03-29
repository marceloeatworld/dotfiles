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

  # Hyprtoolkit theme configuration (used by hyprlauncher and other hypr apps)
  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    # Hyprtoolkit Theme - from theme.nix

    background = ${toHyprColor theme.colors.background}
    base = ${toHyprColor theme.colors.background}
    alternate_base = ${toHyprColor theme.colors.surface}

    text = ${toHyprColor theme.colors.foreground}
    bright_text = ${toHyprColor theme.colors.brightWhite}

    accent = ${toHyprColor theme.colors.yellow}
    accent_secondary = ${toHyprColor theme.colors.green}

    font_size = 11
    h1_size = 16
    h2_size = 14
    h3_size = 12
    small_font_size = 10

    icon_theme = Yaru-yellow
  '';

  # Hyprlauncher configuration (using defaults - custom options removed due to upstream changes)
}
