# Browser configuration
{ pkgs, ... }:

{
  # Brave - Main browser with custom flags
  home.packages = with pkgs; [
    (brave.override {
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--ozone-platform-hint=wayland"
        "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,WaylandWindowDecorations"
        "--disable-features=WaylandWpColorManagerV1,AsyncDns"
        "--dns-over-https-mode=off"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-smooth-scrolling"
      ];
    })
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
