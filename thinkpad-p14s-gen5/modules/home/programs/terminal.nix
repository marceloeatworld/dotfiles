# Terminal emulator configuration - Kitty (primary) + Alacritty (backup)
{ pkgs, ... }:

{
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

      # Ristretto color scheme
      colors = {
        primary = {
          background = "#2c2525";
          foreground = "#e6d9db";
        };
        cursor = {
          text = "#2c2525";
          cursor = "#c3b7b8";
        };
        selection = {
          text = "#e6d9db";
          background = "#403e41";
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
        { key = "Plus"; mods = "Control"; action = "IncreaseFontSize"; }
        { key = "Minus"; mods = "Control"; action = "DecreaseFontSize"; }
        { key = "Key0"; mods = "Control"; action = "ResetFontSize"; }
      ];
    };
  };

  # ============================================
  # KITTY - Primary terminal
  # ============================================
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;
    };

    settings = {
      # Theme - Ristretto
      foreground = "#e6d9db";
      background = "#2c2525";
      selection_foreground = "#e6d9db";
      selection_background = "#403e41";

      # Cursor (block style)
      cursor = "#c3b7b8";
      cursor_text_color = "#c3b7b8";
      cursor_shape = "block";
      cursor_blink_interval = 0;

      # URL underline color
      url_color = "#e6d9db";

      # Window
      window_padding_width = 14;
      # window_padding_height removed in kitty 0.42+
      hide_window_decorations = true;
      confirm_os_window_close = 0;
      background_opacity = "0.95";
      # resize_draw_strategy removed in kitty 0.42+

      # Tab bar (Ristretto theme)
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_edge = "bottom";
      tab_bar_background = "#404040";
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
      active_tab_foreground = "#2c2525";
      active_tab_background = "#f9cc6c";
      inactive_tab_foreground = "#e6d9db";
      inactive_tab_background = "#2c2525";

      # Border colors (Ristretto)
      active_border_color = "#e6d9db";
      inactive_border_color = "#595959";
      bell_border_color = "#595959";

      # Bell
      enable_audio_bell = false;

      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = true;

      # Remote control & instance
      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty";
      # single_instance removed in kitty 0.42+

      # ========================================
      # MOUSE & CLIPBOARD - NEW/FIXED
      # ========================================
      
      # Auto-copy when selecting with mouse (IMPORTANT!)
      copy_on_select = "clipboard";
      
      # Mouse settings
      mouse_hide_wait = "3.0";
      detect_urls = true;
      url_style = "curly";
      open_url_with = "default";
      url_prefixes = "http https file ftp gemini irc gopher mailto news git";
      
      # Strip trailing spaces when copying
      strip_trailing_spaces = "smart";
      
      # What characters are part of a word (for double-click selection)
      select_by_word_characters = "@-./_~?&=%+#";
      
      # Click interval for double/triple click
      click_interval = "0.5";
      
      # Clipboard control (allow kitty to access clipboard)
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
      
      # rectangle_select_modifiers, terminal_select_modifiers, clear_selection_on_paste
      # removed in kitty 0.42+
    };

    # Keyboard shortcuts
    keybindings = {
      # Copy/Paste - Primary shortcuts
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      
      # Copy/Paste - Alternative (Ctrl+Insert/Shift+Insert)
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
      
      # Copy to selection buffer (for middle-click paste)
      "ctrl+shift+s" = "copy_to_clipboard";
      
      # Select all
      "ctrl+shift+a" = "select_all";
      
      # Clear selection
      "escape" = "clear_selection";
      
      # Scrollback
      "ctrl+shift+up" = "scroll_line_up";
      "ctrl+shift+down" = "scroll_line_down";
      "ctrl+shift+page_up" = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";
      "ctrl+shift+home" = "scroll_home";
      "ctrl+shift+end" = "scroll_end";
      
      # Show scrollback in pager (less)
      "ctrl+shift+h" = "show_scrollback";
      
      # Window management
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+w" = "close_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      
      # Tab management
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+q" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      
      # Font size
      "ctrl+shift+equal" = "increase_font_size";
      "ctrl+shift+minus" = "decrease_font_size";
      "ctrl+shift+0" = "restore_font_size";
    };

    extraConfig = ''
      # Ristretto color scheme
      color0 #72696a
      color1 #fd6883
      color2 #adda78
      color3 #f9cc6c
      color4 #f38d70
      color5 #a8a9eb
      color6 #85dacc
      color7 #e6d9db
      color8 #948a8b
      color9 #ff8297
      color10 #c8e292
      color11 #fcd675
      color12 #f8a788
      color13 #bebffd
      color14 #9bf1e1
      color15 #f1e5e7
      
      # Mouse actions
      # Click URLs to open them
      mouse_map left click ungrabbed mouse_handle_click selection link prompt
      
      # Paste on middle-click
      mouse_map middle release ungrabbed paste_from_selection
      
      # Right-click extends selection
      mouse_map right click ungrabbed mouse_select_command_output
    '';
  };
}
