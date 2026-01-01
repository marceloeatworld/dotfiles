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
      rebuild = "update-vscode; nh os switch";  # Auto-updates VS Code before rebuild
      update = "cd $HOME/dotfiles/thinkpad-p14s-gen5 && nix flake update && update-vscode && nh os switch";
      clean = "nh clean all --keep 5";  # Smarter garbage collection

      # Additional NH commands
      nb = "nh os boot";       # Build for next boot
      ntest = "nh os test";    # Test without setting boot default
      ndiff = "nh os build";   # See changes without applying

      # VS Code auto-update (fetches latest, updates overlay, rebuilds)
      update-vscode = ''
        set -e
        OVERLAY="$HOME/dotfiles/thinkpad-p14s-gen5/overlays/vscode-latest.nix"

        echo "Fetching latest VS Code version..."
        LATEST=$(curl -sI "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" | grep -i location | sed -n 's/.*\/\([0-9.]*\)\/.*/\1/p' | tr -d '\r')
        CURRENT=$(grep 'version = ' "$OVERLAY" | sed 's/.*"\(.*\)".*/\1/')

        echo "Current: $CURRENT"
        echo "Latest:  $LATEST"

        if [ "$CURRENT" = "$LATEST" ]; then
          echo "Already up to date!"
          exit 0
        fi

        echo ""
        echo "Downloading VS Code $LATEST and computing hash..."
        HASH=$(nix-prefetch-url "https://update.code.visualstudio.com/$LATEST/linux-x64/stable" 2>/dev/null)
        SRI=$(nix hash convert --hash-algo sha256 --to sri "$HASH")

        echo "Updating $OVERLAY..."
        sed -i "s/version = \".*\"/version = \"$LATEST\"/" "$OVERLAY"
        sed -i "s|sha256 = \".*\"|sha256 = \"$SRI\"|" "$OVERLAY"

        echo ""
        echo "Updated to VS Code $LATEST"
      '';

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

      # Launch Hyprland on login to TTY1
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
        exec uwsm start -S hyprland-uwsm.desktop
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
