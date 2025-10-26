# UWSM - Universal Wayland Session Manager configuration
{ config, ... }:

{
  # UWSM environment configuration
  home.sessionVariables = {
    # Screenshot and recording directories
    SCREENSHOT_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
    SCREENRECORD_DIR = "${config.home.homeDirectory}/Videos/Recordings";
  };

  # Create screenshot and recording directories
  home.file."Pictures/Screenshots/.keep".text = "";
  home.file."Videos/Recordings/.keep".text = "";
}
