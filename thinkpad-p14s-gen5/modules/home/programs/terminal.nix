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
      # Theme - Catppuccin Mocha
      foreground = "#CDD6F4";
      background = "#1E1E2E";
      selection_foreground = "#1E1E2E";
      selection_background = "#F5E0DC";

      # Cursor (block style)
      cursor = "#F5E0DC";
      cursor_text_color = "#1E1E2E";
      cursor_shape = "block";
      cursor_blink_interval = 0;  # No blinking

      # URL underline color
      url_color = "#F5E0DC";

      # Window (Omarchy-style padding)
      window_padding_width = 14;  # Increased from 8 to 14 (Omarchy)
      window_padding_height = 14;
      hide_window_decorations = true;
      confirm_os_window_close = 0;
      background_opacity = "0.95";
      resize_draw_strategy = "static";  # No resize notifications

      # Tab bar (positioned at bottom)
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_edge = "bottom";
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";
      active_tab_foreground = "#11111B";
      active_tab_background = "#CBA6F7";
      inactive_tab_foreground = "#CDD6F4";
      inactive_tab_background = "#181825";

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
      # Catppuccin Mocha color scheme
      color0 #45475A
      color1 #F38BA8
      color2 #A6E3A1
      color3 #F9E2AF
      color4 #89B4FA
      color5 #F5C2E7
      color6 #94E2D5
      color7 #BAC2DE
      color8 #585B70
      color9 #F38BA8
      color10 #A6E3A1
      color11 #F9E2AF
      color12 #89B4FA
      color13 #F5C2E7
      color14 #94E2D5
      color15 #A6ADC8
    '';
  };

  # Font packages
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "Hack" ]; })
  ];
}
