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
    ./programs/media.nix
    ./programs/development.nix
    ./programs/wofi.nix
    ./services/waybar.nix
    ./services/mako.nix
    ./services/swaylock.nix
    ./config/gtk.nix
    ./config/qt.nix
  ];

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "brave";
    TERMINAL = "kitty";
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

    # Productivity (Omarchy additions)
    obsidian          # Note-taking (Markdown-based)
    signal-desktop    # Encrypted messaging
    gnome-calculator  # Calculator app
    xournalpp         # PDF annotation

    # Misc
    keepassxc
    jq                # JSON processor (essential for CLI work)

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

    # Fonts (better coverage)
    noto-fonts
    noto-fonts-emoji
    font-awesome
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
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
      "application/pdf" = "zathura.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
    };
  };
}
