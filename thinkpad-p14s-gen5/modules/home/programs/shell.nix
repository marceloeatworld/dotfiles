# Shell configuration (ZSH with Starship prompt)
{ pkgs, config, ... }:

let
  theme = config.theme;

in
{
  home.packages = with pkgs; [
    # comma (`,`) is provided by programs.nix-index-database.comma below.
    nix-zsh-completions # Completions for nix, nix-env, nix-shell, etc.
    zsh-completions # Extra completions (nmap, docker, systemctl, etc.)
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true; # Type a directory name to cd into it
    cdpath = [
      "${config.home.homeDirectory}"
      "${config.home.homeDirectory}/Documents"
      "${config.home.homeDirectory}/Downloads"
      "${config.home.homeDirectory}/dotfiles"
    ];
    dirHashes = {
      cfg = "${config.xdg.configHome}";
      dl = "${config.home.homeDirectory}/Downloads";
      docs = "${config.home.homeDirectory}/Documents";
      dots = "${config.home.homeDirectory}/dotfiles";
      flake = "${config.home.homeDirectory}/dotfiles/thinkpad-p14s-gen5";
    };
    setOptions = [
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "PUSHD_TO_HOME"
      "INTERACTIVE_COMMENTS"
    ];
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };
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
      zstyle ':completion:*' list-dirs-first true                     # Directories before files
      zstyle ':completion:*' special-dirs true                        # Complete . and ..
      zstyle ':completion:*' rehash true                              # Pick up newly installed commands
      zstyle ':completion:*' use-cache on                             # Cache completions
      zstyle ':completion:*' cache-path "$HOME/.cache/zsh/compcache"
      zstyle ':completion:*:*:kill:*' menu yes select                 # kill <Tab> shows PIDs
      zstyle ':completion:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
      zstyle ':fzf-tab:*' fzf-command fzf
      zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border=rounded
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -la --icons --color=always $realpath 2>/dev/null'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -la --icons --color=always $realpath 2>/dev/null'
      zstyle ':fzf-tab:complete:(ls|eza|bat|nvim|vim):*' fzf-preview '[[ -d $realpath ]] && eza -la --icons --color=always $realpath 2>/dev/null || bat --style=numbers --color=always --line-range=:80 $realpath 2>/dev/null'

      autoload -Uz compinit && compinit -C
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
    '';
    shellAliases = {
      clean = "nh clean all --keep 5"; # Smarter garbage collection
      secrets = "sops \"$(dotfiles-flake-dir)/sops/api-keys.yaml\"";

      # Modern replacements
      ls = "eza --icons";
      ll = "eza -l --icons";
      la = "eza -la --icons";
      tree = "eza --tree --icons --group-directories-first";
      lt = "eza --tree --level=2 --icons --group-directories-first";
      lt3 = "eza --tree --level=3 --icons --group-directories-first";
      cat = "bat";
      y = "yazi";
      lz = "lazygit";
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
      # Headroom proxy sets ANTHROPIC_BASE_URL, which hides /remote-control
      # (requires api.anthropic.com). Plain claude is the default; use
      # claude-hr when token compression matters more than remote control.
      claude = "$HOME/.local/bin/claude";
      claude-hr = "headroom-claude";
      # jailed-agents wrappers (opt-in sandboxed agent sessions)
      "claude-jail" = "jailed-claude-code";
      "opencode-jail" = "jailed-opencode";
      "codex-jail" = "jailed-codex";
      "forge-jail" = "jailed-forgecode";
      # Shortcuts
      v = "nvim";
      vts = "NVIM_ENABLE_TS_LSP=1 nvim";
      vim = "nvim";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      append = true;
      extended = true;
      expireDuplicatesFirst = true;
      findNoDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      saveNoDups = true;
    };
    initContent = ''
      # NOTE: local user binaries are added via home.sessionPath in development.nix

      function take() {
        mkdir -p -- "$1" && cd -- "$1"
      }

      function croot() {
        local root
        root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
        cd -- "$root"
      }

      function yy() {
        local tmp cwd
        tmp=$(mktemp -t yazi-cwd.XXXXXX) || return 1
        yazi "$@" --cwd-file="$tmp"
        cwd=$(<"$tmp")
        rm -f -- "$tmp"
        [[ -n "$cwd" && "$cwd" != "$PWD" ]] && cd -- "$cwd"
      }

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

      function __dotfiles_nh() {
        local action="$1"
        shift

        local flake
        flake=$(dotfiles-flake-dir) || return 1
        (cd "$flake" && __with_nix_github_access_token nh os "$action" . "$@")
      }

      function rebuild() {
        __dotfiles_nh switch "$@"
      }

      function nb() {
        __dotfiles_nh boot "$@"
      }

      function ntest() {
        __dotfiles_nh test "$@"
      }

      function ndiff() {
        __dotfiles_nh build "$@"
      }

      # Launch Hyprland with UWSM on login to TTY1
      # See: https://wiki.hypr.land/Useful-Utilities/Systemd-start/
      # NixOS uses hyprland-uwsm.desktop (not hyprland.desktop) when withUWSM=true
      # tty guard first: uwsm is a Python program and spawning it in every
      # interactive shell adds startup latency for a check that can only
      # succeed on tty1.
      if [[ "$(tty)" == /dev/tty1 ]] && uwsm check may-start; then
        exec uwsm start hyprland-uwsm.desktop
      fi
    '';
  };

  # Starship prompt - compact two-line style
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Keep the path readable and leave the command line clean.
      format = "$nix_shell$directory$git_branch$git_status$line_break$character";
      add_newline = false;
      command_timeout = 200;

      character = {
        success_symbol = "[>](bold blue) ";
        error_symbol = "[x](bold red) ";
      };

      directory = {
        format = "[$path]($style)[$read_only]($read_only_style) ";
        truncation_length = 4;
        truncation_symbol = ".../";
        truncate_to_repo = true;
        home_symbol = "~";
        style = "bold blue";
        read_only = " ro";
        read_only_style = "bold red";
        before_repo_root_style = "dimmed blue";
        repo_root_style = "bold yellow";
        repo_root_format = "[$before_root_path]($before_repo_root_style)[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "purple";
      };

      git_status = {
        format = "[$all_status]($style)";
        style = "red";
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
        style = "cyan";
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

  # Command-not-found suggestions backed by nix-index, plus `comma` / `,` using the
  # prebuilt database from the nix-index-database flake input (imported in home.nix).
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;

  # Zoxide for smarter cd
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # Wider completion coverage for CLIs that do not ship good zsh completions
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
    ignoreCase = true;
  };

  # Smarter searchable shell history. Ctrl+R opens Atuin; Up remains normal zsh.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      enter_accept = true;
      filter_mode = "global";
      inline_height = 18;
      search_mode = "fuzzy";
      show_help = false;
      style = "compact";
      update_check = false;
    };
  };

  # Fix the previous failed command with: please
  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--alias" "please" ];
  };

  # FZF for fuzzy finding
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border=rounded"
      "--inline-info"
    ];
    fileWidget = {
      command = "fd --type f --hidden --follow --exclude .git";
      options = [
        "--preview 'bat --style=numbers --color=always --line-range=:120 {} 2>/dev/null || eza -la --icons --color=always {} 2>/dev/null'"
      ];
    };
    changeDirWidget = {
      command = "fd --type d --hidden --follow --exclude .git";
      options = [
        "--preview 'eza -la --icons --color=always {} 2>/dev/null'"
      ];
    };
    # Atuin owns Ctrl-R (see programs.atuin above); disable fzf's history
    # widget so home-manager stops warning about the double binding.
    historyWidget.command = "";
    colors = {
      bg = theme.colors.background;
      "bg+" = theme.colors.surface;
      fg = theme.colors.foreground;
      "fg+" = theme.colors.foreground;
      header = theme.colors.yellow;
      hl = theme.colors.accent;
      "hl+" = theme.colors.accent;
      info = theme.colors.comment;
      marker = theme.colors.green;
      pointer = theme.colors.accent;
      prompt = theme.colors.cyan;
      spinner = theme.colors.magenta;
    };
  };

  # Eza (ls replacement)
  programs.eza = {
    enable = true;
    enableZshIntegration = false; # Manual aliases in shellAliases (ls, ll, la, tree) take priority
    git = true;
    icons = "auto"; # NixOS 25.05: icons = "auto" instead of true
  };
}
