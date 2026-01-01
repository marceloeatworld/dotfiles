# Shell configuration (ZSH with Starship prompt)
{ pkgs, config, inputs, ... }:

let
  theme = config.theme;
in
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

  # Bat (cat replacement) - Ristretto theme
  programs.bat = {
    enable = true;
    config = {
      theme = "ristretto";
      style = "numbers,changes,header";
    };
  };

  # Ristretto theme for bat (Monokai Pro Ristretto - from theme.nix)
  home.file.".config/bat/themes/ristretto.tmTheme".text = ''
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
