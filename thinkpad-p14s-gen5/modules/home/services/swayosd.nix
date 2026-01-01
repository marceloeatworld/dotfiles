# SwayOSD - On-screen display for volume/brightness
{ config, ... }:

let
  theme = config.theme;
in
{
  # SwayOSD is already in home.packages (from home.nix)
  # This module just adds configuration

  # SwayOSD configuration
  xdg.configFile."swayosd/config.toml".text = ''
    [server]
    show_percentage = true
    max_volume = 100
  '';

  # SwayOSD style (Ristretto theme)
  xdg.configFile."swayosd/style.css".text = ''
    @define-color background-color ${theme.colors.background};
    @define-color border-color ${theme.colors.foregroundDim};
    @define-color label ${theme.colors.foregroundDim};
    @define-color image ${theme.colors.foregroundDim};
    @define-color progress ${theme.colors.foregroundDim};

    window {
      background: alpha(@background-color, 0.95);
      border-radius: 12px;
      border: 2px solid @border-color;
      padding: 20px;
    }

    #container {
      margin: 10px;
    }

    progressbar {
      min-height: 10px;
      border-radius: 5px;
      background: transparent;
    }

    trough {
      min-height: 10px;
      border-radius: 5px;
      background: ${theme.colors.surface};
    }

    progress {
      min-height: 10px;
      border-radius: 5px;
      background: @progress;
    }

    label {
      font-family: "${theme.fonts.mono}";
      font-size: 16px;
      color: @label;
      margin: 5px;
    }

    image {
      color: @image;
    }
  '';
}
