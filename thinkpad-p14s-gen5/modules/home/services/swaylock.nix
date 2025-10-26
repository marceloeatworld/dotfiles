# Swaylock configuration
{ pkgs, ... }:

{
  programs.swaylock = {
    enable = true;
    settings = {
      # Ristretto theme colors
      color = "2c2525";  # Background
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      indicator-thickness = 10;
      inside-color = "2c2525cc";  # Inner with opacity
      inside-clear-color = "f9cc6c";  # Yellow when clearing
      inside-ver-color = "85dacc";  # Cyan when verifying
      inside-wrong-color = "fd6883";  # Pink/red when wrong
      key-hl-color = "adda78";  # Green for key highlights
      line-color = "00000000";  # Transparent line
      ring-color = "403e41";  # Dark gray ring
      ring-clear-color = "f9cc6c";  # Yellow ring when clearing
      ring-ver-color = "85dacc";  # Cyan ring when verifying
      ring-wrong-color = "fd6883";  # Pink/red ring when wrong
      separator-color = "00000000";  # Transparent separator
      text-color = "e6d9db";  # Light mauve text
      text-clear-color = "2c2525";  # Dark text on yellow
      text-ver-color = "2c2525";  # Dark text on cyan
      text-wrong-color = "2c2525";  # Dark text on pink
      bs-hl-color = "fd6883";  # Pink/red for backspace highlight
      show-failed-attempts = true;
    };
  };

  # Swayidle DISABLED - using hypridle instead (configured in hyprland.nix)
  # hypridle is the native Hyprland idle management daemon
  services.swayidle = {
    enable = false;  # DISABLED to avoid conflict with hypridle
    # events = [
    #   { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    #   { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    # ];
    # timeouts = [
    #   { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    #   { timeout = 600; command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off"; resumeCommand = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"; }
    #   { timeout = 900; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    # ];
  };
}
