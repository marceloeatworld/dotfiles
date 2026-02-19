# SwayOSD - On-screen display for volume/brightness
{ config, pkgs, ... }:

let
  theme = config.theme;
in
{
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

  # SwayOSD style - minimal
  xdg.configFile."swayosd/style.css".text = ''
    window {
      background: ${theme.colors.background};
      border-radius: 0;
      border: 1px solid ${theme.colors.border};
      padding: 12px;
    }

    #container {
      margin: 6px;
    }

    progressbar {
      min-height: 6px;
      border-radius: 0;
      background: transparent;
    }

    trough {
      min-height: 6px;
      border-radius: 0;
      background: ${theme.colors.surface};
    }

    progress {
      min-height: 6px;
      border-radius: 0;
      background: ${theme.colors.foreground};
    }

    label {
      font-family: "${theme.fonts.mono}";
      font-size: 12px;
      color: ${theme.colors.foreground};
      margin: 4px;
    }

    image {
      color: ${theme.colors.foreground};
    }
  '';
}
