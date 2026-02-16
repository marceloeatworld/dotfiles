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
      # Ultra-minimal old-school style
      background-color = theme.colors.background;
      text-color = theme.colors.foreground;
      border-color = theme.colors.border;
      progress-color = "over ${theme.colors.surface}";

      # Sharp corners, thin border
      border-radius = 0;
      border-size = 1;
      width = 350;
      height = 150;
      max-visible = 3;
      margin = "8";
      padding = "12";

      default-timeout = 4000;
      ignore-timeout = false;

      font = "${theme.fonts.mono} 10";

      # Minimal icons
      icons = true;
      max-icon-size = 32;
      icon-location = "left";

      actions = true;
      group-by = "app-name";
      format = "%s\\n%b";

      layer = "overlay";
      anchor = "top-right";

      # All urgencies same minimal border
      "urgency=low" = {
        default-timeout = 2000;
      };

      "urgency=high" = {
        border-color = theme.colors.foreground;
        default-timeout = 0;
      };

      # SwayOSD - quick dismiss
      "app-name=SwayOSD" = {
        default-timeout = 1000;
        group-by = "app-name";
      };
    };
  };
}
