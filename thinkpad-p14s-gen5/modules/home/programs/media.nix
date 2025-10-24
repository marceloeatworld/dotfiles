# Media applications configuration
{ pkgs, lib, ... }:

let
  # PhotoGIMP - Makes GIMP look and behave like Photoshop
  photogimp = pkgs.fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    rev = "master";
    sha256 = "sha256-1n/lebA29r2l+mP2qzHZ3ZEGSJqIUbO12VQuackW6gI=";
  };
in
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
    obs-studio        # Screen recording and streaming

    # GIMP with Photoshop plugin support
    (gimp-with-plugins.override {
      plugins = with gimpPlugins; [
        gmic           # G'MIC - advanced filters and effects (Photoshop compatible)
        resynthesizer  # Resynthesizer - intelligent retouching
        gap            # GIMP Animation Package
      ];
    })

    inkscape
  ];

  # Install PhotoGIMP configuration files
  home.file = {
    # PhotoGIMP configuration for GIMP 2.10
    ".var/app/org.gimp.GIMP/config/GIMP/2.10" = lib.mkIf (builtins.pathExists "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/2.10") {
      source = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/2.10";
      recursive = true;
    };

    # Alternative path for non-Flatpak GIMP
    ".config/GIMP/2.10" = {
      source = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/2.10";
      recursive = true;
    };
  };
}
