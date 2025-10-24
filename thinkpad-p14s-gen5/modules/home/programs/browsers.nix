# Browser configuration
{ pkgs, ... }:

{
  # Brave - Main browser
  home.packages = with pkgs; [
    brave
  ];

  # Default browser configuration
  xdg.mimeApps.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };
}
