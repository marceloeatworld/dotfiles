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
    ./programs/desktop-apps.nix  # Desktop entries (IMV, Neovim)
    ./programs/media.nix
    ./programs/development.nix
    ./programs/walker.nix
    ./programs/fastfetch.nix
    ./programs/xournalpp.nix
    ./programs/uwsm.nix
    ./programs/btop.nix          # btop system monitor with Ristretto theme
    ./programs/windows-vm.nix    # Windows 11 VM via Docker with RDP
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

    # File management
    nemo              # GUI file manager (Cinnamon File Manager)
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

    # Media
    mpv
    imv
    imagemagick       # Image manipulation CLI

    # Documents
    libreoffice-fresh
    zathura

    # Productivity
    joplin-desktop    # Note-taking (replaces Obsidian)
    gnome-calculator  # Calculator app
    xournalpp         # PDF annotation

    # Misc
    keepassxc
    jq                # JSON processor (essential for CLI work)
    bc                # Calculator (used by Bitcoin price script)
    pkgs-unstable.protonvpn-gui     # Proton VPN with GUI (unstable for latest version)

    # Windows VM dependencies
    freerdp           # RDP client for Windows VM
    gum               # CLI styling for interactive prompts
    netcat            # Network connectivity checking

    # Python package manager
    uv                # Fast Python package manager (10-100x faster than pip)

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
      "text/plain" = "xed.desktop";
      "text/x-log" = "xed.desktop";
      "text/x-readme" = "xed.desktop";
      "text/markdown" = "xed.desktop";
      "text/x-csrc" = "xed.desktop";
      "text/x-chdr" = "xed.desktop";
      "text/x-python" = "xed.desktop";
      "text/x-shellscript" = "xed.desktop";
      "application/x-shellscript" = "xed.desktop";
      "text/x-makefile" = "xed.desktop";
      "text/x-cmake" = "xed.desktop";
      "application/json" = "xed.desktop";
      "application/xml" = "xed.desktop";
      "text/xml" = "xed.desktop";

      # File manager
      "inode/directory" = "nemo.desktop";

      # Web browser
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";

      # PDF viewer
      "application/pdf" = "zathura.desktop";

      # Images (imv)
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/jpg" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";

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
