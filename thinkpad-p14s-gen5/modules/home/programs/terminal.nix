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
      # Font
      font-family = theme.fonts.mono;
      font-size = 10;

      # Window - minimal padding
      window-padding-x = 4;
      window-padding-y = 4;
      window-decoration = false;
      background-opacity = 1;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Theme colors from config/theme.nix
      background = builtins.substring 1 6 theme.colors.background;
      foreground = builtins.substring 1 6 theme.colors.foreground;
      selection-background = builtins.substring 1 6 theme.colors.selection;
      selection-foreground = builtins.substring 1 6 theme.colors.foreground;
      cursor-color = builtins.substring 1 6 theme.colors.yellow;

      # Terminal palette from theme
      palette = [
        "0=${theme.colors.brightBlack}"   # black
        "1=${theme.colors.red}"           # red
        "2=${theme.colors.green}"         # green
        "3=${theme.colors.yellow}"        # yellow
        "4=${theme.colors.blue}"          # blue
        "5=${theme.colors.magenta}"       # magenta
        "6=${theme.colors.cyan}"          # cyan
        "7=${theme.colors.foreground}"    # white
        "8=${theme.colors.comment}"       # bright black
        "9=${theme.colors.red}"           # bright red
        "10=${theme.colors.green}"        # bright green
        "11=${theme.colors.yellow}"       # bright yellow
        "12=${theme.colors.blue}"         # bright blue
        "13=${theme.colors.magenta}"      # bright magenta
        "14=${theme.colors.cyan}"         # bright cyan
        "15=${theme.colors.brightWhite}"  # bright white
      ];

      # Clipboard
      copy-on-select = "clipboard";
      clipboard-paste-protection = false;

      # Mouse
      mouse-hide-while-typing = true;
      link-url = true;

      # Performance
      # gtk-single-instance disabled - can cause blank windows and theme issues
      # when spawning new terminals quickly
      gtk-single-instance = false;

      # Bell - Ghostty uses just "bell" option
      # audible-bell and visual-bell are not valid options

      # Scrollback
      scrollback-limit = 10000;

      # Confirm close
      confirm-close-surface = false;

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
      # Window - minimal padding
      window = {
        padding = { x = 4; y = 4; };
        decorations = "none";
        opacity = 1;
      };

      # Font
      font = {
        normal = { family = theme.fonts.mono; style = "Regular"; };
        size = 10;
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
          cursor = theme.colors.yellow;
        };
        selection = {
          text = theme.colors.foreground;
          background = theme.colors.selection;
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
      ];
    };
  };

}
