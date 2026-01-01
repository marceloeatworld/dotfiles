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
}
