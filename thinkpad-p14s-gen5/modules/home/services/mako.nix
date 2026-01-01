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
      width = 350;
      height = 150;
      margin = "10";
      padding = "15";

      default-timeout = 5000;
      ignore-timeout = true;

      font = "JetBrainsMono Nerd Font 11";

      # Urgency-specific settings
      "urgency=low" = {
        border-color = "#85dacc";
      };

      "urgency=normal" = {
        border-color = "#e6d9db";
      };

      "urgency=high" = {
        border-color = "#fd6883";
        default-timeout = 0;
      };
    };
  };
}
