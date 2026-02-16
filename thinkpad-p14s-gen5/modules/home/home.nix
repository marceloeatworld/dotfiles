# Home Manager configuration for user marcelo
{ config, pkgs, inputs, pkgs-unstable, ... }:

let
  # Theme selector script (CLI only)
  # Writes to dotfiles repo file which Nix reads at build time
  theme-selector = pkgs.writeShellScriptBin "theme-selector" ''
    #!/usr/bin/env bash
    # Theme Selector - CLI interface
    # Usage:
    #   theme-selector <theme>    # Sets theme directly
    #   theme-selector --list     # Lists available themes
    #   theme-selector --current  # Shows current theme

    DOTFILES_DIR="$HOME/dotfiles/thinkpad-p14s-gen5"
    THEME_FILE="$DOTFILES_DIR/modules/home/config/current-theme"

    # Available themes with descriptions
    declare -A THEMES=(
      ["ristretto"]="Ristretto|Warm coffee-inspired (Monokai Pro)"
      ["neobrutalist"]="Neobrutalist|Minimal high-contrast bold"
      ["nord"]="Nord|Arctic north-bluish palette"
      ["tokyonight"]="Tokyo Night|Tokyo city lights inspired"
      ["catppuccin"]="Catppuccin|Soothing pastel warm theme"
    )

    # Get current theme from file
    get_current() {
      if [ -f "$THEME_FILE" ]; then
        cat "$THEME_FILE" | tr -d '[:space:]'
      else
        echo "ristretto"
      fi
    }

    # List themes
    list_themes() {
      echo "Available themes:"
      current=$(get_current)
      for key in ristretto neobrutalist nord tokyonight catppuccin; do
        IFS='|' read -r name desc <<< "''${THEMES[$key]}"
        marker=""
        [ "$key" = "$current" ] && marker=" (current)"
        echo "  $key - $name$marker"
        echo "      $desc"
      done
    }

    # Set theme
    set_theme() {
      local theme="$1"
      if [ -z "''${THEMES[$theme]}" ]; then
        echo "Error: Unknown theme '$theme'"
        echo ""
        list_themes
        exit 1
      fi

      # Write theme to dotfiles (Nix reads this at build time)
      echo "$theme" > "$THEME_FILE"

      # Stage the file for git (required for flakes)
      cd "$DOTFILES_DIR" && ${pkgs.git}/bin/git add "$THEME_FILE"

      IFS='|' read -r name desc <<< "''${THEMES[$theme]}"
      echo "Theme set to: $name ($theme)"
      echo ""
      echo "Rebuilding system to apply theme..."
      cd "$DOTFILES_DIR" && nh os switch
    }

    # Main
    case "''${1:-}" in
      --list|-l)
        list_themes
        ;;
      --current|-c)
        echo "Current theme: $(get_current)"
        ;;
      --help|-h|"")
        echo "Theme Selector - Change system theme"
        echo ""
        echo "Usage:"
        echo "  theme-selector <theme>      Set theme (rebuilds system)"
        echo "  theme-selector --list       List available themes"
        echo "  theme-selector --current    Show current theme"
        echo ""
        list_themes
        ;;
      *)
        set_theme "$1"
        ;;
    esac
  '';
in
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
    ./programs/media.nix          # Media tools (swayimg, PhotoGIMP, Flowblade)
    ./programs/yt-dlp.nix         # YouTube downloader
    ./programs/nemo.nix           # Nemo file manager
    ./programs/xournalpp.nix      # PDF annotation
    ./programs/zathura.nix        # PDF viewer (Ristretto theme)

    # ── Communication ──
    ./programs/teamspeak.nix      # TeamSpeak 6
    ./programs/protonvpn.nix      # ProtonVPN GUI

    # ── Gaming ──
    ./programs/mangohud.nix       # In-game GPU/CPU/FPS overlay

    # ── Utilities ──
    ./programs/malware-vm.nix     # Malware Analysis VM (libvirt + killswitch)
    ./programs/security-packages.nix # Security tools aliases & docs
    ./programs/radio-sdr.nix      # SDR tools (SDR++, GQRX, rtl-sdr)

    # ── Services ──
    ./services/waybar.nix         # Status bar + custom scripts
    ./services/mako.nix           # Notifications
    ./services/hyprlock.nix       # Screen locker
    ./services/swayosd.nix        # Volume/brightness OSD

    # ── Configuration ──
    ./config/theme.nix            # Centralized Ristretto theme (colors + fonts)
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
    # Theme selector
    theme-selector  # GUI/CLI theme switcher (SUPER+T or `theme-selector`)

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
    # mpv removed - using VLC as default media player
    # swayimg moved to media.nix

    # Documents
    libreoffice-fresh
    # zathura moved to programs/zathura.nix

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

  # Disable XDG autostart for nm-applet (we launch it with delay in hyprland.nix)
  xdg.configFile."autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Hidden=true
  '';

  # NOTE: MIME types are centralized in ./config/mimeapps.nix
}
