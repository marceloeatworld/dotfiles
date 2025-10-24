# Terminal emulator configuration
{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 10;  # Slightly smaller for better screen space (was 11)
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
      cursor_blink_interval = 0;  # No blinking

      # URL underline color
      url_color = "#e6d9db";

      # Window
      window_padding_width = 14;
      window_padding_height = 14;
      hide_window_decorations = true;
      confirm_os_window_close = 0;
      background_opacity = "0.95";
      resize_draw_strategy = "static";

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
      single_instance = true;
    };

    # Keyboard shortcuts (Omarchy-style clipboard bindings)
    keybindings = {
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
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
    '';
  };

  # Font packages
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Hack" ]; })
  ];
}
