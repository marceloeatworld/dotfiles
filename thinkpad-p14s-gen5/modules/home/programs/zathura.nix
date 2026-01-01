# Zathura PDF reader configuration (Ristretto theme)
{ pkgs, ... }:

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
      font = "JetBrainsMono Nerd Font 11";

      # === Ristretto Theme ===
      # Background colors
      default-bg = "#2c2421";
      default-fg = "#e6d9db";

      # Statusbar
      statusbar-fg = "#e6d9db";
      statusbar-bg = "#2c2421";

      # Inputbar
      inputbar-bg = "#2c2421";
      inputbar-fg = "#e6d9db";

      # Notification colors
      notification-bg = "#2c2421";
      notification-fg = "#e6d9db";
      notification-error-bg = "#fd6883";
      notification-error-fg = "#2c2421";
      notification-warning-bg = "#f9cc6c";
      notification-warning-fg = "#2c2421";

      # Highlighting
      highlight-color = "rgba(249, 204, 108, 0.5)";  # Yellow highlight
      highlight-active-color = "rgba(133, 218, 204, 0.5)";  # Cyan active highlight

      # Completion
      completion-bg = "#403e41";
      completion-fg = "#e6d9db";
      completion-group-bg = "#2c2421";
      completion-group-fg = "#adda78";
      completion-highlight-bg = "#403e41";
      completion-highlight-fg = "#f9cc6c";

      # Index mode
      index-bg = "#2c2421";
      index-fg = "#e6d9db";
      index-active-bg = "#403e41";
      index-active-fg = "#f9cc6c";

      # Render options
      render-loading-bg = "#2c2421";
      render-loading-fg = "#e6d9db";

      # Recolor (dark mode for documents)
      recolor = true;
      recolor-darkcolor = "#e6d9db";
      recolor-lightcolor = "#2c2421";
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
