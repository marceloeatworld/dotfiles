# Hyprlauncher - Official Hyprland launcher
# Monokai Pro Ristretto theme (matching btop, ghostty, system)
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
  # Monokai Pro Ristretto - matching btop, ghostty, waybar
  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    # Hyprtoolkit Theme - Monokai Pro Ristretto

    # Background colors (from btop main_bg)
    background = ${toHyprColor theme.colors.background}
    base = ${toHyprColor theme.colors.background}
    alternate_base = 0xFF3d2f2a

    # Text colors (from btop main_fg)
    text = ${toHyprColor theme.colors.foreground}
    bright_text = ${toHyprColor theme.colors.brightWhite}

    # Accent colors - Ristretto yellow/gold
    accent = ${toHyprColor theme.colors.yellow}
    accent_secondary = ${toHyprColor theme.colors.green}

    # Typography (matching GTK theme)
    font_family = Noto Sans
    font_family_monospace = CaskaydiaMono Nerd Font
    font_size = 12
    h1_size = 18
    h2_size = 15
    h3_size = 13
    small_font_size = 10

    # Icons (matching GTK icon theme)
    icon_theme = Yaru-yellow
  '';

  # Hyprlauncher configuration
  xdg.configFile."hypr/hyprlauncher.conf".text = ''
    # Hyprlauncher Configuration

    grab_focus = true
    cache:enabled = true
    window_size = 550 350

    default_finder = desktop
    desktop_prefix =
    unicode_prefix = .
    math_prefix = =
    font_prefix = '

    desktop_icons = true
    desktop_launch_prefix =
  '';
}
