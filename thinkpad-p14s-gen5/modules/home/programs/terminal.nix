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

      # Window
      window-padding-x = 14;
      window-padding-y = 14;
      window-decoration = false;
      background-opacity = 1;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Theme - Monokai Pro Ristretto (from theme.nix)
      background = builtins.substring 1 6 theme.colors.background;
      foreground = builtins.substring 1 6 theme.colors.foreground;
      selection-background = "3d2f2a";
      selection-foreground = builtins.substring 1 6 theme.colors.foreground;
      cursor-color = builtins.substring 1 6 theme.colors.yellow;

      # Monokai Pro Ristretto palette (from theme.nix)
      palette = [
        "0=${theme.colors.brightBlack}"   # black
        "1=${theme.colors.red}"           # red
        "2=${theme.colors.green}"         # green
        "3=${theme.colors.yellow}"        # yellow
        "4=${theme.colors.orange}"        # blue (orange in Ristretto)
        "5=${theme.colors.magenta}"       # magenta
        "6=${theme.colors.cyan}"          # cyan
        "7=${theme.colors.foreground}"    # white
        "8=#948a8b"                        # bright black
        "9=#ff8297"                        # bright red
        "10=#c8e292"                       # bright green
        "11=#fcd675"                       # bright yellow
        "12=#f8a788"                       # bright blue
        "13=#bebffd"                       # bright magenta
        "14=#9bf1e1"                       # bright cyan
        "15=${theme.colors.brightWhite}"  # bright white
      ];

      # Clipboard
      copy-on-select = "clipboard";
      clipboard-paste-protection = false;

      # Mouse
      mouse-hide-while-typing = true;
      link-url = true;

      # Performance
      gtk-single-instance = true;

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
        # Split management
        "ctrl+shift+enter=new_split:down"
        "ctrl+shift+backslash=new_split:right"
        "ctrl+shift+]=goto_split:next"
        "ctrl+shift+[=goto_split:previous"
        # Font size
        "ctrl+shift+equal=increase_font_size:1"
        "ctrl+shift+minus=decrease_font_size:1"
        "ctrl+shift+zero=reset_font_size"
        # Scrollback
        "ctrl+shift+up=scroll_page_up"
        "ctrl+shift+down=scroll_page_down"
        "ctrl+shift+home=scroll_to_top"
        "ctrl+shift+end=scroll_to_bottom"
      ];
    };
  };

  # ============================================
  # ALACRITTY - Backup terminal (simple, fast)
  # ============================================
  programs.alacritty = {
    enable = true;
    settings = {
      # Window
      window = {
        padding = { x = 14; y = 14; };
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

      # Monokai Pro Ristretto color scheme (matching Ghostty, btop, system)
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
          background = "#3d2f2a";
        };
        normal = {
          black = theme.colors.comment;
          red = theme.colors.red;
          green = theme.colors.green;
          yellow = theme.colors.yellow;
          blue = "#f38d70";
          magenta = theme.colors.magenta;
          cyan = theme.colors.cyan;
          white = theme.colors.foreground;
        };
        bright = {
          black = "#948a8b";
          red = "#ff8297";
          green = "#c8e292";
          yellow = "#fcd675";
          blue = "#f8a788";
          magenta = "#bebffd";
          cyan = "#9bf1e1";
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
