# UWSM - Universal Wayland Session Manager configuration
{ config, ... }:

{
  # UWSM environment configuration
  home.sessionVariables = {
    # Default applications (already set in home.nix, but repeated here for UWSM)
    TERMINAL = "${config.home.sessionVariables.TERMINAL}";
    EDITOR = "${config.home.sessionVariables.EDITOR}";
    VISUAL = "${config.home.sessionVariables.VISUAL}";
    BROWSER = "${config.home.sessionVariables.BROWSER}";

    # Screenshot and recording directories
    SCREENSHOT_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
    SCREENRECORD_DIR = "${config.home.homeDirectory}/Videos/Recordings";
  };

  # Create screenshot and recording directories
  home.file."Pictures/Screenshots/.keep".text = "";
  home.file."Videos/Recordings/.keep".text = "";
}
