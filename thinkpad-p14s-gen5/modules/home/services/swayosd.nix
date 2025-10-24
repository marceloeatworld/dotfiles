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

  # SwayOSD style (Catppuccin Mocha theme)
  xdg.configFile."swayosd/style.css".text = ''
    window {
      background: alpha(#1E1E2E, 0.95);
      border-radius: 12px;
      border: 2px solid #CBA6F7;
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
      background: #313244;
    }

    progress {
      min-height: 10px;
      border-radius: 5px;
      background: linear-gradient(to right, #89B4FA, #CBA6F7);
    }

    label {
      font-family: "JetBrainsMono Nerd Font";
      font-size: 16px;
      color: #CDD6F4;
      margin: 5px;
    }
  '';
}
