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
    ./programs/browsers.nix
    ./programs/brave-flags.nix  # Brave Wayland flags
    ./programs/webapps.nix       # Web apps (WhatsApp, Spotify, etc.)
    ./programs/media.nix
    ./programs/development.nix
    ./programs/walker.nix
    ./programs/fastfetch.nix
    ./programs/xournalpp.nix
    ./programs/uwsm.nix
    ./services/waybar.nix
    ./services/mako.nix
    ./services/swaylock.nix
    ./services/swayosd.nix
    ./config/gtk.nix
    ./config/qt.nix
    ./config/fontconfig.nix
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
    neofetch
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
    protonvpn-gui     # Proton VPN with GUI

    # Wayland specific
    wl-clipboard
    wl-clipboard-x11
    grim
    slurp
    wf-recorder
    hyprpicker
    swayosd           # Beautiful OSD for volume/brightness
    hyprsunset        # Blue light filter
    satty             # Screenshot annotation
    xdg-desktop-portal-hyprland  # Desktop integration
    xdg-desktop-portal-gtk       # GTK portal
    blueman           # Bluetooth manager GUI

    # Fonts (better coverage)
    noto-fonts
    noto-fonts-emoji
    font-awesome
    jetbrains-mono  # Development font (Nerd Font variant)
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

  # XDG MIME types (Omarchy-style comprehensive associations)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
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
    };
  };
}
