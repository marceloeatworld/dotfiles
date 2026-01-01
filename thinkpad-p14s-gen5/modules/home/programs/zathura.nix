# Zathura PDF reader configuration (Ristretto theme)
{ config, ... }:

let
  theme = config.theme;
in
{
  programs.zathura = {
    enable = true;

    # Ristretto theme colors
    options = {
      # General settings
      selection-clipboard = "clipboard";
      adjust-open = "best-fit";
      pages-per-row = 1;
      scroll-page-aware = true;
      scroll-full-overlap = "0.01";
      scroll-step = 100;
      zoom-min = 10;
      guioptions = "";  # Hide statusbar and inputbar (minimal UI)
      render-loading = true;
      show-scrollbars = false;

      # Font
      font = "${theme.fonts.mono} ${toString theme.fonts.monoSize}";

      # === Ristretto Theme ===
      # Background colors
      default-bg = theme.colors.background;
      default-fg = theme.colors.foreground;

      # Statusbar
      statusbar-fg = theme.colors.foreground;
      statusbar-bg = theme.colors.background;

      # Inputbar
      inputbar-bg = theme.colors.background;
      inputbar-fg = theme.colors.foreground;

      # Notification colors
      notification-bg = theme.colors.background;
      notification-fg = theme.colors.foreground;
      notification-error-bg = theme.colors.red;
      notification-error-fg = theme.colors.background;
      notification-warning-bg = theme.colors.yellow;
      notification-warning-fg = theme.colors.background;

      # Highlighting
      highlight-color = "rgba(249, 204, 108, 0.5)";  # Yellow highlight
      highlight-active-color = "rgba(133, 218, 204, 0.5)";  # Cyan active highlight

      # Completion
      completion-bg = theme.colors.surface;
      completion-fg = theme.colors.foreground;
      completion-group-bg = theme.colors.background;
      completion-group-fg = theme.colors.green;
      completion-highlight-bg = theme.colors.surface;
      completion-highlight-fg = theme.colors.yellow;

      # Index mode
      index-bg = theme.colors.background;
      index-fg = theme.colors.foreground;
      index-active-bg = theme.colors.surface;
      index-active-fg = theme.colors.yellow;

      # Render options
      render-loading-bg = theme.colors.background;
      render-loading-fg = theme.colors.foreground;

      # Recolor (dark mode for documents)
      recolor = true;
      recolor-darkcolor = theme.colors.foreground;
      recolor-lightcolor = theme.colors.background;
      recolor-keephue = true;
      recolor-reverse-video = true;
    };

    # Keybindings
    mappings = {
      # Navigation
      j = "scroll down";
      k = "scroll up";
      h = "scroll left";
      l = "scroll right";
      J = "scroll half-down";
      K = "scroll half-up";
      gg = "goto top";
      G = "goto bottom";

      # Zoom
      "+" = "zoom in";
      "-" = "zoom out";
      "=" = "zoom in";
      "0" = "adjust_window best-fit";

      # Page navigation
      n = "search forward";
      N = "search backward";
      "<C-n>" = "navigate next";
      "<C-p>" = "navigate previous";

      # View modes
      d = "toggle_page_mode";
      a = "adjust_window best-fit";
      s = "adjust_window width";

      # Recolor toggle (dark/light mode)
      i = "recolor";

      # Fullscreen
      f = "toggle_fullscreen";

      # Index (table of contents)
      "<Tab>" = "toggle_index";

      # Print
      p = "print";

      # Quit
      q = "quit";
      "<Esc>" = "abort";
    };
  };
}
