# Shell configuration (ZSH with Starship prompt)
{ pkgs, config, inputs, ... }:
{
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
        local HASH=$(nix-prefetch-url --unpack "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-$LATEST.tgz" 2>/dev/null)
        if [[ -z "$HASH" ]]; then
          echo "⚠ Failed to download Claude Code $LATEST"
          return 1
        fi
        local SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        sed -i "s/version = \".*\"/version = \"$LATEST\"/" "$OVERLAY"
        sed -i "s|hash = \".*\"|hash = \"$SRI\"|" "$OVERLAY"

        echo "✓ Updated to Claude Code $LATEST"
      }

      # Update all custom overlays
      function update-overlays() {
        update-vscode
        update-claude-code
      }

      # Launch Hyprland with UWSM on login to TTY1
      # See: https://wiki.hypr.land/Useful-Utilities/Systemd-start/
      # NixOS uses hyprland-uwsm.desktop (not hyprland.desktop) when withUWSM=true
      if uwsm check may-start; then
        exec uwsm start hyprland-uwsm.desktop
      fi
    '';
  };

  # Starship prompt (Ristretto theme)
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Minimalist format: directory + git + character
      format = "[$directory$git_branch$git_status]($style)$character";
      add_newline = true;
      command_timeout = 200;

      character = {
        success_symbol = "[❯](bold cyan)";
        error_symbol = "[✗](bold cyan)";
      };

      directory = {
        truncation_length = 2;
        truncation_symbol = "…/";
        repo_root_style = "bold cyan";
        repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "italic cyan";
      };

      git_status = {
        format = "[$all_status]($style)";
        style = "cyan";
        ahead = "⇡\${count} ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
        behind = "⇣\${count} ";
        conflicted = " ";
        up_to_date = " ";
        untracked = "? ";
        modified = " ";
        stashed = "";
        staged = "";
        renamed = "";
        deleted = "";
      };

      # Keep nix_shell for NixOS development
      nix_shell = {
        symbol = " ";
        format = "via [$symbol$state]($style) ";
      };

      # Disable package module (minimalist)
      package = {
        disabled = true;
      };
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

  # Bat (cat replacement)
  programs.bat = {
    enable = true;
    config = {
      theme = "catppuccin-mocha";
      style = "numbers,changes,header";
    };
    themes = {
      catppuccin-mocha = {
        src = inputs.catppuccin-bat;
        file = "themes/Catppuccin Mocha.tmTheme";
      };
    };
  };

  # Eza (ls replacement)
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";  # NixOS 25.05: icons = "auto" instead of true
  };
}
