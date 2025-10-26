# Media applications configuration
{ pkgs, ... }:

{
  # MPV video player
  programs.mpv = {
    enable = true;
    config = {
      profile = "gpu-hq";
      hwdec = "auto-safe";
      vo = "gpu";
      gpu-context = "wayland";
    };
  };

  # Image viewer
  programs.imv = {
    enable = true;
    settings = {
      options = {
        background = "1E1E2E";
        overlay_font = "JetBrainsMono Nerd Font:12";
      };
    };
  };

  # Additional media packages
  home.packages = with pkgs; [
    spotify
    vlc
    obs-studio   # Screen recording and streaming
    gimp         # Image editor (simplified - removed PhotoGIMP config)
    inkscape     # Vector graphics
  ];
}
