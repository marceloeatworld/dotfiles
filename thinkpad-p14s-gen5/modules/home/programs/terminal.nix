# Terminal emulator configuration
# Terminal emulators: Ghostty (primary) + Alacritty (backup)
{ pkgs, ... }:

{
  # ============================================
  # GHOSTTY - Primary terminal (modern, fast, compatible)
  # ============================================
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      # Font
      font-family = "JetBrainsMono Nerd Font";
      font-size = 10;

      # Window
      window-padding-x = 14;
      window-padding-y = 14;
      window-decoration = false;
      background-opacity = 0.95;

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Theme - Monokai Pro Ristretto (matching btop, hyprlauncher, waybar)
      background = "2c2421";
      foreground = "e6d9db";
      selection-background = "3d2f2a";
      selection-foreground = "e6d9db";
      cursor-color = "f9cc6c";

      # Monokai Pro Ristretto palette
      palette = [
        "0=#72696a"   # black
        "1=#fd6883"   # red
        "2=#adda78"   # green
        "3=#f9cc6c"   # yellow
        "4=#f38d70"   # blue (orange in Ristretto)
        "5=#a8a9eb"   # magenta
        "6=#85dacc"   # cyan
        "7=#e6d9db"   # white
        "8=#948a8b"   # bright black
        "9=#ff8297"   # bright red
        "10=#c8e292"  # bright green
        "11=#fcd675"  # bright yellow
        "12=#f8a788"  # bright blue
        "13=#bebffd"  # bright magenta
        "14=#9bf1e1"  # bright cyan
        "15=#f1e5e7"  # bright white
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
        "ctrl+shift+enter=new_split:right"
        "ctrl+shift+backslash=new_split:down"
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
        opacity = 0.95;
      };

      # Font
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
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
          background = "#2c2421";
          foreground = "#e6d9db";
        };
        cursor = {
          text = "#2c2421";
          cursor = "#f9cc6c";
        };
        selection = {
          text = "#e6d9db";
          background = "#3d2f2a";
        };
        normal = {
          black = "#72696a";
          red = "#fd6883";
          green = "#adda78";
          yellow = "#f9cc6c";
          blue = "#f38d70";
          magenta = "#a8a9eb";
          cyan = "#85dacc";
          white = "#e6d9db";
        };
        bright = {
          black = "#948a8b";
          red = "#ff8297";
          green = "#c8e292";
          yellow = "#fcd675";
          blue = "#f8a788";
          magenta = "#bebffd";
          cyan = "#9bf1e1";
          white = "#f1e5e7";
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
