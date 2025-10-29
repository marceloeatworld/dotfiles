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

  # PhotoGIMP configuration files for GIMP 3.0
  home.file.".config/GIMP/3.0" = {
    source = "${photogimp}/PhotoGIMP-linux/.config/GIMP/3.0";
    recursive = true;
  };

  # Override with complete Photoshop-style shortcuts (GIMP 3.0 format)
  home.file.".config/GIMP/3.0/shortcutsrc".text = ''
    # GIMP 3.0 shortcutsrc - Complete Photoshop-style keyboard shortcuts
    # Overrides PhotoGIMP defaults with comprehensive Photoshop mappings

    (file-version 1)

    # ===== BASIC EDIT OPERATIONS =====
    (action "edit-copy" "<Primary>c" "Copy")
    (action "edit-paste" "<Primary>v" "Paste")
    (action "edit-cut" "<Primary>x" "Cut")
    (action "edit-undo" "<Primary>z")
    (action "edit-redo" "<Primary>y")
    (action "edit-strong-redo" "<Primary><Shift>y")
    (action "edit-clear" "Delete")

    # ===== FILE OPERATIONS =====
    (action "file-new" "<Primary>n")
    (action "file-open" "<Primary>o")
    (action "file-save" "<Primary>s")
    (action "file-save-as" "<Primary><Shift>s")
    (action "file-export-as" "<Primary><Shift><Alt>s")
    (action "file-close-all" "<Primary><Shift>w")
    (action "file-quit" "<Primary>q")
    (action "view-close" "<Primary>w")

    # ===== TRANSFORM & RESIZE =====
    (action "tools-scale" "<Primary>t")
    (action "tools-unified-transform" "<Primary>t")
    (action "image-scale" "<Primary><Alt>i")
    (action "image-canvas-size" "<Primary><Alt>c")
    (action "image-crop-to-selection" "<Primary><Shift>x")
    (action "tools-rotate" "r")
    (action "tools-flip" "<Primary><Shift>f")

    # ===== LAYERS =====
    (action "layers-new" "<Primary><Shift>n")
    (action "layers-duplicate" "<Primary>j")
    (action "layers-merge-down" "<Primary>e")
    (action "layers-flatten-image" "<Primary><Shift>e")
    (action "layers-anchor" "<Primary>h")
    (action "layers-delete" "<Primary><Shift>Delete")
    (action "layers-raise" "<Primary>bracketright")
    (action "layers-lower" "<Primary>bracketleft")
    (action "layers-raise-to-top" "<Primary><Shift>bracketright")
    (action "layers-lower-to-bottom" "<Primary><Shift>bracketleft")

    # ===== SELECTION =====
    (action "select-all" "<Primary>a")
    (action "select-none" "<Primary>d")
    (action "select-invert" "<Primary><Shift>i")
    (action "select-float" "<Primary><Shift>j")
    (action "select-feather" "<Primary><Alt>d")
    (action "select-grow" "<Primary><Shift>plus")
    (action "select-shrink" "<Primary><Shift>minus")

    # ===== COLOR ADJUSTMENTS =====
    (action "filters-levels" "<Primary>l")
    (action "tools-curves" "<Primary>m")
    (action "filters-hue-saturation" "<Primary>u")
    (action "filters-color-balance" "<Primary>b")
    (action "filters-desaturate" "<Primary><Shift>u")
    (action "filters-invert-linear" "<Primary>i")
    (action "filters-brightness-contrast" "<Primary><Shift>c")

    # ===== FILL & PAINT =====
    (action "edit-fill-fg" "<Alt>BackSpace")
    (action "edit-fill-bg" "<Primary>BackSpace")
    (action "edit-stroke-selection" "<Primary><Shift>BackSpace")

    # ===== VIEW & ZOOM =====
    (action "view-zoom-fit-in" "<Primary>0")
    (action "view-zoom-1-1" "<Primary>1")
    (action "view-zoom-in" "<Primary>plus")
    (action "view-zoom-out" "<Primary>minus")
    (action "view-fullscreen" "F11")
    (action "view-show-guides" "<Primary>semicolon")
    (action "view-show-grid" "<Primary>apostrophe")
    (action "view-snap-to-guides" "<Primary><Shift>semicolon")

    # ===== TOOLS (Single Key) =====
    (action "tools-rect-select" "m")
    (action "tools-ellipse-select" "m")
    (action "tools-free-select" "l")
    (action "tools-fuzzy-select" "w")
    (action "tools-by-color-select" "<Shift>w")
    (action "tools-move" "v")
    (action "tools-crop" "c")
    (action "tools-paintbrush" "b")
    (action "tools-pencil" "<Shift>b")
    (action "tools-eraser" "e")
    (action "tools-clone" "s")
    (action "tools-heal" "j")
    (action "tools-text" "t")
    (action "tools-bucket-fill" "g")
    (action "tools-gradient" "<Shift>g")
    (action "tools-zoom" "z")
    (action "tools-color-picker" "i")

    # ===== BRUSH SIZE =====
    (action "context-brush-radius-increase" "bracketright")
    (action "context-brush-radius-decrease" "bracketleft")
    (action "context-brush-hardness-increase" "braceright")
    (action "context-brush-hardness-decrease" "braceleft")

    # ===== FILTERS =====
    (action "filters-repeat" "<Primary>f")
    (action "filters-reshow" "<Primary><Shift>f")

    # ===== MISC =====
    (action "dialogs-preferences" "<Primary>k")
    (action "image-duplicate" "<Primary><Shift>d")
    (action "dialogs-toolbox" "<Primary>b")
  '';


  home.file.".local/share/icons/hicolor" = {
    source = "${photogimp}/PhotoGIMP-linux/.local/share/icons/hicolor";
    recursive = true;
  };

  home.file.".local/share/applications/org.gimp.GIMP.desktop" = {
    source = "${photogimp}/PhotoGIMP-linux/.local/share/applications/org.gimp.GIMP.desktop";
  };

  # Additional media packages
  home.packages = with pkgs; [
    spotify
    vlc
    obs-studio      # Screen recording and streaming
    gimp3           # GIMP 3.0.4 with PhotoGIMP (Photoshop-like interface)
    inkscape        # Vector graphics
  ];
}
