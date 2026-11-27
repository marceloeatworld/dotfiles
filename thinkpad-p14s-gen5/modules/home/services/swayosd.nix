# SwayOSD - On-screen display for volume/brightness
{ config, pkgs, ... }:

let
  theme = config.theme;
in
{
  # SwayOSD client in PATH (used by Waybar scroll, Hyprland keybindings)
  home.packages = [ pkgs.swayosd ];

  # SwayOSD systemd service - ensures it starts reliably and restarts on crash
  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD - On-screen display for volume/brightness";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # SwayOSD configuration
  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    show_percentage = true
    max_volume = 100
  '';

  # SwayOSD style - subtle and polished
  xdg.configFile."swayosd/style.css".text = ''
    @import url("${config.home.homeDirectory}/.config/theme/current/swayosd.css");
  '';
}
