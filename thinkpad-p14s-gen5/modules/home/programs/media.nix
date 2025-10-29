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

  # GIMP configuration - Photoshop-style keyboard shortcuts
  home.file.".config/GIMP/2.10/menurc".text = ''
    ; GIMP menurc - Photoshop-style keyboard shortcuts
    ; This file maps GIMP actions to Photoshop-compatible shortcuts

    ; ===== BASIC EDIT OPERATIONS =====
    (gtk_accel_path "<Actions>/edit/edit-copy" "<Primary>c")
    (gtk_accel_path "<Actions>/edit/edit-paste" "<Primary>v")
    (gtk_accel_path "<Actions>/edit/edit-cut" "<Primary>x")
    (gtk_accel_path "<Actions>/edit/edit-undo" "<Primary>z")
    (gtk_accel_path "<Actions>/edit/edit-redo" "<Primary>y")
    (gtk_accel_path "<Actions>/edit/edit-clear" "Delete")

    ; ===== FILE OPERATIONS =====
    (gtk_accel_path "<Actions>/file/file-new" "<Primary>n")
    (gtk_accel_path "<Actions>/file/file-open" "<Primary>o")
    (gtk_accel_path "<Actions>/file/file-save" "<Primary>s")
    (gtk_accel_path "<Actions>/file/file-save-as" "<Primary><Shift>s")
    (gtk_accel_path "<Actions>/file/file-export-as" "<Primary><Shift><Alt>s")
    (gtk_accel_path "<Actions>/file/file-close-all" "<Primary><Shift>w")
    (gtk_accel_path "<Actions>/file/file-quit" "<Primary>q")
    (gtk_accel_path "<Actions>/plug-in/file-print-gtk" "<Primary>p")

    ; ===== TRANSFORM & RESIZE =====
    (gtk_accel_path "<Actions>/tools/tools-transform" "<Primary>t")
    (gtk_accel_path "<Actions>/tools/tools-scale" "<Primary>t")
    (gtk_accel_path "<Actions>/image/image-scale" "<Primary><Alt>i")
    (gtk_accel_path "<Actions>/image/image-canvas-size" "<Primary><Alt>c")
    (gtk_accel_path "<Actions>/image/image-crop-to-selection" "<Primary><Shift>x")
    (gtk_accel_path "<Actions>/tools/tools-rotate" "<Primary><Shift>r")
    (gtk_accel_path "<Actions>/tools/tools-flip" "<Primary><Shift>f")

    ; ===== LAYERS =====
    (gtk_accel_path "<Actions>/layers/layers-new" "<Primary><Shift>n")
    (gtk_accel_path "<Actions>/layers/layers-duplicate" "<Primary>j")
    (gtk_accel_path "<Actions>/layers/layers-merge-down" "<Primary>e")
    (gtk_accel_path "<Actions>/layers/layers-flatten-image" "<Primary><Shift>e")
    (gtk_accel_path "<Actions>/layers/layers-anchor" "<Primary>h")
    (gtk_accel_path "<Actions>/layers/layers-delete" "<Primary><Shift>Delete")
    (gtk_accel_path "<Actions>/layers/layers-raise" "<Primary>bracketright")
    (gtk_accel_path "<Actions>/layers/layers-lower" "<Primary>bracketleft")
    (gtk_accel_path "<Actions>/layers/layers-raise-to-top" "<Primary><Shift>bracketright")
    (gtk_accel_path "<Actions>/layers/layers-lower-to-bottom" "<Primary><Shift>bracketleft")

    ; ===== SELECTION =====
    (gtk_accel_path "<Actions>/select/select-all" "<Primary>a")
    (gtk_accel_path "<Actions>/select/select-none" "<Primary>d")
    (gtk_accel_path "<Actions>/select/select-invert" "<Primary><Shift>i")
    (gtk_accel_path "<Actions>/select/select-float" "<Primary><Shift>j")
    (gtk_accel_path "<Actions>/select/select-feather" "<Primary><Alt>d")
    (gtk_accel_path "<Actions>/select/select-grow" "<Primary><Shift>plus")
    (gtk_accel_path "<Actions>/select/select-shrink" "<Primary><Shift>minus")

    ; ===== COLOR ADJUSTMENTS =====
    (gtk_accel_path "<Actions>/colors/colors-levels" "<Primary>l")
    (gtk_accel_path "<Actions>/colors/colors-curves" "<Primary>m")
    (gtk_accel_path "<Actions>/colors/colors-hue-saturation" "<Primary>u")
    (gtk_accel_path "<Actions>/colors/colors-color-balance" "<Primary>b")
    (gtk_accel_path "<Actions>/colors/colors-desaturate" "<Primary><Shift>u")
    (gtk_accel_path "<Actions>/colors/colors-invert" "<Primary>i")
    (gtk_accel_path "<Actions>/colors/colors-auto-white-balance" "<Primary><Shift>b")
    (gtk_accel_path "<Actions>/colors/colors-brightness-contrast" "<Primary><Shift>c")

    ; ===== FILL & PAINT =====
    (gtk_accel_path "<Actions>/edit/edit-fill-fg" "<Alt>BackSpace")
    (gtk_accel_path "<Actions>/edit/edit-fill-bg" "<Primary>BackSpace")
    (gtk_accel_path "<Actions>/edit/edit-stroke-selection" "<Primary><Shift>BackSpace")

    ; ===== VIEW & ZOOM =====
    (gtk_accel_path "<Actions>/view/view-zoom-fit-in" "<Primary>0")
    (gtk_accel_path "<Actions>/view/view-zoom-1-1" "<Primary>1")
    (gtk_accel_path "<Actions>/view/view-zoom-in" "<Primary>plus")
    (gtk_accel_path "<Actions>/view/view-zoom-out" "<Primary>minus")
    (gtk_accel_path "<Actions>/view/view-fullscreen" "F11")
    (gtk_accel_path "<Actions>/view/view-show-guides" "<Primary>semicolon")
    (gtk_accel_path "<Actions>/view/view-show-grid" "<Primary>apostrophe")
    (gtk_accel_path "<Actions>/view/view-snap-to-guides" "<Primary><Shift>semicolon")

    ; ===== TOOLS =====
    (gtk_accel_path "<Actions>/tools/tools-rect-select" "m")
    (gtk_accel_path "<Actions>/tools/tools-ellipse-select" "<Shift>m")
    (gtk_accel_path "<Actions>/tools/tools-free-select" "l")
    (gtk_accel_path "<Actions>/tools/tools-fuzzy-select" "w")
    (gtk_accel_path "<Actions>/tools/tools-by-color-select" "<Shift>w")
    (gtk_accel_path "<Actions>/tools/tools-move" "v")
    (gtk_accel_path "<Actions>/tools/tools-crop" "c")
    (gtk_accel_path "<Actions>/tools/tools-rotate" "r")
    (gtk_accel_path "<Actions>/tools/tools-scale" "s")
    (gtk_accel_path "<Actions>/tools/tools-paintbrush" "b")
    (gtk_accel_path "<Actions>/tools/tools-pencil" "<Shift>b")
    (gtk_accel_path "<Actions>/tools/tools-eraser" "e")
    (gtk_accel_path "<Actions>/tools/tools-clone" "s")
    (gtk_accel_path "<Actions>/tools/tools-heal" "j")
    (gtk_accel_path "<Actions>/tools/tools-text" "t")
    (gtk_accel_path "<Actions>/tools/tools-bucket-fill" "g")
    (gtk_accel_path "<Actions>/tools/tools-blend" "<Shift>g")
    (gtk_accel_path "<Actions>/tools/tools-zoom" "z")
    (gtk_accel_path "<Actions>/tools/tools-color-picker" "i")

    ; ===== FILTERS =====
    (gtk_accel_path "<Actions>/filters/filters-repeat" "<Primary>f")
    (gtk_accel_path "<Actions>/filters/filters-re-show" "<Primary><Shift>f")
    (gtk_accel_path "<Actions>/plug-in/plug-in-gauss" "<Primary><Shift><Alt>g")

    ; ===== MISC =====
    (gtk_accel_path "<Actions>/dialogs/dialogs-preferences" "<Primary>k")
    (gtk_accel_path "<Actions>/windows/windows-show-display-next" "Tab")
    (gtk_accel_path "<Actions>/image/image-duplicate" "<Primary><Shift>d")
  '';

  # Additional media packages
  home.packages = with pkgs; [
    spotify
    vlc
    obs-studio   # Screen recording and streaming
    gimp         # Image editor with Photoshop-style shortcuts
    inkscape     # Vector graphics
  ];
}
