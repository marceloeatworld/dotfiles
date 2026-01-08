{ pkgs, config, ... }:

let
  theme = config.theme;
in
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

    # Additional tools for context menu actions
    p7zip                   # 7z archive support
    unrar                   # RAR extraction
    zip                     # ZIP creation
    unzip                   # ZIP extraction
  ];

  # Nemo configuration
  dconf.settings = {
    # Nemo preferences
    "org/nemo/preferences" = {
      # Default folder view - list view is cleaner/neobrutalist
      default-folder-viewer = "list-view";

      # Show hidden files - off by default
      show-hidden-files = false;

      # Thumbnail settings
      thumbnail-limit = 104857600;  # 100MB
      show-directory-item-counts = "local-only";

      # Behavior
      click-policy = "double";
      executable-text-activation = "display";  # Open text files directly
      enable-delete = true;
      confirm-trash = false;
      confirm-move-to-trash = false;  # No confirmation for trash

      # Preview
      show-image-thumbnails = "always";
      show-full-path-titles = true;

      # Context menu
      context-menus-show-all = true;

      # Neobrutalist: compact, no decorations
      show-location-entry = true;  # Text path bar (not breadcrumbs)
      show-new-folder-icon-toolbar = true;
      show-open-in-terminal-toolbar = true;
      show-edit-icon-toolbar = false;
      show-reload-icon-toolbar = true;
      show-home-icon-toolbar = true;
      show-computer-icon-toolbar = false;
      show-search-icon-toolbar = true;
    };

    # Configure Ghostty as default terminal for Nemo "Open in Terminal"
    "org/cinnamon/desktop/default-applications/terminal" = {
      exec = "ghostty";
      exec-arg = "";
    };

    # GNOME terminal fallback (some apps check this)
    "org/gnome/desktop/applications/terminal" = {
      exec = "ghostty";
      exec-arg = "";
    };

    # Nemo window settings
    "org/nemo/window-state" = {
      sidebar-width = 180;  # Narrower sidebar - neobrutalist
      start-with-sidebar = true;
      maximized = false;
      geometry = "1200x800+100+100";  # Default window size
    };

    # Icon view settings
    "org/nemo/icon-view" = {
      default-zoom-level = "small";  # Smaller icons - more minimal
      captions = ["size" "none" "none"];  # Only show size caption
    };

    # List view settings - optimized for neobrutalist
    "org/nemo/list-view" = {
      default-zoom-level = "smaller";  # Compact rows
      default-column-order = ["name" "size" "type" "date_modified" "permissions"];
      default-visible-columns = ["name" "size" "date_modified"];  # Minimal columns
    };

    # Compact view
    "org/nemo/compact-view" = {
      default-zoom-level = "small";
    };

    # Desktop settings (disable desktop icons)
    "org/nemo/desktop" = {
      desktop-layout = "false";
      show-desktop-icons = false;
    };

    # Plugins
    "org/nemo/plugins" = {
      disabled-actions = [];  # Enable all actions
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
    Exec=ghostty --working-directory=%P
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

  # === ARCHIVE ACTIONS ===

  # Extract archive here
  home.file.".config/nemo/actions/extract-here.nemo_action".text = ''
    [Nemo Action]
    Name=Extract Here
    Comment=Extract archive in current folder
    Exec=file-roller --extract-here %F
    Icon-Name=extract-archive
    Selection=s
    Extensions=zip;tar;tar.gz;tgz;tar.bz2;tbz;tar.xz;txz;7z;rar;gz;bz2;xz;
  '';

  # Extract to subfolder
  home.file.".config/nemo/actions/extract-to-folder.nemo_action".text = ''
    [Nemo Action]
    Name=Extract to Folder
    Comment=Extract archive to a new folder
    Exec=file-roller --extract %F
    Icon-Name=extract-archive
    Selection=s
    Extensions=zip;tar;tar.gz;tgz;tar.bz2;tbz;tar.xz;txz;7z;rar;gz;bz2;xz;
  '';

  # Compress to ZIP
  home.file.".config/nemo/actions/compress-zip.nemo_action".text = ''
    [Nemo Action]
    Name=Compress to ZIP
    Comment=Create a ZIP archive
    Exec=file-roller --add %F
    Icon-Name=package-x-generic
    Selection=any
    Extensions=any;
  '';

  # === CODE/DEV ACTIONS ===

  # Open in VS Code (works for both files and folders)
  home.file.".config/nemo/actions/open-vscode.nemo_action".text = ''
    [Nemo Action]
    Name=Open in VS Code
    Comment=Open file or folder in Visual Studio Code
    Exec=code %F
    Icon-Name=visual-studio-code
    Selection=any
    Extensions=any;
  '';

  # Open current folder in VS Code (right-click on empty space)
  home.file.".config/nemo/actions/open-vscode-here.nemo_action".text = ''
    [Nemo Action]
    Name=Open Folder in VS Code
    Comment=Open current folder in Visual Studio Code
    Exec=code %P
    Icon-Name=visual-studio-code
    Selection=None
    Extensions=any;
  '';

  # === FILE OPERATIONS ===

  # Open with default app (force)
  home.file.".config/nemo/actions/open-with.nemo_action".text = ''
    [Nemo Action]
    Name=Open With...
    Comment=Choose application to open file
    Exec=xdg-open %F
    Icon-Name=system-run
    Selection=s
    Extensions=any;
  '';

  # Set as wallpaper
  home.file.".config/nemo/actions/set-wallpaper.nemo_action".text = ''
    [Nemo Action]
    Name=Set as Wallpaper
    Comment=Set image as desktop wallpaper
    Exec=sh -c 'echo "preload = %F" > ~/.config/hypr/hyprpaper.conf && echo "wallpaper = ,%F" >> ~/.config/hypr/hyprpaper.conf && killall hyprpaper; hyprpaper &'
    Icon-Name=preferences-desktop-wallpaper
    Selection=s
    Extensions=jpg;jpeg;png;webp;gif;bmp;
  '';

  # === CLIPBOARD ACTIONS ===

  # Copy filename only
  home.file.".config/nemo/actions/copy-filename.nemo_action".text = ''
    [Nemo Action]
    Name=Copy Filename
    Comment=Copy filename to clipboard
    Exec=sh -c 'basename "%F" | tr -d "\n" | wl-copy'
    Icon-Name=edit-copy
    Selection=s
    Extensions=any;
  '';

  # === GIT ACTIONS ===

  # Git status in terminal
  home.file.".config/nemo/actions/git-status.nemo_action".text = ''
    [Nemo Action]
    Name=Git Status
    Comment=Show git status in terminal
    Exec=ghostty --working-directory=%P -e sh -c 'git status; read -p "Press Enter to close..."'
    Icon-Name=git
    Selection=None
    Extensions=any;
    Conditions=exec <git>;
  '';

  # === PERMISSIONS ===

  # Make executable
  home.file.".config/nemo/actions/make-executable.nemo_action".text = ''
    [Nemo Action]
    Name=Make Executable
    Comment=Add execute permission to file
    Exec=chmod +x %F
    Icon-Name=application-x-executable
    Selection=any
    Extensions=sh;py;pl;rb;bash;
  '';

  # === MEDIA ACTIONS ===

  # Play with MPV
  home.file.".config/nemo/actions/play-mpv.nemo_action".text = ''
    [Nemo Action]
    Name=Play with MPV
    Comment=Play media file with MPV
    Exec=mpv %F
    Icon-Name=mpv
    Selection=any
    Extensions=mp4;mkv;avi;webm;mov;mp3;flac;ogg;wav;m4a;
  '';

  # === HASH/CHECKSUM ===

  # Show file hash
  home.file.".config/nemo/actions/show-hash.nemo_action".text = ''
    [Nemo Action]
    Name=Show SHA256 Hash
    Comment=Calculate and show file hash
    Exec=sh -c 'HASH=$(sha256sum "%F" | cut -d" " -f1) && notify-send "SHA256 Hash" "$HASH" && echo -n "$HASH" | wl-copy'
    Icon-Name=dialog-information
    Selection=s
    Extensions=any;
  '';

  # NOTE: MIME types are centralized in ../config/mimeapps.nix

  # === NEMO GTK CSS - Neobrutalist theme override ===
  # Matches the neobrutalist theme: sharp corners, minimal, high contrast
  home.file.".config/gtk-3.0/nemo.css".text = ''
    /* Neobrutalist Nemo - Sharp, minimal, functional */

    /* Remove all rounded corners */
    .nemo-window,
    .nemo-window .sidebar,
    .nemo-window .view,
    .nemo-window button,
    .nemo-window entry,
    .nemo-window .path-bar button {
      border-radius: 0;
    }

    /* Sidebar - clean and minimal */
    .nemo-window .sidebar {
      background-color: ${theme.colors.backgroundAlt};
      border-right: 1px solid ${theme.colors.border};
    }

    .nemo-window .sidebar row {
      padding: 4px 8px;
      border-radius: 0;
    }

    .nemo-window .sidebar row:selected {
      background-color: ${theme.colors.selection};
    }

    /* Main view */
    .nemo-window .view {
      background-color: ${theme.colors.background};
      color: ${theme.colors.foreground};
    }

    /* Selection highlight */
    .nemo-window .view:selected {
      background-color: ${theme.colors.selection};
      color: ${theme.colors.foreground};
    }

    /* Path bar - flat buttons */
    .nemo-window .path-bar button {
      background: transparent;
      border: none;
      padding: 4px 8px;
    }

    .nemo-window .path-bar button:hover {
      background-color: ${theme.colors.surface};
    }

    /* Toolbar - minimal */
    .nemo-window toolbar {
      background-color: ${theme.colors.backgroundAlt};
      border-bottom: 1px solid ${theme.colors.border};
      padding: 2px;
    }

    /* Toolbar buttons - flat */
    .nemo-window toolbar button {
      background: transparent;
      border: none;
      padding: 6px;
      border-radius: 0;
    }

    .nemo-window toolbar button:hover {
      background-color: ${theme.colors.surface};
    }

    /* Status bar - subtle */
    .nemo-window statusbar {
      background-color: ${theme.colors.backgroundAlt};
      border-top: 1px solid ${theme.colors.border};
      padding: 2px 8px;
      font-size: 0.9em;
      color: ${theme.colors.foregroundDim};
    }

    /* Scrollbars - thin and minimal */
    .nemo-window scrollbar {
      background-color: transparent;
    }

    .nemo-window scrollbar slider {
      background-color: ${theme.colors.border};
      border-radius: 0;
      min-width: 6px;
      min-height: 6px;
    }

    .nemo-window scrollbar slider:hover {
      background-color: ${theme.colors.foregroundDim};
    }
  '';
}
