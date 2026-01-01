# SwayOSD - On-screen display for volume/brightness
{ pkgs, ... }:

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
    @define-color background-color #2c2421;
    @define-color border-color #c3b7b8;
    @define-color label #c3b7b8;
    @define-color image #c3b7b8;
    @define-color progress #c3b7b8;

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
      background: #403e41;
    }

    progress {
      min-height: 10px;
      border-radius: 5px;
      background: @progress;
    }

    label {
      font-family: "JetBrainsMono Nerd Font";
      font-size: 16px;
      color: @label;
      margin: 5px;
    }

    image {
      color: @image;
    }
  '';
}
