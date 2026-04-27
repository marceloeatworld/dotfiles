# Shell configuration (ZSH with Starship prompt)
{ pkgs, config, ... }:

let
  theme = config.theme;

in
{
  home.packages = with pkgs; [
    nix-zsh-completions # Completions for nix, nix-env, nix-shell, etc.
    zsh-completions # Extra completions (nmap, docker, systemctl, etc.)
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # Extra completion packages (nmap, git, docker, systemctl, etc.)
    completionInit = ''
      # Interactive menu completion with descriptions
      zstyle ':completion:*' menu select                              # Arrow-key menu on Tab
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"      # Colorize file completions
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'  # Case-insensitive + fuzzy
      zstyle ':completion:*' format '%F{yellow}-- %d --%f'           # Category headers
      zstyle ':completion:*' group-name '''                           # Group by category
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:messages' format '%F{cyan}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
      zstyle ':completion:*' verbose yes                              # Show descriptions
      zstyle ':completion:*' squeeze-slashes true                     # /usr//bin -> /usr/bin
      zstyle ':completion:*' use-cache on                             # Cache completions
      zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"
      zstyle ':completion:*:*:kill:*' menu yes select                 # kill <Tab> shows PIDs
      zstyle ':completion:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

      autoload -Uz compinit && compinit -C
    '';
    shellAliases = {
      # NixOS - Using NH (modern nix helper)
      rebuild = "cd \"$(dotfiles-flake-dir)\" && nh os switch .";
      clean = "nh clean all --keep 5"; # Smarter garbage collection
      secrets = "sops \"$(dotfiles-flake-dir)/sops/api-keys.yaml\"";

      # Additional NH commands
      nb = "cd \"$(dotfiles-flake-dir)\" && nh os boot ."; # Build for next boot
      ntest = "cd \"$(dotfiles-flake-dir)\" && nh os test ."; # Test without setting boot default
      ndiff = "cd \"$(dotfiles-flake-dir)\" && nh os build ."; # See changes without applying

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
      # Captive portal (hotel/airport WiFi)
      captive-on = "sudo captive-portal-bypass on";
      captive-off = "sudo captive-portal-bypass off";
      # Google Cloud (gcloud) - switch between accounts
      gcp-me = "gcloud config configurations activate default";
      gcp-work = "gcloud config configurations activate \${GCLOUD_WORK_CONFIG:-work}";
      gcp-who = "gcloud config list";
      gcp-list = "gcloud config configurations list";
      gcp-login = "gcloud auth login";
      # AI/LLM
      # llm is a script in development.nix (llama-cli direct)
      # Hermes Agent profiles
      ai = "hermes chat"; # default: local llama-cpp
      "ai-coder" = "hermes -p coder chat"; # z.ai GLM-5.1
      "ai-minimax" = "hermes -p minimax chat"; # MiniMax M1 (2.7)
      # Kali Red Team (container + Hermes AI)
      "kali-ai" = "hermes -s kali-redteam chat"; # local model
      "kali-ai-coder" = "hermes -p coder -s kali-redteam chat"; # GLM-5.1
      "kali-ai-minimax" = "hermes -p minimax -s kali-redteam chat"; # MiniMax M1
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
      # NOTE: npm global PATH is set via home.sessionPath in development.nix

      function nix() {
        if [[ "$1" = "build" ]]; then
          local arg
          local has_link_flag=0

          for arg in "$@"; do
            case "$arg" in
              --no-link|--out-link|--out-link=*|-o)
                has_link_flag=1
                break
                ;;
            esac
          done

          if [[ $has_link_flag -eq 0 ]]; then
            command nix build --no-link "''${@:2}"
            return $?
          fi
        fi

        command nix "$@"
      }

      function dotfiles-flake-dir() {
        local dir=""
        local root=""

        if [[ -n "''${DOTFILES_FLAKE:-}" && -f "$DOTFILES_FLAKE/flake.nix" ]]; then
          print -r -- "$DOTFILES_FLAKE"
          return 0
        fi

        if root=$(git rev-parse --show-toplevel 2>/dev/null); then
          if [[ -f "$root/thinkpad-p14s-gen5/flake.nix" ]]; then
            dir="$root/thinkpad-p14s-gen5"
          elif [[ -f "$root/flake.nix" ]]; then
            dir="$root"
          fi
        fi

        if [[ -z "$dir" && -f "$HOME/dotfiles/thinkpad-p14s-gen5/flake.nix" ]]; then
          dir="$HOME/dotfiles/thinkpad-p14s-gen5"
        fi

        if [[ -z "$dir" ]]; then
          echo "Could not locate dotfiles flake. Run from the repo or set DOTFILES_FLAKE." >&2
          return 1
        fi

        print -r -- "$dir"
      }

      function clean-dotfiles-result-links() {
        setopt local_options null_glob

        local flake repo link
        flake=$(dotfiles-flake-dir 2>/dev/null) || return 0
        repo=$(dirname "$flake")

        for link in "$repo"/result "$repo"/result-* "$flake"/result "$flake"/result-*; do
          [[ -L "$link" ]] && unlink "$link"
        done
      }

      function overlay-path() {
        local flake
        flake=$(dotfiles-flake-dir) || return 1
        print -r -- "$flake/$1"
      }

      function update-binary-overlay() {
        local name="$1"
        local overlay_rel="$2"
        local latest_url="$3"
        local jq_filter="$4"
        local strip_prefix="$5"
        local download_template="$6"
        local hash_attr="$7"
        local prefetch_mode="''${8:-file}"
        local display_prefix="''${9:-}"

        local OVERLAY
        OVERLAY=$(overlay-path "$overlay_rel") || return 1

        echo ""
        echo "══════════════════════════════════════════"
        echo "  $name Update Check"
        echo "══════════════════════════════════════════"

        local LATEST_RAW
        LATEST_RAW=$(curl -sL "$latest_url" 2>/dev/null | jq -r "$jq_filter")
        local LATEST="$LATEST_RAW"
        if [[ -n "$strip_prefix" ]]; then
          LATEST="''${LATEST#$strip_prefix}"
        fi
        local CURRENT
        CURRENT=$(grep 'version = ' "$OVERLAY" | head -1 | sed 's/.*"\(.*\)".*/\1/')

        echo "Current: $display_prefix$CURRENT"
        echo "Latest:  $LATEST_RAW"

        if [[ -z "$LATEST" || "$LATEST" = "null" || "$LATEST_RAW" = "null" ]]; then
          echo "⚠ Could not fetch latest version (network error?)"
          return 0
        fi

        if [[ "$CURRENT" = "$LATEST" ]]; then
          echo "✓ Already up to date!"
          return 0
        fi

        local DOWNLOAD_URL="$download_template"
        DOWNLOAD_URL=$(printf '%s\n' "$DOWNLOAD_URL" | sed "s|{version}|$LATEST|g; s|{raw}|$LATEST_RAW|g")

        echo ""
        echo "Downloading $name $LATEST_RAW..."
        local HASH
        if [[ "$prefetch_mode" = "unpack" ]]; then
          HASH=$(nix-prefetch-url --unpack "$DOWNLOAD_URL")
        else
          HASH=$(nix-prefetch-url "$DOWNLOAD_URL")
        fi
        if [[ -z "$HASH" ]]; then
          echo "⚠ Failed to download $name $LATEST_RAW"
          return 1
        fi
        local SRI
        SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        sed -i "0,/version = \".*\"/{s/version = \".*\"/version = \"$LATEST\"/}" "$OVERLAY"
        sed -i "0,/$hash_attr = \".*\"/{s|$hash_attr = \".*\"|$hash_attr = \"$SRI\"|}" "$OVERLAY"

        echo "✓ Updated to $name $LATEST_RAW"
        return 2
      }

      function update-vscode() {
        update-binary-overlay \
          "VS Code" \
          "overlays/vscode-latest.nix" \
          "https://update.code.visualstudio.com/api/update/linux-x64/stable/latest" \
          ".productVersion" \
          "" \
          "https://update.code.visualstudio.com/{version}/linux-x64/stable" \
          "sha256"
      }

      function update-claude-code() {
        update-binary-overlay \
          "Claude Code" \
          "overlays/claude-code-latest.nix" \
          "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" \
          ".version" \
          "" \
          "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-{version}.tgz" \
          "sha256"
      }

      function update-opencode() {
        update-binary-overlay \
          "OpenCode" \
          "overlays/opencode-latest.nix" \
          "https://api.github.com/repos/anomalyco/opencode/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/anomalyco/opencode/releases/download/v{version}/opencode-linux-x64.tar.gz" \
          "sha256"
      }

      function update-forgecode() {
        update-binary-overlay \
          "ForgeCode" \
          "overlays/forgecode-latest.nix" \
          "https://api.github.com/repos/tailcallhq/forgecode/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/tailcallhq/forgecode/releases/download/v{version}/forge-x86_64-unknown-linux-musl" \
          "sha256"
      }

      function update-codex() {
        update-binary-overlay \
          "Codex" \
          "overlays/codex-latest.nix" \
          "https://api.github.com/repos/openai/codex/releases/latest" \
          ".tag_name" \
          "rust-v" \
          "https://github.com/openai/codex/releases/download/rust-v{version}/codex-x86_64-unknown-linux-musl.tar.gz" \
          "sha256"
      }

      function update-runpodctl() {
        update-binary-overlay \
          "RunPod CLI" \
          "overlays/runpodctl-latest.nix" \
          "https://api.github.com/repos/runpod/runpodctl/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/runpod/runpodctl/archive/refs/tags/v{version}.tar.gz" \
          "hash" \
          "unpack"
        local update_status=$?
        [[ $update_status -eq 2 ]] || return $update_status

        local OVERLAY
        OVERLAY=$(overlay-path "overlays/runpodctl-latest.nix") || return 1

        echo "Computing Go vendor hash..."
        local VENDOR_HASH
        VENDOR_HASH=$(nix-build --no-out-link -E "
          let pkgs = import <nixpkgs> {};
          in pkgs.callPackage $OVERLAY {}
        " 2>&1 | grep "got:" | awk '{print $2}')

        if [[ -n "$VENDOR_HASH" ]]; then
          sed -i "s|vendorHash = \"sha256-.*\"|vendorHash = \"$VENDOR_HASH\"|" "$OVERLAY"
        else
          echo "⚠ Could not compute vendorHash automatically"
          echo "  Source hash updated. Run 'rebuild' — if it fails, update vendorHash manually."
        fi

        return 2
      }

      # Update all agent skills (clone missing + pull existing)
      # Covers: Claude Code, ForgeCode, OpenCode skill caches + plugin marketplaces
      function update-skills() {
        echo ""
        echo "══════════════════════════════════════════"
        echo "  Agent Skills Update"
        echo "══════════════════════════════════════════"

        local updated=0
        local cloned=0
        local total=0

        # Unified skill cache — one clone per repo, distributed by ai-skills.nix on rebuild
        local skill_repos=(
          "$HOME/.cache/ai-skills/gemini|https://github.com/google-gemini/gemini-skills"
          "$HOME/.cache/ai-skills/cloudflare|https://github.com/cloudflare/skills"
          "$HOME/.cache/ai-skills/supabase|https://github.com/supabase/agent-skills"
          "$HOME/.cache/ai-skills/neon|https://github.com/neondatabase/agent-skills"
          "$HOME/.cache/ai-skills/pg-aiguide|https://github.com/timescale/pg-aiguide"
          "$HOME/.cache/ai-skills/android-re|https://github.com/SimoneAvogadro/android-reverse-engineering-skill"
          "$HOME/.cache/ai-skills/clerk|https://github.com/clerk/skills"
          "$HOME/.cache/ai-skills/runpod|https://github.com/runpod/skills"
          "$HOME/.cache/ai-skills/hyprland|https://github.com/marceloeatworld/hyprland-ai-skill"
          "$HOME/.cache/ai-skills/mdbook|https://github.com/marceloeatworld/mdbook-ai-skill"
          "$HOME/.cache/ai-skills/nixos|https://github.com/marceloeatworld/nixos-ai-skill"
          "$HOME/.cache/ai-skills/fal-ai|https://github.com/fal-ai-community/skills"
          "$HOME/.cache/ai-skills/vercel|https://github.com/vercel-labs/agent-skills"
          "$HOME/.cache/ai-skills/svelte|https://github.com/sveltejs/ai-tools"
          "$HOME/.cache/ai-skills/design-md|https://github.com/google-labs-code/design.md"
        )

        for entry in "''${skill_repos[@]}"; do
          local dir="''${entry%%|*}"
          local url="''${entry##*|}"
          local name=$(basename "$dir")
          local parent=$(basename "$(dirname "$dir")")
          total=$((total + 1))

          if [ ! -d "$dir/.git" ]; then
            echo "  Cloning: $parent/$name"
            mkdir -p "$(dirname "$dir")"
            git clone --quiet "$url" "$dir" 2>/dev/null || { echo "  Failed:  $parent/$name"; continue; }
            cloned=$((cloned + 1))
          else
            local before=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
            git -C "$dir" pull --ff-only --quiet 2>/dev/null || continue
            local after=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
            if [[ "$before" != "$after" ]]; then
              echo "  Updated: $parent/$name"
              updated=$((updated + 1))
            fi
          fi
        done

        # Also pull plugin marketplaces (no clone, managed by Claude Code)
        for dir in "$HOME/.claude/plugins/marketplaces/"*/; do
          [ -d "$dir/.git" ] || continue
          total=$((total + 1))
          local name=$(basename "$dir")
          local before=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
          git -C "$dir" pull --ff-only --quiet 2>/dev/null || continue
          local after=$(git -C "$dir" rev-parse HEAD 2>/dev/null)
          if [[ "$before" != "$after" ]]; then
            echo "  Updated: marketplaces/$name"
            updated=$((updated + 1))
          fi
        done

        echo ""
        if [[ $cloned -gt 0 || $updated -gt 0 ]]; then
          [[ $cloned -gt 0 ]] && echo "  Cloned:  $cloned new repos"
          [[ $updated -gt 0 ]] && echo "  Updated: $updated repos"
          echo "  Total:   $total skill repos"
          return 2
        else
          echo "  All $total skill repos up to date."
          return 0
        fi
      }

      function update-pnpm() {
        update-binary-overlay \
          "pnpm" \
          "overlays/pnpm-latest.nix" \
          "https://api.github.com/repos/pnpm/pnpm/releases/latest" \
          ".tag_name" \
          "v" \
          "https://github.com/pnpm/pnpm/releases/download/v{version}/pnpm-linuxstatic-x64" \
          "sha256"
      }

      # Update quick overlays (VS Code + Claude Code + OpenCode + ForgeCode + Codex + RunPod + pnpm)
      # Returns 0 if something was updated, 1 if nothing changed
      function update-overlays() {
        local changed=0
        update-vscode; [[ $? -eq 2 ]] && changed=1
        update-claude-code; [[ $? -eq 2 ]] && changed=1
        update-opencode; [[ $? -eq 2 ]] && changed=1
        update-forgecode; [[ $? -eq 2 ]] && changed=1
        update-codex; [[ $? -eq 2 ]] && changed=1
        update-runpodctl; [[ $? -eq 2 ]] && changed=1
        update-pnpm; [[ $? -eq 2 ]] && changed=1
        update-skills; [[ $? -eq 2 ]] && changed=1
        return $((1 - changed))
      }

      # Update overlays/skills, then rebuild only when something actually changed.
      function update-apps() {
        update-overlays
        local update_status=$?

        if [[ $update_status -eq 0 ]]; then
          local flake
          flake=$(dotfiles-flake-dir) || return 1
          (cd "$flake" && nh os switch .)
          return $?
        fi

        if [[ $update_status -eq 1 ]]; then
          echo "Nothing to update."
          return 0
        fi

        return $update_status
      }

      function update() {
        local flake update_status
        flake=$(dotfiles-flake-dir) || return 1

        clean-dotfiles-result-links

        (
          cd "$flake" || exit 1
          nix flake update &&
            { update-overlays || true; } &&
            nh os switch .
        )
        update_status=$?

        clean-dotfiles-result-links
        return $update_status
      }

      # Update llama.cpp and rebuild (long compile time)
      function update-llama() {
        update-binary-overlay \
          "llama.cpp" \
          "overlays/llama-cpp-latest.nix" \
          "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest" \
          ".tag_name" \
          "b" \
          "https://github.com/ggml-org/llama.cpp/archive/refs/tags/{raw}.tar.gz" \
          "hash" \
          "unpack" \
          "b"
        local update_status=$?
        [[ $update_status -eq 2 ]] || return $update_status

        echo ""
        echo "══════════════════════════════════════════"
        echo "  Rebuilding NixOS with llama.cpp..."
        echo "══════════════════════════════════════════"
        local flake
        flake=$(dotfiles-flake-dir) || return 1
        (cd "$flake" && nh os switch .)
      }

      function update-llama-cpp() {
        update-llama "$@"
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
      format = "$nix_shell$directory$git_branch$git_status$character";
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
        repo_root_style = "${theme.colors.accent}";
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
      <string>Current Theme</string>
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
            <string>${theme.colors.accent}</string>
            <key>lineHighlight</key>
            <string>${theme.colors.surface}</string>
            <key>selection</key>
            <string>${theme.colors.selection}</string>
            <key>selectionBorder</key>
            <string>${theme.colors.selection}</string>
            <key>findHighlight</key>
            <string>${theme.colors.accent}</string>
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
    enableZshIntegration = false; # Manual aliases in shellAliases (ls, ll, la, tree) take priority
    git = true;
    icons = "auto"; # NixOS 25.05: icons = "auto" instead of true
  };
}
