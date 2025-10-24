# Swaylock configuration
{ pkgs, ... }:

{
  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font-size = 24;
      indicator-idle-visible = false;
      indicator-radius = 100;
      indicator-thickness = 10;
      inside-color = "1e1e2e";
      inside-clear-color = "f9e2af";
      inside-ver-color = "89b4fa";
      inside-wrong-color = "f38ba8";
      key-hl-color = "a6e3a1";
      line-color = "00000000";
      ring-color = "313244";
      ring-clear-color = "f9e2af";
      ring-ver-color = "89b4fa";
      ring-wrong-color = "f38ba8";
      separator-color = "00000000";
      text-color = "cdd6f4";
      text-clear-color = "1e1e2e";
      text-ver-color = "1e1e2e";
      text-wrong-color = "1e1e2e";
      bs-hl-color = "f38ba8";
      show-failed-attempts = true;
    };
  };

  # Swayidle for automatic locking
  services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { event = "lock"; command = "${pkgs.swaylock}/bin/swaylock -f"; }
    ];
    timeouts = [
      { timeout = 300; command = "${pkgs.swaylock}/bin/swaylock -f"; }
      { timeout = 600; command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off"; resumeCommand = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on"; }
      { timeout = 900; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    ];
  };
}
