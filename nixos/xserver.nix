{ pkgs, ... }: 
{
  services.xserver = {
    enable = true;
    xkb.layout = "us,fr";
    displayManager.autoLogin = {
      enable = true;
      user = "marcelo";
    };
    libinput = {
      enable = true;
      # mouse = {
      #   accelProfile = "flat";
      # };
    };
  };
  # To prevent getting stuck at shutdown
  systemd.extraConfig = "DefaultTimeoutStopSec=10s";
}
