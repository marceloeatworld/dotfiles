# Mako notification daemon configuration
{ config, ... }:

let
  theme = config.theme;
in
{
  services.mako = {
    enable = true;

    # Use settings instead of deprecated extraConfig (NixOS 25.05)
    settings = {
      # Ristretto theme - Global settings
      background-color = theme.colors.background;
      text-color = theme.colors.foreground;
      border-color = theme.colors.foreground;
      progress-color = "over ${theme.colors.surface}";

      border-radius = 8;
      border-size = 2;
      width = 400;
      height = 200;
      max-visible = 5;
      margin = "10";
      padding = "15";

      default-timeout = 5000;
      ignore-timeout = true;

      font = "${theme.fonts.mono} ${toString theme.fonts.monoSize}";

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
        border-color = theme.colors.cyan;
        default-timeout = 3000;
      };

      "urgency=normal" = {
        border-color = theme.colors.foreground;
      };

      "urgency=high" = {
        border-color = theme.colors.red;
        default-timeout = 0;
      };

      # App-specific overrides
      "app-name=Spotify" = {
        border-color = theme.colors.green;
        default-timeout = 3000;
      };

      "app-name=Discord" = {
        border-color = theme.colors.green;
      };

      "app-name=Brave" = {
        border-color = theme.colors.orange;
      };

      # Volume/brightness notifications (from SwayOSD) - shorter timeout
      "app-name=SwayOSD" = {
        default-timeout = 1500;
        group-by = "app-name";
      };

      # Screenshot notifications
      "summary~=Screenshot" = {
        border-color = theme.colors.yellow;
        default-timeout = 4000;
      };
    };
  };
}
