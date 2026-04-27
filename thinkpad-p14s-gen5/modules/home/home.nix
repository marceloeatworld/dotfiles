# Home Manager configuration for user marcelo
{ config, pkgs, inputs, lib, ... }:

let
  wranglerVersion = "4.85.0";

  # Cloudflare Workers CLI from the official npm package.
  # Bun resolves/caches the npm package at runtime; Node stays in PATH for
  # Wrangler's Node shebang. This avoids pkgs.wrangler and its pnpm-deps build.
  wrangler-wrapper = pkgs.writeShellScriptBin "wrangler" ''
    export PATH="${pkgs.nodejs_22}/bin:$PATH"
    exec ${pkgs.bun}/bin/bun x wrangler@${wranglerVersion} "$@"
  '';

  themeEntries = lib.concatMapStringsSep "\n"
    (themeName:
      let
        meta = config.theme.metadata.${themeName};
      in
      ''      ["${themeName}"]="${meta.name}|${meta.description}"''
    )
    config.theme.available;
  themeNames = lib.concatStringsSep " " config.theme.available;

  # Theme selector script (CLI only)
  # Writes to dotfiles repo file which Nix reads at build time
  theme-selector = pkgs.writeShellScriptBin "theme-selector" ''
        # Theme Selector - CLI interface
        # Usage:
        #   theme-selector <theme>    # Sets theme directly
        #   theme-selector --list     # Lists available themes
        #   theme-selector --current  # Shows current theme

        find_dotfiles_dir() {
          if [ -n "''${DOTFILES_FLAKE:-}" ] && [ -f "$DOTFILES_FLAKE/flake.nix" ]; then
            printf '%s\n' "$DOTFILES_FLAKE"
            return 0
          fi

          local root
          if root="$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)"; then
            if [ -f "$root/thinkpad-p14s-gen5/flake.nix" ]; then
              printf '%s\n' "$root/thinkpad-p14s-gen5"
              return 0
            fi
            if [ -f "$root/flake.nix" ]; then
              printf '%s\n' "$root"
              return 0
            fi
          fi

          if [ -f "$HOME/dotfiles/thinkpad-p14s-gen5/flake.nix" ]; then
            printf '%s\n' "$HOME/dotfiles/thinkpad-p14s-gen5"
            return 0
          fi

          echo "Could not locate dotfiles flake. Run from the repo or set DOTFILES_FLAKE." >&2
          return 1
        }

        DOTFILES_DIR="$(find_dotfiles_dir)"
        THEME_FILE="$DOTFILES_DIR/modules/home/config/current-theme"

        # Available themes with descriptions
        declare -A THEMES=(
    ${themeEntries}
        )

        # Get current theme from file
        get_current() {
          if [ -f "$THEME_FILE" ]; then
            tr -d '[:space:]' < "$THEME_FILE"
          else
            echo "ristretto"
          fi
        }

        # List themes
        list_themes() {
          echo "Available themes:"
          current=$(get_current)
          for key in ${themeNames}; do
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
          cd "$DOTFILES_DIR" && ${pkgs.nh}/bin/nh os switch
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
    # ── Secrets (sops-nix) ──
    inputs.sops-nix.homeManagerModules.sops
    ./config/secrets.nix # API keys (age-encrypted)

    # ── Desktop & Window Manager ──
    ./programs/hyprland.nix # Hyprland config, keybindings, animations
    ./programs/hyprlauncher.nix # Application launcher
    ./programs/uwsm.nix # Universal Wayland Session Manager

    # ── Terminal & Shell ──
    ./programs/terminal.nix # Ghostty + Alacritty terminals
    ./programs/shell.nix # Zsh + Starship prompt
    ./programs/keys.nix # Terminal cheatsheet command (`keys`)
    ./programs/btop.nix # System monitor (themed)
    ./programs/fastfetch.nix # System info display

    # ── Development ──
    ./programs/nvim.nix # Neovim with LazyVim
    ./programs/git.nix # Git + delta diff viewer
    ./programs/vscode.nix # VS Code package, wrapper and UI settings
    ./programs/development.nix # Languages and development tools
    ./programs/claude-code.nix # Claude Code AI assistant
    ./programs/opencode.nix # OpenCode AI coding agent (Z.AI GLM)
    ./programs/forgecode.nix # ForgeCode AI coding harness (Rust, ZSH integration)
    ./programs/codex.nix # Codex AI coding agent (OpenAI, Rust musl static)
    ./programs/ai-skills.nix # Centralized skills for Claude/Forge/OpenCode

    # ── Applications ──
    # NOTE: Brave browser is installed via Firejail wrappedBinaries in security.nix
    ./programs/webapps.nix # Web apps (WhatsApp, Spotify, etc.)
    ./programs/desktop-apps.nix # Desktop entries for apps
    ./programs/media.nix # Media tools (swayimg, PhotoGIMP, Flowblade)
    ./programs/yt-dlp.nix # YouTube downloader
    ./programs/nemo.nix # Nemo file manager
    ./programs/xournalpp.nix # PDF annotation
    ./programs/zathura.nix # PDF viewer (themed)

    # ── Networking ──
    ./programs/vpn.nix # WireGuard VPN (Proton, country switching)

    # ── Gaming ──
    ./programs/mangohud.nix # In-game GPU/CPU/FPS overlay

    # ── Utilities ──
    ./programs/analysis-vm.nix # Malware Analysis Lab (FLARE-VM + REMnux + Dev-Win, libvirt + killswitch)
    ./programs/security-packages.nix # Security tools aliases & docs
    ./programs/kali-redteam.nix # Kali Linux headless container (red team + local LLM)
    ./programs/radio-sdr.nix # SDR tools (SDR++, GQRX, rtl-sdr)

    # ── Services ──
    ./services/waybar.nix # Status bar + custom scripts
    ./services/mako.nix # Notifications
    ./services/hyprlock.nix # Screen locker
    ./services/swayosd.nix # Volume/brightness OSD

    # ── Configuration ──
    ./config/theme.nix # Centralized theme system (colors + fonts)
    ./config/gtk.nix # GTK theme (Adwaita-dark)
    ./config/qt.nix # Qt theme
    ./config/fontconfig.nix # Font configuration
    ./config/webapp-icons.nix # Custom icons for web apps
    ./config/hyprpaper.nix # Wallpaper configuration
    ./config/mimeapps.nix # File associations (centralized)
  ];

  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "brave"; # NOTE: xdg-settings reads this and may match webapp .desktop files first — MIME defaults are set in mimeapps.nix
    TERMINAL = "ghostty";
    DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
    CONTAINER_HOST = "unix:///run/user/1000/podman/podman.sock";

    # Wayland backend preferences
    SAL_USE_VCLPLUGIN = "gtk3"; # LibreOffice native Wayland via GTK3

  };

  # Basic user packages
  # NOTE: btop is in btop.nix, fastfetch is in fastfetch.nix
  home.packages = with pkgs; [
    # Theme selector
    theme-selector # CLI theme switcher (run 'theme-selector')

    # Cloudflare Workers CLI - official npm package, resolved by Bun at runtime
    wrangler-wrapper

    # System utilities
    hyprsysteminfo # Official Hyprland system info (GUI)
    tree
    ripgrep
    fd
    eza
    # NOTE: bat is managed by programs.bat.enable in shell.nix
    # NOTE: fzf, zoxide, direnv are managed by programs.*.enable in shell.nix
    dust # Better du (disk usage visualizer)
    tldr # Simplified man pages

    # File management (Nemo and related packages moved to programs/nemo.nix)
    xed-editor # Simple text editor from Linux Mint (pairs well with Nemo)
    yazi # Terminal file manager (modern, replaces nnn/ranger)


    # NOTE: Archive tools (p7zip, unrar, zip, unzip) are in nemo.nix (context menu actions)

    # Network tools
    wget
    curl
    speedtest-cli

    # GPU cloud
    runpodctl # RunPod CLI - manage GPU pods/serverless (v2, built from source)

    # Productivity
    gnome-calculator # Calculator app

    jq # JSON processor (essential for CLI work)
    bc # Calculator (used by Bitcoin price script)

    # Windows VM dependencies
    freerdp # RDP client for Windows VM
    gum # CLI styling for interactive prompts
    netcat # Network connectivity checking

    # Python package manager
    uv # Fast Python package and project manager

    # API testing
    bruno # Open source API client (Postman alternative, no login required)

    # Messaging (native clients, sandboxed via Firejail in security.nix)
    vesktop # Discord client with Vencord (replaces discord-web webapp)
    zapzap # WhatsApp client (replaces whatsapp-web webapp)

    # Apps sandboxed via Firejail (security.nix) - packages here for .desktop visibility in launcher
    spotify # Music streaming
    vlc # Media player
    transmission_4-gtk # Torrent client
    libreoffice-fresh # Office suite
    inkscape # Vector graphics editor
    keepassxc # Password manager
    blender # 3D modelling
    obs-studio # Screen recording
    audacity # Audio editor
    xournalpp # PDF annotation
    joplin-desktop # Note-taking
    telegram-desktop # Messaging

    # Wayland specific (core tools in system/hyprland.nix)
    hyprpicker # Color picker for Hyprland
    nwg-displays # Monitor management GUI (position, rotation, resolution)
    # NOTE: swayosd is managed by systemd service in swayosd.nix
    satty # Screenshot annotation
    # NOTE: blueman provided by services.blueman.enable (networking.nix)

    # NOTE: Fonts are installed system-wide in modules/system/fonts.nix
    # This is REQUIRED for Hyprland/Waybar and other Wayland apps
    # Do NOT install fonts in home.packages - use fonts.packages instead
  ];

  # XDG user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
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
