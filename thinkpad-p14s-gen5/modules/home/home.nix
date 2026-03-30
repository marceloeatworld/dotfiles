# Home Manager configuration for user marcelo
{ config, pkgs, ... }:

let
  # Wrangler (Cloudflare Workers CLI) - wrapper for bun global install
  # Auto-updated on rebuild via home.activation, always latest from npm
  # Bun global bin: ~/.cache/.bun/bin/
  wrangler-wrapper = pkgs.writeShellScriptBin "wrangler" ''
    exec "$HOME/.cache/.bun/bin/wrangler" "$@"
  '';

  # Theme selector script (CLI only)
  # Writes to dotfiles repo file which Nix reads at build time
  theme-selector = pkgs.writeShellScriptBin "theme-selector" ''
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
    ./programs/btop.nix           # System monitor (themed)
    ./programs/fastfetch.nix      # System info display

    # ── Development ──
    ./programs/nvim.nix           # Neovim with LazyVim
    ./programs/git.nix            # Git + delta diff viewer
    ./programs/development.nix    # VS Code, languages, tools
    ./programs/claude-code.nix    # Claude Code AI assistant
    ./programs/opencode.nix       # OpenCode AI coding agent (Z.AI GLM)
    ./programs/claude-ecc-skills.nix # ECC skills & commands (plan, verify, blueprint, etc.)

    # ── Applications ──
    # NOTE: Brave browser is installed via Firejail wrappedBinaries in security.nix
    ./programs/webapps.nix        # Web apps (WhatsApp, Spotify, etc.)
    ./programs/desktop-apps.nix   # Desktop entries for apps
    ./programs/media.nix          # Media tools (swayimg, PhotoGIMP, Flowblade)
    ./programs/yt-dlp.nix         # YouTube downloader
    ./programs/nemo.nix           # Nemo file manager
    ./programs/xournalpp.nix      # PDF annotation
    ./programs/zathura.nix        # PDF viewer (themed)

    # ── Networking ──
    ./programs/vpn.nix            # WireGuard VPN (Proton, country switching)

    # ── Communication ──
    ./programs/teamspeak.nix      # TeamSpeak 6

    # ── Gaming ──
    ./programs/mangohud.nix       # In-game GPU/CPU/FPS overlay

    # ── Utilities ──
    ./programs/malware-vm.nix     # Malware Analysis VM (libvirt + killswitch)
    ./programs/security-packages.nix # Security tools aliases & docs
    ./programs/kali-redteam.nix   # Kali Linux headless container (red team + local LLM)
    ./programs/radio-sdr.nix      # SDR tools (SDR++, GQRX, rtl-sdr)

    # ── Services ──
    ./services/waybar.nix         # Status bar + custom scripts
    ./services/mako.nix           # Notifications
    ./services/hyprlock.nix       # Screen locker
    ./services/swayosd.nix        # Volume/brightness OSD

    # ── Configuration ──
    ./config/theme.nix            # Centralized theme system (colors + fonts)
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
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # Required for Radeon 780M GPU acceleration (also set for llama-cpp in services.nix)
  };

  # Basic user packages
  # NOTE: btop is in btop.nix, fastfetch is in fastfetch.nix
  home.packages = with pkgs; [
    # Theme selector
    theme-selector  # CLI theme switcher (run 'theme-selector')

    # Wrangler (Cloudflare Workers CLI) - bun global, auto-installs if missing
    wrangler-wrapper  # Install/update: bun install -g wrangler@latest

    # System utilities
    hyprsysteminfo  # Official Hyprland system info (GUI)
    tree
    ripgrep
    fd
    eza
    # NOTE: bat is managed by programs.bat.enable in shell.nix
    # NOTE: fzf, zoxide, direnv are managed by programs.*.enable in shell.nix
    dust              # Better du (disk usage visualizer)
    tldr              # Simplified man pages

    # File management (Nemo and related packages moved to programs/nemo.nix)
    xed-editor        # Simple text editor from Linux Mint (pairs well with Nemo)
    yazi              # Terminal file manager (modern, replaces nnn/ranger)


    # NOTE: Archive tools (p7zip, unrar, zip, unzip) are in nemo.nix (context menu actions)

    # Network tools
    wget
    curl
    speedtest-cli

    # Productivity
    gnome-calculator  # Calculator app

    jq                # JSON processor (essential for CLI work)
    bc                # Calculator (used by Bitcoin price script)

    # Windows VM dependencies
    freerdp           # RDP client for Windows VM
    gum               # CLI styling for interactive prompts
    netcat            # Network connectivity checking

    # Python package manager
    uv                # Fast Python package manager (10-100x faster than pip)

    # API testing
    bruno             # Open source API client (Postman alternative, no login required)

    # Messaging (native clients, sandboxed via Firejail in security.nix)
    vesktop           # Discord client with Vencord (replaces discord-web webapp)
    zapzap            # WhatsApp client (replaces whatsapp-web webapp)

    # Apps sandboxed via Firejail (security.nix) - packages here for .desktop visibility in launcher
    spotify           # Music streaming
    vlc               # Media player
    transmission_4-gtk # Torrent client
    libreoffice-fresh # Office suite
    inkscape          # Vector graphics editor
    keepassxc         # Password manager
    blender           # 3D modelling
    obs-studio        # Screen recording
    audacity          # Audio editor
    xournalpp         # PDF annotation
    joplin-desktop    # Note-taking
    telegram-desktop  # Messaging

    # Wayland specific (core tools in system/hyprland.nix)
    hyprpicker        # Color picker for Hyprland
    nwg-displays      # Monitor management GUI (position, rotation, resolution)
    # NOTE: swayosd is managed by systemd service in swayosd.nix
    satty             # Screenshot annotation
    # NOTE: blueman provided by services.blueman.enable (networking.nix)

    # NOTE: Fonts are installed system-wide in modules/system/fonts.nix
    # This is REQUIRED for Hyprland/Waybar and other Wayland apps
    # Do NOT install fonts in home.packages - use fonts.packages instead
  ];

  # Auto-update wrangler via bun global on every rebuild
  home.activation.updateWrangler = config.lib.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.bun}/bin/bun install -g wrangler@latest 2>/dev/null || true
  '';

  # ZapZap (WhatsApp) - custom CSS theme matching system theme
  xdg.dataFile."ZapZap/customizations/global/css/theme.css".text = let
    theme = config.theme;
  in ''
    /* System theme for WhatsApp Web - auto-generated from config.theme */

    /* Main background */
    ._aigs, /* chat list panel */
    ._aigw, /* main background */
    .two,
    #app,
    ._aigs ._aigv,
    [data-testid="chatlist-header"],
    [data-testid="chat-list"],
    header._amid,
    ._amie {
      background-color: ${theme.colors.background} !important;
    }

    /* Chat area / conversation background */
    ._akbu,
    .copyable-area,
    ._aigz,
    ._akba,
    span.selectable-text {
      background-color: ${theme.colors.backgroundAlt} !important;
    }

    /* Sidebar / panels */
    ._aig-,
    ._aigs,
    [data-testid="drawer-left"],
    [data-testid="drawer-right"],
    ._amig,
    ._amih {
      background-color: ${theme.colors.background} !important;
    }

    /* Message bubbles - outgoing */
    .message-out ._akbu,
    .message-out .copyable-text,
    .message-out [data-pre-plain-text],
    ._akbr {
      background-color: ${theme.colors.surface} !important;
    }

    /* Message bubbles - incoming */
    .message-in ._akbu,
    .message-in .copyable-text,
    .message-in [data-pre-plain-text],
    ._akbs {
      background-color: ${theme.colors.backgroundAlt} !important;
    }

    /* Text color */
    span.selectable-text,
    ._ao3e,
    ._amk4,
    ._amk6,
    [data-testid="conversation-info-header-chat-title"],
    [data-testid="cell-frame-title"] {
      color: ${theme.colors.foreground} !important;
    }

    /* Secondary text */
    [data-testid="last-msg-status"],
    [data-testid="cell-frame-secondary"],
    ._amk7,
    ._ahlk {
      color: ${theme.colors.foregroundDim} !important;
    }

    /* Input / compose box */
    [data-testid="conversation-compose-box-input"],
    ._ak1q,
    footer,
    ._akbu._ao_0 {
      background-color: ${theme.colors.surface} !important;
      color: ${theme.colors.foreground} !important;
    }

    /* Search box */
    [data-testid="chat-list-search"],
    ._amid._amie,
    ._amig ._amih,
    ._aigu {
      background-color: ${theme.colors.surface} !important;
      color: ${theme.colors.foreground} !important;
    }

    /* Borders */
    ._aigs,
    header,
    [data-testid="chatlist-header"],
    ._amid {
      border-color: ${theme.colors.border} !important;
    }

    /* Accent color (green checkmarks, links) */
    ._amid ._amie svg,
    [data-icon="double-check"],
    a {
      color: ${theme.colors.green} !important;
    }

    /* Scrollbar */
    ::-webkit-scrollbar-thumb {
      background-color: ${theme.colors.selection} !important;
    }
    ::-webkit-scrollbar-track {
      background-color: ${theme.colors.background} !important;
    }

    /* Selection highlight */
    ::selection {
      background-color: ${theme.colors.selection} !important;
    }

    /* Unread badge */
    ._ahlk[data-testid="icon-unread-count"] {
      background-color: ${theme.colors.green} !important;
    }
  '';

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
