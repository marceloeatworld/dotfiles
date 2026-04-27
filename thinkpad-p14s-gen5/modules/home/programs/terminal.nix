# Terminal emulator configuration
# Terminal emulators: Ghostty (primary) + Alacritty (backup)
{ config, ... }:

let
  theme = config.theme;
in
{
  # ============================================
  # GHOSTTY - Primary terminal (modern, fast, compatible)
  # ============================================
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # ── Font ──
      font-family = theme.fonts.mono;
      font-size = 10;
      minimum-contrast = 1.2;  # Slight safety net for dim text without flattening the theme

      # ── Window ──
      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-color = "extend";    # Padding matches adjacent cell color (not always bg)
      window-padding-balance = true;      # Center content when padding doesn't divide evenly
      window-decoration = false;
      background-opacity = 0.96;          # More readable; Hyprland still provides subtle depth
      resize-overlay = "after-first";     # Show size overlay on resize

      # ── Cursor ──
      cursor-style = "block";
      cursor-style-blink = false;

      # ── Theme colors ──
      background = theme.colors.background;
      foreground = theme.colors.foreground;
      selection-background = theme.colors.selection;
      selection-foreground = theme.colors.foreground;
      cursor-color = theme.colors.accent;

      palette = [
        "0=${theme.colors.brightBlack}"
        "1=${theme.colors.red}"
        "2=${theme.colors.green}"
        "3=${theme.colors.yellow}"
        "4=${theme.colors.blue}"
        "5=${theme.colors.magenta}"
        "6=${theme.colors.cyan}"
        "7=${theme.colors.foreground}"
        "8=${theme.colors.comment}"
        "9=${theme.colors.red}"
        "10=${theme.colors.green}"
        "11=${theme.colors.yellow}"
        "12=${theme.colors.blue}"
        "13=${theme.colors.magenta}"
        "14=${theme.colors.cyan}"
        "15=${theme.colors.brightWhite}"
      ];

      # ── Shell integration (enable non-default features) ──
      # Defaults already enable: cursor, title, path
      # sudo: preserve terminfo through sudo
      # ssh-env: auto TERM=xterm-256color on SSH
      # ssh-terminfo: auto-install ghostty terminfo on remote hosts
      shell-integration-features = "sudo,ssh-env,ssh-terminfo";

      # ── Splits ──
      unfocused-split-opacity = 0.90;  # Dim inactive splits without hurting readability
      focus-follows-mouse = true;       # Split focus follows mouse

      # ── Clipboard ──
      copy-on-select = "clipboard";
      clipboard-read = "allow";          # Let programs (tmux/nvim) read clipboard via OSC 52
      clipboard-trim-trailing-spaces = true;
      clipboard-paste-protection = true;  # Keep paste warnings for risky multi-line commands

      # ── Mouse ──
      mouse-hide-while-typing = true;
      link-url = true;

      # ── Notifications ──
      notify-on-command-finish = "unfocused";           # Notify when long commands finish in unfocused tab/split
      notify-on-command-finish-after = "10s";           # Only for commands running 10+ seconds
      notify-on-command-finish-action = "no-bell,notify"; # Desktop notification instead of terminal bell

      # ── Performance ──
      gtk-single-instance = "detect";  # Smart detection (was false — caused blank windows)

      # ── Scrollback ──
      scrollback-limit = 10000000;  # Default-sized history, useful for logs/build output

      # ── Confirm ──
      confirm-close-surface = true;  # Shell integration avoids prompts when already at a prompt

      # Keybindings (must be in settings as a list)
      keybind = [
        # Copy/Paste
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
        "ctrl+insert=copy_to_clipboard"
        "shift+insert=paste_from_clipboard"

        # Tab management
        "ctrl+shift+t=new_tab"
        "ctrl+shift+w=close_surface"
        "ctrl+shift+right=next_tab"
        "ctrl+shift+left=previous_tab"
        "ctrl+shift+one=goto_tab:1"
        "ctrl+shift+two=goto_tab:2"
        "ctrl+shift+three=goto_tab:3"
        "ctrl+shift+four=goto_tab:4"
        "ctrl+shift+five=goto_tab:5"
        "ctrl+shift+six=goto_tab:6"
        "ctrl+shift+seven=goto_tab:7"
        "ctrl+shift+eight=goto_tab:8"
        "ctrl+shift+nine=goto_tab:9"

        # Split management - create
        "ctrl+shift+enter=new_split:down"
        "ctrl+shift+backslash=new_split:right"
        "ctrl+alt+enter=new_split:up"
        "ctrl+alt+backslash=new_split:left"

        # Split navigation - vim style (hjkl)
        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+j=goto_split:bottom"
        "ctrl+shift+k=goto_split:top"
        "ctrl+shift+l=goto_split:right"
        "ctrl+shift+]=goto_split:next"
        "ctrl+shift+[=goto_split:previous"

        # Split resize
        "ctrl+alt+h=resize_split:left,50"
        "ctrl+alt+j=resize_split:down,50"
        "ctrl+alt+k=resize_split:up,50"
        "ctrl+alt+l=resize_split:right,50"

        # Split equalize
        "ctrl+shift+e=equalize_splits"

        # Font size
        "ctrl+shift+equal=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
        "ctrl+shift+zero=reset_font_size"

        # Scrollback
        "ctrl+shift+up=scroll_page_up"
        "ctrl+shift+down=scroll_page_down"
        "ctrl+shift+page_up=scroll_page_up"
        "ctrl+shift+page_down=scroll_page_down"
        "ctrl+shift+home=scroll_to_top"
        "ctrl+shift+end=scroll_to_bottom"

        # Quick commands
        "ctrl+shift+u=write_screen_file:open"
      ];
    };
  };

  # ============================================
  # ALACRITTY - Backup terminal (simple, fast)
  # ============================================
  programs.alacritty = {
    enable = true;
    settings = {
      general = {
        live_config_reload = true;
      };

      env = {
        TERM = "alacritty";
        COLORTERM = "truecolor";
      };

      # Window - minimal padding
      window = {
        padding = { x = 4; y = 4; };
        dynamic_padding = true;
        decorations = "none";
        opacity = 0.96;
      };

      # Font
      font = {
        normal = { family = theme.fonts.mono; style = "Regular"; };
        size = 10;
        offset = { x = 0; y = 1; };
      };

      # Cursor
      cursor = {
        style = { shape = "Block"; blinking = "Off"; };
      };

      # Scrolling
      scrolling = {
        history = 10000;
        multiplier = 3;
      };

      # Selection
      selection = {
        save_to_clipboard = true;
      };

      mouse = {
        hide_when_typing = true;
      };

      # Bell
      bell = {
        duration = 0;
      };

      # Colors from theme.nix
      colors = {
        primary = {
          background = theme.colors.background;
          foreground = theme.colors.foreground;
        };
        cursor = {
          text = theme.colors.background;
          cursor = theme.colors.accent;
        };
        selection = {
          text = theme.colors.foreground;
          background = theme.colors.selection;
        };
        search = {
          matches = {
            foreground = theme.colors.background;
            background = theme.colors.yellow;
          };
          focused_match = {
            foreground = theme.colors.background;
            background = theme.colors.accent;
          };
        };
        hints = {
          start = {
            foreground = theme.colors.background;
            background = theme.colors.accent;
          };
          end = {
            foreground = theme.colors.background;
            background = theme.colors.yellow;
          };
        };
        footer_bar = {
          foreground = theme.colors.foreground;
          background = theme.colors.backgroundAlt;
        };
        line_indicator = {
          foreground = theme.colors.accent;
          background = theme.colors.backgroundAlt;
        };
        vi_mode_cursor = {
          text = theme.colors.background;
          cursor = theme.colors.accent;
        };
        normal = {
          black = theme.colors.brightBlack;
          red = theme.colors.red;
          green = theme.colors.green;
          yellow = theme.colors.yellow;
          blue = theme.colors.blue;
          magenta = theme.colors.magenta;
          cyan = theme.colors.cyan;
          white = theme.colors.foreground;
        };
        bright = {
          black = theme.colors.comment;
          red = theme.colors.red;
          green = theme.colors.green;
          yellow = theme.colors.yellow;
          blue = theme.colors.blue;
          magenta = theme.colors.magenta;
          cyan = theme.colors.cyan;
          white = theme.colors.brightWhite;
        };
      };

      # Keyboard bindings
      keyboard.bindings = [
        { key = "V"; mods = "Control|Shift"; action = "Paste"; }
        { key = "C"; mods = "Control|Shift"; action = "Copy"; }
        { key = "Insert"; mods = "Control"; action = "Copy"; }
        { key = "Insert"; mods = "Shift"; action = "Paste"; }
        { key = "Plus"; mods = "Control|Shift"; action = "IncreaseFontSize"; }
        { key = "Minus"; mods = "Control|Shift"; action = "DecreaseFontSize"; }
        { key = "Key0"; mods = "Control|Shift"; action = "ResetFontSize"; }
        { key = "PageUp"; mods = "Control|Shift"; action = "ScrollPageUp"; }
        { key = "PageDown"; mods = "Control|Shift"; action = "ScrollPageDown"; }
        { key = "Home"; mods = "Control|Shift"; action = "ScrollToTop"; }
        { key = "End"; mods = "Control|Shift"; action = "ScrollToBottom"; }
        { key = "F"; mods = "Control|Shift"; action = "SearchForward"; }
        { key = "Space"; mods = "Control|Shift"; action = "ToggleViMode"; }
      ];
    };
  };

}
