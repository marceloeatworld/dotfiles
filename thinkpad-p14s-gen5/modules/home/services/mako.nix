# Mako notification daemon configuration
{ ... }:

{
  services.mako = {
    enable = true;

    # Ristretto theme
    backgroundColor = "#2c2525";
    textColor = "#e6d9db";
    borderColor = "#e6d9db";
    progressColor = "over #403e41";

    borderRadius = 8;
    borderSize = 2;
    width = 350;
    height = 150;
    margin = "10";
    padding = "15";

    defaultTimeout = 5000;
    ignoreTimeout = true;

    font = "JetBrainsMono Nerd Font 11";

    extraConfig = ''
      [urgency=low]
      border-color=#85dacc

      [urgency=normal]
      border-color=#e6d9db

      [urgency=high]
      border-color=#fd6883
      default-timeout=0
    '';
  };
}
