# Media applications configuration
{ config, pkgs, pkgs-unstable, ... }:

let
  theme = config.theme;

  # PhotoGIMP - Makes GIMP look like Photoshop (GIMP 3.0)
  photogimp = pkgs.fetchzip {
    url = "https://github.com/Diolinux/PhotoGIMP/releases/download/3.0/PhotoGIMP-linux.zip";
    sha256 = "sha256-vBEMR83ZMV/o8wPR9mm2eZt44CulHxdUuK4Y7O/xwzs=";
    stripRoot = false;
  };

  # OpenShot AppImage from GitHub releases
  openshot-appimage = pkgs.appimageTools.wrapType2 {
    pname = "openshot-qt";
    version = "3.4.0";
    src = pkgs.fetchurl {
      url = "https://github.com/OpenShot/openshot-qt/releases/download/v3.4.0/OpenShot-v3.4.0-x86_64.AppImage";
      sha256 = "sha256-Lvi8dzsq2KaBHP39bXGH3H6VooSp85Az6sZnXPeO7yw=";
    };
    extraPkgs = pkgs: with pkgs; [
      python3
      ffmpeg
      libGL
      libGLU
      xorg.libX11
      xorg.libXrender
      xorg.libXext
      qt5.qtbase
      qt5.qtsvg
      qt5.qtmultimedia
    ];
  };

  # MPV wrapper to ensure correct binary path for desktop files
  mpv-wrapped = pkgs.mpv;
in
{
  # OpenShot desktop entry
  xdg.desktopEntries.openshot-qt = {
    name = "OpenShot Video Editor";
    genericName = "Video Editor";
    comment = "Create and edit videos and movies";
    exec = "${openshot-appimage}/bin/openshot-qt %F";
    icon = "openshot-qt";
    terminal = false;
    type = "Application";
    categories = [ "AudioVideo" "Video" "AudioVideoEditing" ];
    mimeType = [
      "application/vnd.openshot-qt-project"
      "video/mp4" "video/x-matroska" "video/webm" "video/avi"
      "video/quicktime" "video/mpeg" "video/ogg"
    ];
  };

  # Custom mpv.desktop that works correctly on NixOS
  # The default mpv.desktop uses TryExec=mpv which may fail
  xdg.desktopEntries.mpv = {
    name = "mpv Media Player";
    genericName = "Multimedia player";
    comment = "Play movies and songs";
    exec = "${mpv-wrapped}/bin/mpv --player-operation-mode=pseudo-gui -- %U";
    icon = "mpv";
    terminal = false;
    type = "Application";
    categories = [ "AudioVideo" "Audio" "Video" "Player" "TV" ];
    mimeType = [
      "video/mp4" "video/x-matroska" "video/webm" "video/avi" "video/x-msvideo"
      "video/quicktime" "video/mpeg" "video/x-flv" "video/x-ms-wmv" "video/ogg"
      "video/3gpp" "video/3gpp2" "audio/mpeg" "audio/mp3" "audio/flac"
      "audio/ogg" "audio/wav" "audio/aac" "audio/mp4" "audio/webm"
    ];
    settings = {
      StartupWMClass = "mpv";
    };
  };
  # MPV video player - Full configuration
  programs.mpv = {
    enable = true;
    config = {
      # Video output
      profile = "gpu-hq";
      hwdec = "auto-safe";
      vo = "gpu-next";
      gpu-context = "wayland";
      gpu-api = "vulkan";

      # Quality
      scale = "ewa_lanczos";
      cscale = "ewa_lanczos";
      video-sync = "display-resample";
      interpolation = true;
      tscale = "oversample";

      # Audio
      volume = 100;
      volume-max = 150;
      audio-pitch-correction = true;

      # Subtitles
      sub-auto = "fuzzy";
      sub-font = theme.fonts.mono;
      sub-font-size = 40;
      sub-color = "#FFFFFF";
      sub-border-color = "#000000";
      sub-border-size = 2;
      sub-shadow-offset = 1;
      sub-shadow-color = "#000000";
      sub-spacing = 0.5;

      # OSD
      osd-level = 1;
      osd-duration = 2500;
      osd-font = theme.fonts.mono;
      osd-font-size = 32;
      osd-color = theme.colors.foreground;
      osd-border-color = theme.colors.background;
      osd-border-size = 2;
      osd-bar-align-y = 0.9;

      # Screenshot
      screenshot-format = "png";
      screenshot-png-compression = 8;
      screenshot-template = "~/Pictures/Screenshots/mpv-%F-%P";

      # Cache
      cache = true;
      demuxer-max-bytes = "150MiB";
      demuxer-max-back-bytes = "75MiB";

      # Misc
      keep-open = true;
      save-position-on-quit = true;
      autofit-larger = "90%x90%";
      cursor-autohide = 1000;
      force-window = "immediate";
    };

    bindings = {
      # Playback
      "SPACE" = "cycle pause";
      "m" = "cycle mute";
      "UP" = "add volume 5";
      "DOWN" = "add volume -5";
      "LEFT" = "seek -5";
      "RIGHT" = "seek 5";
      "Shift+LEFT" = "seek -60";
      "Shift+RIGHT" = "seek 60";
      "[" = "add speed -0.1";
      "]" = "add speed 0.1";
      "BS" = "set speed 1.0";

      # Subtitles
      "v" = "cycle sub-visibility";
      "j" = "cycle sub";
      "J" = "cycle sub down";

      # Screenshot
      "s" = "screenshot";
      "S" = "screenshot video";

      # Fullscreen
      "f" = "cycle fullscreen";
      "ESC" = "set fullscreen no";

      # Playlist
      ">" = "playlist-next";
      "<" = "playlist-prev";
      "l" = "ab-loop";
      "L" = "cycle-values loop-file inf no";

      # Audio
      "a" = "cycle audio";

      # Aspect ratio
      "A" = "cycle-values video-aspect-override 16:9 4:3 2.35:1 -1";

      # Rotate
      "r" = "cycle-values video-rotate 90 180 270 0";
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
  home.packages = [
    openshot-appimage # Video editor v3.4.0 (AppImage from GitHub)
  ] ++ (with pkgs; [
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
    musescore       # Music notation editor (unstable - latest version)
  ]);
}
