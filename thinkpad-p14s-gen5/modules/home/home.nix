# Home Manager configuration for user marcelo
{ config, pkgs, inputs, pkgs-unstable, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "marcelo";
  home.homeDirectory = "/home/marcelo";

  # This value determines the Home Manager release compatibility
  home.stateVersion = "25.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Import module configurations
  imports = [
    ./programs/hyprland.nix
    ./programs/terminal.nix
    ./programs/shell.nix
    ./programs/git.nix
    ./programs/nvim.nix
    ./programs/browsers.nix  # Brave with Wayland flags
    ./programs/webapps.nix   # Web apps (WhatsApp, Spotify, etc.)
    ./programs/desktop-apps.nix  # Desktop entries (Neovim)
    ./programs/media.nix
    ./programs/development.nix
    ./programs/yt-dlp.nix
    ./programs/walker.nix
    ./programs/fastfetch.nix
    ./programs/xournalpp.nix
    ./programs/uwsm.nix
    ./programs/btop.nix          # btop system monitor with Ristretto theme
    ./programs/windows-vm.nix    # Windows 11 VM via Docker with RDP
    ./programs/security-tools.nix  # Security audit tools (sqlmap, nikto, etc.)
    ./programs/nemo.nix          # Nemo file manager with full integration
    ./programs/teamspeak.nix     # TeamSpeak 6 Beta 3.2
    ./programs/protonvpn.nix     # ProtonVPN GUI with bcrypt test fix
    ./services/waybar.nix
    ./services/mako.nix
    ./services/swaylock.nix
    ./services/swayosd.nix
    ./config/gtk.nix
    ./config/qt.nix
    ./config/fontconfig.nix
    ./config/webapp-icons.nix    # Custom icons for web apps
    ./config/hyprpaper.nix       # Wallpaper configuration
  ];

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "brave";
    TERMINAL = "kitty";

    # Wayland backend preferences
    SAL_USE_VCLPLUGIN = "gtk3";  # LibreOffice native Wayland via GTK3

    # AMD GPU ROCm/hashcat support (RDNA 3 iGPU)
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # Required for Radeon 780M GPU acceleration
  };

  # Gnome Keyring integration
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # Basic user packages
  home.packages = with pkgs; [
    # System utilities
    htop
    btop
    fastfetch
    tree
    ripgrep
    fd
    eza
    bat
    fzf
    zoxide
    direnv
    dust              # Better du (disk usage visualizer)
    tldr              # Simplified man pages

    # File management (Nemo and related packages moved to programs/nemo.nix)
    xed-editor        # Simple text editor from Linux Mint (pairs well with Nemo)
    yazi
    nnn
    ranger
    gvfs              # Virtual file systems (Android MTP, network shares)

    # Archives
    unzip
    zip
    p7zip
    unrar

    # Network tools
    wget
    curl
    speedtest-cli
    avahi             # Local network discovery (mDNS)
    transmission_4-gtk  # Torrent client (GTK interface)

    # Media
    mpv
    # swayimg moved to media.nix

    # Documents
    libreoffice-fresh
    zathura

    # Productivity
    joplin-desktop    # Note-taking (replaces Obsidian)
    gnome-calculator  # Calculator app
    xournalpp         # PDF annotation

    # 3D Graphics
    blender           # 3D Creation/Animation/Publishing System (unstable: 4.4.3)

    # Misc
    keepassxc
    jq                # JSON processor (essential for CLI work)
    bc                # Calculator (used by Bitcoin price script)
    # Proton VPN - override moved to programs/protonvpn.nix to fix bcrypt test failures

    # Windows VM dependencies
    freerdp           # RDP client for Windows VM
    gum               # CLI styling for interactive prompts
    netcat            # Network connectivity checking

    # Python package manager
    uv                # Fast Python package manager (10-100x faster than pip)

    # API testing
    bruno             # Open source API client (Postman alternative, no login required)

    # Wayland specific
    wl-clipboard
    wl-clipboard-x11
    grim
    slurp
    wf-recorder
    hyprpicker
    swayosd           # Beautiful OSD for volume/brightness
    # hyprsunset - REMOVED: installed via hyprland.nix with pkgs-unstable (v0.3.3)
    satty             # Screenshot annotation
    # xdg-desktop-portal-hyprland - REMOVED: already configured in system/hyprland.nix
    # xdg-desktop-portal-gtk - REMOVED: already configured in system/hyprland.nix
    blueman           # Bluetooth manager GUI

    # NOTE: Fonts are installed system-wide in modules/system/fonts.nix
    # This is REQUIRED for Hyprland/Waybar and other Wayland apps
    # Do NOT install fonts in home.packages - use fonts.packages instead
  ];

  # VS Code Wayland flags (for vscode.fhs)
  home.file.".config/code-flags.conf".text = ''
    --enable-features=UseOzonePlatform,WaylandWindowDecorations
    --ozone-platform=wayland
  '';

  # XDG user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
    templates = "${config.home.homeDirectory}/Templates";
    publicShare = "${config.home.homeDirectory}/Public";
  };

  # XDG MIME types
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Text files (xed editor)
      "text/plain" = "org.x.editor.desktop";
      "text/x-log" = "org.x.editor.desktop";
      "text/x-readme" = "org.x.editor.desktop";
      "text/markdown" = "org.x.editor.desktop";
      "text/x-csrc" = "org.x.editor.desktop";
      "text/x-chdr" = "org.x.editor.desktop";
      "text/x-python" = "org.x.editor.desktop";
      "text/x-shellscript" = "org.x.editor.desktop";
      "application/x-shellscript" = "org.x.editor.desktop";
      "text/x-makefile" = "org.x.editor.desktop";
      "text/x-cmake" = "org.x.editor.desktop";
      "application/json" = "org.x.editor.desktop";
      "application/xml" = "org.x.editor.desktop";
      "text/xml" = "org.x.editor.desktop";

      # File manager
      "inode/directory" = "nemo.desktop";

      # Web browser
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";

      # PDF viewer
      "application/pdf" = "org.pwmt.zathura.desktop";

      # Images (swayimg) - All formats including WebP, AVIF, JXL
      "image/png" = "swayimg.desktop";
      "image/jpeg" = "swayimg.desktop";
      "image/jpg" = "swayimg.desktop";
      "image/gif" = "swayimg.desktop";
      "image/webp" = "swayimg.desktop";
      "image/bmp" = "swayimg.desktop";
      "image/x-bmp" = "swayimg.desktop";
      "image/tiff" = "swayimg.desktop";
      "image/svg+xml" = "swayimg.desktop";
      "image/avif" = "swayimg.desktop";
      "image/jxl" = "swayimg.desktop";
      "image/heif" = "swayimg.desktop";
      "image/heic" = "swayimg.desktop";
      "image/x-xcf" = "swayimg.desktop";
      "image/x-portable-pixmap" = "swayimg.desktop";
      "image/x-portable-graymap" = "swayimg.desktop";
      "image/x-portable-bitmap" = "swayimg.desktop";
      "image/x-portable-anymap" = "swayimg.desktop";
      "image/x-xbitmap" = "swayimg.desktop";
      "image/x-tga" = "swayimg.desktop";
      "image/vnd.microsoft.icon" = "swayimg.desktop";
      "image/x-icon" = "swayimg.desktop";

      # Videos (mpv)
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "video/x-ms-wmv" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/3gpp" = "mpv.desktop";
      "video/3gpp2" = "mpv.desktop";

      # Web app protocol handlers
      "x-scheme-handler/whatsapp" = "whatsapp-web.desktop";
      "x-scheme-handler/spotify" = "spotify-web.desktop";
      "x-scheme-handler/discord" = "discord-web.desktop";
      "x-scheme-handler/mailto" = "protonmail-web.desktop";
    };
  };
}
