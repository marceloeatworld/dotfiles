# Terminal emulator configuration
{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    settings = {
      # Theme - Catppuccin Mocha
      foreground = "#CDD6F4";
      background = "#1E1E2E";
      selection_foreground = "#1E1E2E";
      selection_background = "#F5E0DC";

      # Cursor colors
      cursor = "#F5E0DC";
      cursor_text_color = "#1E1E2E";

      # URL underline color
      url_color = "#F5E0DC";

      # Window
      window_padding_width = 8;
      confirm_os_window_close = 0;
      background_opacity = "0.95";

      # Tab bar
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
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
