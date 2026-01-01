# System-wide font configuration for Hyprland
# IMPORTANT: Fonts MUST be in fonts.packages (system-level) for Wayland apps
# home.packages is NOT sufficient for Hyprland/Waybar/etc.
{ pkgs, ... }:

{
  # Enable fontconfig
  fonts.fontconfig.enable = true;

  # System-wide font packages (REQUIRED for Hyprland/Wayland apps)
  fonts.packages = with pkgs; [
    # Base fonts
    liberation_ttf         # Liberation Sans, Serif, Mono (default serif/sans)
    noto-fonts             # Noto Sans (used by GTK)
    noto-fonts-color-emoji # Emoji support
    noto-fonts-cjk-sans    # CJK (Chinese/Japanese/Korean) support

    # Icon fonts
    font-awesome           # Font Awesome icons (Waybar, etc.)

    # Nerd Fonts (for terminals and Waybar)
    nerd-fonts.jetbrains-mono   # JetBrainsMono Nerd Font (default monospace)
    nerd-fonts.caskaydia-cove   # CaskaydiaMono Nerd Font (Cascadia Code)
    nerd-fonts.fira-code        # FiraCode Nerd Font
    nerd-fonts.hack             # Hack Nerd Font
  ];

  # Default fonts configuration
  fonts.fontconfig.defaultFonts = {
    serif = [ "Noto Serif" "Liberation Serif" ];
    sansSerif = [ "Noto Sans" "Liberation Sans" ];
    monospace = [ "JetBrainsMono Nerd Font" "Hack Nerd Font" ];
    emoji = [ "Noto Color Emoji" ];
  };

  # Fontconfig optimizations
  fonts.fontconfig = {
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "default";
    };
  };
}
