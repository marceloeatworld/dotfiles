{ pkgs, config, ... }:

{
  # Nemo file manager with full integration
  home.packages = with pkgs; [
    nemo-with-extensions    # Nemo with all extensions included
    nemo-fileroller         # Archive support (create/extract zip, tar, etc.)
    file-roller             # GNOME archive manager (backend for nemo-fileroller)
    glib                    # Required for gsettings command

    # Thumbnail generation packages
    gnome-desktop           # Thumbnail factory (includes gdk-pixbuf)
    librsvg                 # SVG thumbnails (includes gdk-pixbuf)
    webp-pixbuf-loader      # WebP thumbnails
    ffmpegthumbnailer       # Video thumbnails
    poppler-utils           # PDF thumbnails
  ];

  # Nemo configuration
  dconf.settings = {
    # Nemo preferences
    "org/nemo/preferences" = {
      # Default folder view
      default-folder-viewer = "list-view";

      # Show hidden files
      show-hidden-files = false;

      # Thumbnail settings - INCREASED for better preview support
      thumbnail-limit = 104857600;  # 100MB (was 10MB)
      show-directory-item-counts = "local-only";

      # Behavior
      click-policy = "double";
      executable-text-activation = "display";  # FIXED: Open text files directly, no dialog
      enable-delete = true;
      confirm-trash = false;

      # Preview
      show-image-thumbnails = "always";
      show-full-path-titles = true;

      # Context menu
      context-menus-show-all = true;
    };

    # Configure Ghostty as default terminal for Nemo "Open in Terminal"
    "org/cinnamon/desktop/default-applications/terminal" = {
      exec = "ghostty";
      exec-arg = "";
    };

    # Nemo window settings
    "org/nemo/window-state" = {
      sidebar-width = 200;
      start-with-sidebar = true;
      maximized = false;
    };

    # Icon view settings
    "org/nemo/icon-view" = {
      default-zoom-level = "standard";
    };

    # List view settings
    "org/nemo/list-view" = {
      default-zoom-level = "standard";
      default-column-order = ["name" "size" "type" "date_modified"];
      default-visible-columns = ["name" "size" "type" "date_modified"];
    };

    # Desktop settings (disable desktop icons)
    "org/nemo/desktop" = {
      desktop-layout = "false";
      show-desktop-icons = false;
    };
  };

  # Configure Nemo to use Ghostty as terminal
  # This action appears when right-clicking in empty space OR on folders
  home.file.".config/nemo/actions/open-terminal.nemo_action".text = ''
    [Nemo Action]
    Name=Open Terminal Here
    Comment=Open Ghostty terminal in this folder
    Exec=ghostty --working-directory=%F
    Icon-Name=utilities-terminal
    Selection=any
    Extensions=dir;
    Quote=double
    EscapeSpaces=true
  '';

  # Second action for background (empty space) right-click
  home.file.".config/nemo/actions/open-terminal-background.nemo_action".text = ''
    [Nemo Action]
    Name=Open Terminal Here
    Comment=Open Ghostty terminal in current folder
    Exec=ghostty
    Icon-Name=utilities-terminal
    Selection=None
    Extensions=any;
  '';

  # Open files with xed editor
  home.file.".config/nemo/actions/edit-with-xed.nemo_action".text = ''
    [Nemo Action]
    Name=Edit with Xed
    Comment=Open file with Xed text editor
    Exec=xed %F
    Icon-Name=accessories-text-editor
    Selection=any
    Extensions=txt;md;conf;log;sh;py;js;json;xml;html;css;nix;
  '';

  # Open files with Neovim in Ghostty
  home.file.".config/nemo/actions/edit-with-nvim.nemo_action".text = ''
    [Nemo Action]
    Name=Edit with Neovim
    Comment=Open file with Neovim in terminal
    Exec=ghostty nvim %F
    Icon-Name=nvim
    Selection=any
    Extensions=txt;md;conf;log;sh;py;js;json;xml;html;css;nix;
  '';

  # Copy file path to clipboard
  home.file.".config/nemo/actions/copy-path.nemo_action".text = ''
    [Nemo Action]
    Name=Copy File Path
    Comment=Copy full path to clipboard
    Exec=echo -n %F | wl-copy
    Icon-Name=edit-copy
    Selection=any
    Extensions=any;
  '';

  # Open as root with Nemo
  home.file.".config/nemo/actions/open-as-root.nemo_action".text = ''
    [Nemo Action]
    Name=Open as Root
    Comment=Open folder with root privileges
    Exec=pkexec nemo %F
    Icon-Name=system-lock-screen
    Selection=any
    Extensions=dir;
  '';

  # GTK settings for Nemo
  # Note: EDITOR variable is set to "nvim" in home.nix for terminal use
  # Xed is configured as default for GUI file associations in xdg.mimeApps

  # NOTE: MIME types are centralized in ../config/mimeapps.nix
}
