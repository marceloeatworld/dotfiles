# Shell configuration (ZSH with Starship prompt)
{ pkgs, config, inputs, ... }:

let
  theme = config.theme;

  # Keybindings cheatsheet content
  keysContent = ''
━━━━━━━━━━━━━━━ HYPRLAND ━━━━━━━━━━━━━━━
Super+Enter     Terminal (Ghostty)
Super+B         Browser (Brave)
Super+E         File manager (Nemo)
Super+D         App launcher
Super+A         Audio control panel
Super+Q         Close window

━━━━━━━━━━━━━ WINDOWS ━━━━━━━━━━━━━
Super+F         Fullscreen
Super+Shift+F   Fullscreen (keep bar)
Super+Space     Toggle floating
Super+P         Pin (all workspaces)
Super+T         Toggle split (H/V)
Super+H/J/K/L       Move focus
Super+Shift+HJKL    Move window
Super+Ctrl+HJKL     Resize window
Super+Mouse L       Move window (drag)
Super+Mouse R       Resize window (drag)

━━━━━━━━━━━━ WORKSPACES ━━━━━━━━━━━━
Super+1-9/0     Workspace 1-10
Super+Alt+H/L   Move to prev/next WS
Super+S         Special workspace
Super+Shift+S   Move to special WS

━━━━━━━━━━━━━━━ UTILS ━━━━━━━━━━━━━━━
Super+V         Clipboard history
Super+Shift+V   Clear clipboard
Super+C         Color picker
Super+N         Blue light filter
Super+Shift+N   Blue light off
Super+M         Battery mode
Super+Shift+M   Performance mode
Super+Shift+R   Restart Waybar

━━━━━━━━━━━━ SCREENSHOTS ━━━━━━━━━━━━
Print           Region → clipboard
Super+Print     Region → file
Super+Shift+Print   Full screen → file

━━━━━━━━━━━━━ SYSTEM ━━━━━━━━━━━━━
Super+Esc       Lock screen
Super+Shift+Esc Power off
Super+Ctrl+Esc  Reboot

━━━━━━━━━━━━━━━ NEOVIM ━━━━━━━━━━━━━━━
Space           Leader key
Space ?         Show all keybinds
Space e         File explorer
Space ff        Find file
Space fg        Grep search
Space w         Save | Space q  Quit
jk              Exit insert mode

━━━━━━━━━━ NEOVIM NAVIGATION ━━━━━━━━━━
gd  Definition    gr  References
K   Hover docs    Space ca  Code action
Space cr  Rename  Space cf  Format
[d / ]d   Prev/next diagnostic
s         Flash jump

━━━━━━━━━━━━ NEOVIM GIT ━━━━━━━━━━━━
Space gg  LazyGit    Space gd  Diff view
Space gb  Line blame Space gs  Stage hunk
[c / ]c   Prev/next git hunk

━━━━━━━━━━━━ TERMINAL ━━━━━━━━━━━━
rebuild   Rebuild NixOS
update    Update system
clean     Clean generations
ll / la   List files
z <dir>   Smart cd (zoxide)
Ctrl+R    History search

━━━━━━━━━━━━━ VMs ━━━━━━━━━━━━━
virt-manager           GUI VM manager
virt-viewer <vm>       View VM display
virsh list --all       List all VMs
virsh start <vm>       Start VM
virsh shutdown <vm>    Shutdown VM
virsh suspend <vm>     Pause VM
virsh resume <vm>      Resume VM
virsh snapshot-create-as <vm> <name>
virsh snapshot-revert <vm> <name>
virsh snapshot-list <vm>
virsh snapshot-delete <vm> <name>

VM Names: Windows-VM, Windows-Malware

━━━━━━━━━━ MALWARE VM ━━━━━━━━━━
sudo malware-vm setup       Create networks
malware-vm start            Start VM (isolated)
malware-vm killswitch       Isolate network
malware-vm network-on       Enable internet
malware-vm verify           Check isolation
malware-vm snapshot         Create snapshot
malware-vm restore          Restore snapshot
malware-vm status           Show VM status

━━━━━━━━━━━━ DOCKER ━━━━━━━━━━━━
docker ps              List containers
docker compose up -d   Start services
docker compose down    Stop services
lazydocker             Docker TUI

