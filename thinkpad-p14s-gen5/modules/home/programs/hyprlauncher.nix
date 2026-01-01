# Hyprlauncher - Official Hyprland launcher
# Uses hyprtoolkit for theming (Ristretto theme)
{ pkgs, ... }:

{
  # Install hyprlauncher
  home.packages = with pkgs; [
    hyprlauncher
  ];

  # Hyprtoolkit theme configuration (used by hyprlauncher)
  # Ristretto color palette
  xdg.configFile."hypr/hyprtoolkit.conf".text = ''
    # Hyprtoolkit Theme - Ristretto
    # This theme is shared by all hyprtoolkit-based apps (hyprlauncher, etc.)

    # Background colors
    background = FF2C2525
    base = FF2C2525
    alternate_base = FF403E41

    # Text colors
    text = FFE6D9DB
    bright_text = FFF1E5E7

    # Accent colors (Ristretto yellow/gold)
    accent = FFFABD2F
    accent_secondary = FFF9CC6C

    # Typography
    font_size = 12
    h1_size = 18
    h2_size = 15
    h3_size = 13
    small_font_size = 10

    # Icons
    icon_theme = Yaru-yellow
  '';

  # Hyprlauncher configuration
  xdg.configFile."hypr/hyprlauncher.conf".text = ''
    # Hyprlauncher Configuration

    # General
    grab_focus = true

    # Cache (remember frequently used apps)
    cache:enabled = true

    # UI
    window_size = 500 300

    # Finders
    default_finder = desktop
    desktop_prefix =
    unicode_prefix = .
    math_prefix = =
    font_prefix = '

    # Desktop finder options
    desktop_icons = true
    desktop_launch_prefix =
  '';
}
