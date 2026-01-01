# Hyprlauncher - Official Hyprland launcher
# Monokai Pro Ristretto theme (matching btop, ghostty, system)
{ pkgs, ... }:

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
    background = 0xFF2c2421
    base = 0xFF2c2421
    alternate_base = 0xFF3d2f2a

    # Text colors (from btop main_fg)
    text = 0xFFe6d9db
    bright_text = 0xFFf1e5e7

    # Accent colors - Ristretto yellow/gold
    accent = 0xFFf9cc6c
    accent_secondary = 0xFFadda78

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