━━━━━━━━━━ SECURITY TOOLS ━━━━━━━━━━
nmap -sV <ip>          Port scan + versions
wireshark              Packet capture GUI
aircrack-ng            WiFi audit suite
hashcat                GPU password cracker
john                   CPU password cracker
sqlmap                 SQL injection
hydra                  Brute force login
ghidra                 Reverse engineering
angr                   Binary analysis (Python)

━━━━━━━━━━━━━ GIT ━━━━━━━━━━━━━
gs         git status
ga         git add
gc         git commit
gp         git push
gl         git pull
gd         git diff
lazygit    Git TUI
gitui      Git TUI (fast)

━━━━━━━━━━━━ AI/LLM ━━━━━━━━━━━━
llm                    Chat (default: dolphin-q8)
llm <model>            Chat with specific model
llm list               List available models
llm server [model]     Start OpenAI-compatible server
aichat                 CLI chat client

━━━━━━━━━━━━━ NIX ━━━━━━━━━━━━━
nix search nixpkgs <p> Search packages
nix shell nixpkgs#<p>  Temp install
nix run nixpkgs#<p>    Run without install
nix flake update       Update inputs
nix flake check        Validate flake
nix-tree               Visualize deps

━━━━━━━━━ MODERN CLI (Rust) ━━━━━━━━━
eza / ll / la          Better ls
bat                    Better cat (syntax)
fd                     Better find
rg                     Better grep (ripgrep)
dust                   Better du (disk usage)
duf                    Better df (filesystems)
procs                  Better ps
bottom                 Better top/htop
zoxide / z             Smart cd

━━━━━━━━━━━ DEBUGGING ━━━━━━━━━━━
gdb                    GNU debugger
gef                    GDB Enhanced Features
valgrind               Memory leak detector
strace                 System call tracer

━━━━━━━━━━━━ SYSTEM ━━━━━━━━━━━━
btop                   System monitor
journalctl -xe         System logs
systemctl status <s>   Service status
systemctl --failed     Failed services
tlp-stat               Battery/power info

━━━━━━━━━━ SDR / RADIO ━━━━━━━━━━
sdrpp                  SDR++ receiver (modern UI)
gqrx                   GQRX receiver (GNU Radio)
gnuradio-companion     GNU Radio flowgraph editor
rtl_test               Test RTL-SDR dongle
rtl_fm -f 98.5M -M fm  FM radio (98.5 MHz)
rtl_tcp -a 127.0.0.1   Stream SDR over network
kalibrate-rtl          Calibrate frequency offset
audacity               Audio analysis
'';

  # Write content to a file and read it with cat
  keysFile = pkgs.writeText "keys-cheatsheet" keysContent;
  keys-script = pkgs.writeShellScriptBin "keys" "${pkgs.coreutils}/bin/cat ${keysFile}";
