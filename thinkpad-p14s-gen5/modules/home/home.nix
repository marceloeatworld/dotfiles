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

  # Import module configurations (organized by category)
  imports = [
    # ── Desktop & Window Manager ──
    ./programs/hyprland.nix       # Hyprland config, keybindings, animations
    ./programs/hyprlauncher.nix   # Application launcher
    ./programs/uwsm.nix           # Universal Wayland Session Manager

    # ── Terminal & Shell ──
    ./programs/terminal.nix       # Ghostty + Alacritty terminals
    ./programs/shell.nix          # Zsh + Starship prompt
    ./programs/btop.nix           # System monitor (Ristretto theme)
    ./programs/fastfetch.nix      # System info display

    # ── Development ──
    ./programs/nvim.nix           # Neovim with LazyVim
    ./programs/git.nix            # Git + delta diff viewer
    ./programs/development.nix    # VS Code, languages, tools
    ./programs/claude-code.nix    # Claude Code AI assistant

    # ── Applications ──
    ./programs/browsers.nix       # Brave with Wayland flags
    ./programs/webapps.nix        # Web apps (WhatsApp, Spotify, etc.)
    ./programs/desktop-apps.nix   # Desktop entries for apps
    ./programs/media.nix          # Media players (mpv, swayimg)
    ./programs/yt-dlp.nix         # YouTube downloader
    ./programs/nemo.nix           # Nemo file manager
    ./programs/xournalpp.nix      # PDF annotation

    # ── Communication ──
    ./programs/teamspeak.nix      # TeamSpeak 6
    ./programs/protonvpn.nix      # ProtonVPN GUI

    # ── Gaming ──
    ./programs/mangohud.nix       # In-game GPU/CPU/FPS overlay

    # ── Utilities ──
    ./programs/windows-vm.nix     # Windows 11 VM (Docker + RDP)
    ./programs/security-tools.nix # Security tools aliases & docs

    # ── Services ──
    ./services/waybar.nix         # Status bar + custom scripts
    ./services/mako.nix           # Notifications
    ./services/hyprlock.nix       # Screen locker
    ./services/swayosd.nix        # Volume/brightness OSD

    # ── Configuration ──
    ./config/gtk.nix              # GTK theme (Adwaita-dark)
    ./config/qt.nix               # Qt theme
    ./config/fontconfig.nix       # Font configuration
    ./config/webapp-icons.nix     # Custom icons for web apps
    ./config/hyprpaper.nix        # Wallpaper configuration
    ./config/mimeapps.nix         # File associations (centralized)
  ];

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "brave";
    TERMINAL = "ghostty";

    # Wayland backend preferences
    SAL_USE_VCLPLUGIN = "gtk3";  # LibreOffice native Wayland via GTK3

    # AMD GPU ROCm/hashcat support (RDNA 3 iGPU)
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # Required for Radeon 780M GPU acceleration
  };

  # Basic user packages
  # NOTE: btop is in btop.nix, fastfetch is in fastfetch.nix
  home.packages = with pkgs; [
    # System utilities
    hyprsysteminfo  # Official Hyprland system info (GUI)
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

    # Wayland specific (core tools in system/hyprland.nix)
    hyprpicker        # Color picker for Hyprland
    swayosd           # Beautiful OSD for volume/brightness
    satty             # Screenshot annotation
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

  # NOTE: MIME types are centralized in ./config/mimeapps.nix
}
