# Wofi - dmenu-like picker used for clipboard history (SUPER+V) and one-off
# WiFi/password prompts. Themed to match the rest of the desktop.
{ config, pkgs, ... }:

let
  theme = config.theme;
in
{
  home.packages = [ pkgs.wofi ];

  xdg.configFile."wofi/config".text = ''
    insensitive=true
    matching=fuzzy
    no_actions=true
    term=ghostty
    width=640
    height=420
  '';

  xdg.configFile."wofi/style.css".text = ''
    @import url("${config.home.homeDirectory}/.config/theme/current/wofi.css");
  '';
}