in
{
  home.packages = [ keys-script ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # NixOS - Using NH (modern nix helper)
      rebuild = "nh os switch";
      update = "cd $HOME/dotfiles/thinkpad-p14s-gen5 && nix flake update && update-overlays && nh os switch";
      update-apps = "update-overlays && nh os switch";  # Updates VS Code & Claude Code (will close running instances)
      clean = "nh clean all --keep 5";  # Smarter garbage collection

      # Additional NH commands
      nb = "nh os boot";       # Build for next boot
      ntest = "nh os test";    # Test without setting boot default
      ndiff = "nh os build";   # See changes without applying

      # Modern replacements
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la --icons";
      tree = "eza --tree --icons";
      cat = "bat";
      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      # Shortcuts
      v = "nvim";
      vim = "nvim";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreSpace = true;
    };
    initContent = ''
      # npm global packages
      export PATH="$HOME/.npm-global/bin:$PATH"

      # VS Code auto-update function (fetches latest from Microsoft API)
      function update-vscode() {
        local OVERLAY="$HOME/dotfiles/thinkpad-p14s-gen5/overlays/vscode-latest.nix"

        echo "══════════════════════════════════════════"
        echo "  VS Code Update Check"
        echo "══════════════════════════════════════════"

        # Use official VS Code update API
        local API_RESPONSE=$(curl -s "https://update.code.visualstudio.com/api/update/linux-x64/stable/latest" 2>/dev/null)
        local LATEST=$(echo "$API_RESPONSE" | jq -r '.productVersion')
        local CURRENT=$(grep 'version = ' "$OVERLAY" | sed 's/.*"\(.*\)".*/\1/')

        echo "Current: $CURRENT"
        echo "Latest:  $LATEST"

        if [[ -z "$LATEST" || "$LATEST" = "null" ]]; then
          echo "⚠ Could not fetch latest version (network error?)"
          return 0
        fi

        if [[ "$CURRENT" = "$LATEST" ]]; then
          echo "✓ Already up to date!"
          return 0
        fi

        echo ""
        echo "Downloading VS Code $LATEST..."
        local HASH=$(nix-prefetch-url "https://update.code.visualstudio.com/$LATEST/linux-x64/stable" 2>/dev/null)
        if [[ -z "$HASH" ]]; then
          echo "⚠ Failed to download VS Code $LATEST"
          return 1
        fi
        local SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        sed -i "s/version = \".*\"/version = \"$LATEST\"/" "$OVERLAY"
        sed -i "s|sha256 = \".*\"|sha256 = \"$SRI\"|" "$OVERLAY"

        echo "✓ Updated to VS Code $LATEST"
      }

      # Claude Code auto-update function (fetches latest from npm registry)
      function update-claude-code() {
        local OVERLAY="$HOME/dotfiles/thinkpad-p14s-gen5/overlays/claude-code-latest.nix"

        echo ""
        echo "══════════════════════════════════════════"
        echo "  Claude Code Update Check"
        echo "══════════════════════════════════════════"

        local LATEST=$(curl -s "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" 2>/dev/null | jq -r '.version')
        local CURRENT=$(grep 'version = ' "$OVERLAY" | sed 's/.*"\(.*\)".*/\1/')

        echo "Current: $CURRENT"
        echo "Latest:  $LATEST"

        if [[ -z "$LATEST" || "$LATEST" = "null" ]]; then
          echo "⚠ Could not fetch latest version (network error?)"
          return 0
        fi

        if [[ "$CURRENT" = "$LATEST" ]]; then
          echo "✓ Already up to date!"
          return 0
        fi

        echo ""
        echo "Downloading Claude Code $LATEST..."
        local HASH=$(nix-prefetch-url "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$LATEST.tgz" 2>/dev/null)
        if [[ -z "$HASH" ]]; then
          echo "⚠ Failed to download Claude Code $LATEST"
          return 1
        fi
        local SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        sed -i "s/version = \".*\"/version = \"$LATEST\"/" "$OVERLAY"
        sed -i "s|hash = \".*\"|hash = \"$SRI\"|" "$OVERLAY"

        echo "✓ Updated to Claude Code $LATEST"
      }

      # llama.cpp auto-update function (fetches latest from GitHub releases)
      function update-llama-cpp() {
        local OVERLAY="$HOME/dotfiles/thinkpad-p14s-gen5/overlays/llama-cpp-latest.nix"

        echo ""
        echo "══════════════════════════════════════════"
        echo "  llama.cpp Update Check"
        echo "══════════════════════════════════════════"

        local LATEST_TAG=$(curl -s "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" 2>/dev/null | jq -r '.tag_name')
        local LATEST=$(echo "$LATEST_TAG" | sed 's/^b//')
        local CURRENT=$(grep 'version = ' "$OVERLAY" | head -1 | sed 's/.*"\(.*\)".*/\1/')

        echo "Current: b$CURRENT"
        echo "Latest:  $LATEST_TAG"

        if [[ -z "$LATEST" || "$LATEST" = "null" ]]; then
          echo "⚠ Could not fetch latest version (network error?)"
          return 0
        fi

        if [[ "$CURRENT" = "$LATEST" ]]; then
          echo "✓ Already up to date!"
          return 0
        fi

        echo ""
        echo "Downloading llama.cpp $LATEST_TAG..."
        local HASH=$(nix-prefetch-url --unpack "https://github.com/ggml-org/llama.cpp/archive/refs/tags/$LATEST_TAG.tar.gz" 2>/dev/null)
        if [[ -z "$HASH" ]]; then
          echo "⚠ Failed to download llama.cpp $LATEST_TAG"
          return 1
        fi
        local SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        sed -i "s/version = \".*\"/version = \"$LATEST\"/" "$OVERLAY"
        sed -i "s|hash = \".*\"|hash = \"$SRI\"|" "$OVERLAY"

        echo "✓ Updated to llama.cpp $LATEST_TAG"
      }

      # Update quick overlays (VS Code + Claude Code only)
      function update-overlays() {
        update-vscode
        update-claude-code
      }

      # Update llama.cpp separately (long compile time)
      function update-llama() {
        update-llama-cpp
        echo ""
        echo "══════════════════════════════════════════"
        echo "  Rebuilding NixOS with llama.cpp..."
        echo "══════════════════════════════════════════"
        nh os switch
      }

      # Update Cloudflare skill for Claude Code (and optionally OpenCode)
      function update-cf-skill() {
        "$HOME/dotfiles/scripts/install-cloudflare-skill.sh" "$@"
      }

      # Launch Hyprland with UWSM on login to TTY1
      # See: https://wiki.hypr.land/Useful-Utilities/Systemd-start/
      # NixOS uses hyprland-uwsm.desktop (not hyprland.desktop) when withUWSM=true
      if uwsm check may-start; then
        exec uwsm start hyprland-uwsm.desktop
      fi
    '';
  };

  # Starship prompt - minimal style
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Ultra-minimal format
      format = "$directory$git_branch$git_status$character";
      add_newline = false;
      command_timeout = 200;

      character = {
        success_symbol = "[>](${theme.colors.foreground})";
        error_symbol = "[x](${theme.colors.red})";
      };

      directory = {
        truncation_length = 2;
        truncation_symbol = "../";
        style = "${theme.colors.foreground}";
        repo_root_style = "${theme.colors.yellow}";
        repo_root_format = "[$repo_root]($repo_root_style)[$path]($style) ";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "${theme.colors.comment}";
      };

      git_status = {
        format = "[$all_status]($style)";
        style = "${theme.colors.comment}";
        ahead = "+";
        behind = "-";
        diverged = "+-";
        conflicted = "!";
        up_to_date = "";
        untracked = "?";
        modified = "*";
        stashed = "";
        staged = "+";
        renamed = "";
        deleted = "";
      };

      nix_shell = {
        symbol = "nix ";
        format = "[$symbol]($style)";
        style = "${theme.colors.comment}";
      };

      package.disabled = true;
    };
  };

  # Direnv for automatic environment switching
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # Zoxide for smarter cd
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # FZF for fuzzy finding
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Bat (cat replacement) - theme from theme.nix
  programs.bat = {
    enable = true;
    config = {
      theme = "current";
      style = "numbers,changes";
    };
  };

  # Bat theme (from theme.nix)
  home.file.".config/bat/themes/current.tmTheme".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Monokai Pro Ristretto</string>
      <key>settings</key>
      <array>
        <!-- Global Settings -->
        <dict>
          <key>settings</key>
          <dict>
            <key>background</key>
            <string>${theme.colors.background}</string>
            <key>foreground</key>
            <string>${theme.colors.foreground}</string>
            <key>caret</key>
            <string>${theme.colors.yellow}</string>
            <key>lineHighlight</key>
            <string>${theme.colors.surface}</string>
            <key>selection</key>
            <string>${theme.colors.selection}</string>
            <key>selectionBorder</key>
            <string>${theme.colors.selection}</string>
            <key>findHighlight</key>
            <string>${theme.colors.yellow}</string>
            <key>guide</key>
            <string>${theme.colors.border}</string>
            <key>activeGuide</key>
            <string>${theme.colors.foreground}</string>
          </dict>
        </dict>
        <!-- Comments -->
        <dict>
          <key>name</key>
          <string>Comment</string>
          <key>scope</key>
          <string>comment, punctuation.definition.comment</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.comment}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Strings -->
        <dict>
          <key>name</key>
          <string>String</string>
          <key>scope</key>
          <string>string</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.yellow}</string>
          </dict>
        </dict>
        <!-- Numbers -->
        <dict>
          <key>name</key>
          <string>Number</string>
          <key>scope</key>
          <string>constant.numeric</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.magenta}</string>
          </dict>
        </dict>
        <!-- Constants -->
        <dict>
          <key>name</key>
          <string>Constant</string>
          <key>scope</key>
          <string>constant, constant.language, constant.character</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.magenta}</string>
          </dict>
        </dict>
        <!-- Keywords -->
        <dict>
          <key>name</key>
          <string>Keyword</string>
          <key>scope</key>
          <string>keyword, storage.type, storage.modifier</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Operators -->
        <dict>
          <key>name</key>
          <string>Operator</string>
          <key>scope</key>
          <string>keyword.operator</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Functions -->
        <dict>
          <key>name</key>
          <string>Function</string>
          <key>scope</key>
          <string>entity.name.function, support.function, meta.function-call</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.green}</string>
          </dict>
        </dict>
        <!-- Classes -->
        <dict>
          <key>name</key>
          <string>Class</string>
          <key>scope</key>
          <string>entity.name.class, entity.name.type, support.class</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Variables -->
        <dict>
          <key>name</key>
          <string>Variable</string>
          <key>scope</key>
          <string>variable, variable.parameter</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.foreground}</string>
          </dict>
        </dict>
        <!-- Parameters -->
        <dict>
          <key>name</key>
          <string>Parameter</string>
          <key>scope</key>
          <string>variable.parameter</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.orange}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Tags (HTML/XML) -->
        <dict>
          <key>name</key>
          <string>Tag</string>
          <key>scope</key>
          <string>entity.name.tag</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Attributes -->
        <dict>
          <key>name</key>
          <string>Attribute</string>
          <key>scope</key>
          <string>entity.other.attribute-name</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Support -->
        <dict>
          <key>name</key>
          <string>Support</string>
          <key>scope</key>
          <string>support.type, support.constant</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
          </dict>
        </dict>
        <!-- Punctuation -->
        <dict>
          <key>name</key>
          <string>Punctuation</string>
          <key>scope</key>
          <string>punctuation</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.foreground}</string>
          </dict>
        </dict>
        <!-- Invalid -->
        <dict>
          <key>name</key>
          <string>Invalid</string>
          <key>scope</key>
          <string>invalid</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
            <key>background</key>
            <string>${theme.colors.surface}</string>
          </dict>
        </dict>
        <!-- Markdown Heading -->
        <dict>
          <key>name</key>
          <string>Markdown Heading</string>
          <key>scope</key>
          <string>markup.heading, entity.name.section</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
            <key>fontStyle</key>
            <string>bold</string>
          </dict>
        </dict>
        <!-- Markdown Bold -->
        <dict>
          <key>name</key>
          <string>Markdown Bold</string>
          <key>scope</key>
          <string>markup.bold</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.orange}</string>
            <key>fontStyle</key>
            <string>bold</string>
          </dict>
        </dict>
        <!-- Markdown Italic -->
        <dict>
          <key>name</key>
          <string>Markdown Italic</string>
          <key>scope</key>
          <string>markup.italic</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.yellow}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Markdown Link -->
        <dict>
          <key>name</key>
          <string>Markdown Link</string>
          <key>scope</key>
          <string>markup.underline.link, string.other.link</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
          </dict>
        </dict>
        <!-- Markdown Code -->
        <dict>
          <key>name</key>
          <string>Markdown Code</string>
          <key>scope</key>
          <string>markup.raw, markup.inline.raw</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.green}</string>
          </dict>
        </dict>
        <!-- Diff Added -->
        <dict>
          <key>name</key>
          <string>Diff Added</string>
          <key>scope</key>
          <string>markup.inserted, meta.diff.header.to-file</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.green}</string>
          </dict>
        </dict>
        <!-- Diff Removed -->
        <dict>
          <key>name</key>
          <string>Diff Removed</string>
          <key>scope</key>
          <string>markup.deleted, meta.diff.header.from-file</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Diff Changed -->
        <dict>
          <key>name</key>
          <string>Diff Changed</string>
          <key>scope</key>
          <string>markup.changed</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.orange}</string>
          </dict>
        </dict>
      </array>
    </dict>
    </plist>
  '';

  # Eza (ls replacement)
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";  # NixOS 25.05: icons = "auto" instead of true
  };
}
