# Media applications configuration
{ pkgs, pkgs-unstable, ... }:

let
  # PhotoGIMP - Makes GIMP look like Photoshop (GIMP 3.0)
  photogimp = pkgs.fetchzip {
    url = "https://github.com/Diolinux/PhotoGIMP/releases/download/3.0/PhotoGIMP-linux.zip";
    sha256 = "sha256-vBEMR83ZMV/o8wPR9mm2eZt44CulHxdUuK4Y7O/xwzs=";
    stripRoot = false;
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

  # Configure swayimg (WebP-capable image viewer)
  xdg.configFile."swayimg/config".text = ''
    [general]
    position = center
    background = #1E1E2E

    [viewer]
    scale = optimal
    antialiasing = yes
    transparency = grid
  '';

  # PhotoGIMP - Copy ALL config files for complete Photoshop style
  home.file.".config/GIMP/3.0" = {
    source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0";
    recursive = true;
    force = true;  # Overwrite existing files without backing up
  };

  # Additional media packages
  home.packages = (with pkgs; [
    spotify
    vlc
    obs-studio      # Screen recording and streaming
    gimp3           # GIMP 3.0.4 with PhotoGIMP (Photoshop-like interface)
    inkscape        # Vector graphics
    swayimg         # Image viewer with WebP/AVIF/JXL support (replaces imv)
    ffmpeg-full     # Video/audio/image conversion and processing (includes WebP)
    imagemagick     # Image manipulation CLI
    exiftool        # Read/write EXIF metadata in images
    mediainfo       # Detailed video/audio file information
    v4l-utils       # Video4Linux utilities (v4l2-ctl, v4l2-compliance, etc.)
  ]) ++ (with pkgs-unstable; [
    guvcview        # GTK UVC Viewer - webcam/USB camera viewer and recorder (unstable)
    musescore       # Music notation editor (unstable - latest version)
  ]);
}
