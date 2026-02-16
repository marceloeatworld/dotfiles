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

  # PhotoGIMP - Only symlink static assets (themes, fonts, shortcuts, etc.)
  # GIMP needs to write to gimprc, sessionrc, pluginrc, etc. so we don't symlink those
  home.file = {
    # Keyboard shortcuts (Photoshop-style)
    ".config/GIMP/3.0/shortcutsrc".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/shortcutsrc";
    # Tool presets and options
    ".config/GIMP/3.0/toolrc".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/toolrc";
    ".config/GIMP/3.0/tool-options" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/tool-options";
      recursive = true;
    };
    # Templates
    ".config/GIMP/3.0/templaterc".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/templaterc";
    # Theme styling
    ".config/GIMP/3.0/theme.css".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/theme.css";
    # Splash screens
    ".config/GIMP/3.0/splashes" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/splashes";
      recursive = true;
    };
    # Fonts
    ".config/GIMP/3.0/fonts" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/fonts";
      recursive = true;
    };
    # Gradients
    ".config/GIMP/3.0/gradients" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/gradients";
      recursive = true;
    };
    # Filters
    ".config/GIMP/3.0/filters" = {
      source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/filters";
      recursive = true;
    };
    # Tags (brush/pattern organization)
    ".config/GIMP/3.0/tags.xml".source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0/tags.xml";
  };

  # Additional media packages
  home.packages = (with pkgs; [
    kdePackages.kdenlive  # Video editor (stable, H.265/HEVC native support)
    flowblade       # Multitrack non-linear video editor
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
  ]);
}
