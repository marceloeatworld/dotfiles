# Mako notification daemon configuration
{ ... }:

{
  services.mako = {
    enable = true;

    # Use settings instead of deprecated extraConfig (NixOS 25.05)
    settings = {
      # Ristretto theme - Global settings
      background-color = "#2c2421";
      text-color = "#e6d9db";
      border-color = "#e6d9db";
      progress-color = "over #403e41";

      border-radius = 8;
      border-size = 2;
      width = 400;
      height = 200;
      max-visible = 5;
      margin = "10";
      padding = "15";

      default-timeout = 5000;
      ignore-timeout = true;

      font = "JetBrainsMono Nerd Font 11";

      # Icons
      icons = true;
      max-icon-size = 64;
      icon-location = "left";

      # Actions (buttons in notifications)
      actions = true;

      # Grouping similar notifications
      group-by = "app-name";

      # Format with app name and body
      format = "<b>%s</b>\\n%b";

      # Layer and anchor position
      layer = "overlay";
      anchor = "top-right";

      # Urgency-specific settings
      "urgency=low" = {
        border-color = "#85dacc";
        default-timeout = 3000;
      };

      "urgency=normal" = {
        border-color = "#e6d9db";
      };

      "urgency=high" = {
        border-color = "#fd6883";
        default-timeout = 0;
      };

      # App-specific overrides
      "app-name=Spotify" = {
        border-color = "#adda78";
        default-timeout = 3000;
      };

      "app-name=Discord" = {
        border-color = "#a9dc76";
      };

      "app-name=Brave" = {
        border-color = "#fc9867";
      };

      # Volume/brightness notifications (from SwayOSD) - shorter timeout
      "app-name=SwayOSD" = {
        default-timeout = 1500;
        group-by = "app-name";
      };

      # Screenshot notifications
      "summary~=Screenshot" = {
        border-color = "#f9cc6c";
        default-timeout = 4000;
      };
    };
  };
}
