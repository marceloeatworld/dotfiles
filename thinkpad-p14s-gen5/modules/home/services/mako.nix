# Mako notification daemon configuration
{ ... }:

{
  services.mako = {
    enable = true;

    # Catppuccin Mocha theme
    backgroundColor = "#1e1e2e";
    textColor = "#cdd6f4";
    borderColor = "#cba6f7";
    progressColor = "over #313244";

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
      border-color=#89b4fa

      [urgency=normal]
      border-color=#cba6f7

      [urgency=high]
      border-color=#f38ba8
      default-timeout=0
    '';
  };
}
