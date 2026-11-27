# UWSM - Universal Wayland Session Manager configuration
{ config, ... }:

{
  # UWSM environment configuration
  home.sessionVariables = {
    # Screenshot and recording directories
    SCREENSHOT_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
    SCREENRECORD_DIR = "${config.home.homeDirectory}/Videos/Recordings";
  };

  # UWSM does not automatically source Home Manager's shell/session variables.
  # Export them into the managed Wayland session so Hyprland exec binds and
  # user services see the same environment as interactive shells.
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  # Create screenshot and recording directories
  home.file."Pictures/Screenshots/.keep".text = "";
  home.file."Videos/Recordings/.keep".text = "";
}
