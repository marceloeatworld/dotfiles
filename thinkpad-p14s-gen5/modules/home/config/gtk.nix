{ pkgs, ... }:

{
  gtk = {
    enable = true;

    theme = {
      name = "Gruvbox-Dark-BL";
      package = pkgs.gruvbox-gtk-theme;
    };

    iconTheme = {
      name = "Yaru-yellow";
      package = pkgs.yaru-theme;
    };

    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    font = {
      name = "Noto Sans";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # Custom GTK3 CSS - Monokai Pro Ristretto theme colors (matching Neovim)
  home.file.".config/gtk-3.0/gtk.css".text = ''
    /* Monokai Pro Ristretto theme - matching Neovim colorscheme */
    /* Colors from gthelding/monokai-pro.nvim with filter = "ristretto" */

    /* Color palette:
     * Background: #2c2525 (dark brown)
     * Foreground: #e6d9db (light beige)
     * Black: #1f1a1a (darker brown)
     * Red: #fd6883
     * Green: #adda78
     * Yellow: #f9cc6c
     * Blue: #85dacc
     * Magenta/Purple: #a8a9eb
     * Cyan: #85dacc
     * Orange: #f38d70
     * Grey: #948a8b
     * Border: #403e41
     */

    /* ============================ */
    /* NEMO FILE MANAGER            */
    /* ============================ */

    .nemo-window {
      background-color: #2c2525;
      color: #e6d9db;
    }

    /* Sidebar */
    .nemo-window .sidebar,
    .nemo-window sidebar {
      background-color: #1f1a1a;
      color: #e6d9db;
    }

    .nemo-window .sidebar:selected,
    .nemo-window sidebar:selected {
      background-color: #f9cc6c;
      color: #2c2525;
      font-weight: bold;
    }

    /* Toolbar */
    .nemo-window toolbar,
    .nemo-window headerbar {
      background-color: #2c2525;
      color: #e6d9db;
      border-bottom: 1px solid #403e41;
    }

    /* Path bar */
    .nemo-window .path-bar button {
      background-color: #403e41;
      color: #e6d9db;
      border: none;
      border-radius: 6px;
      margin: 2px;
    }

    .nemo-window .path-bar button:hover {
      background-color: rgba(249, 204, 108, 0.2);
      color: #f9cc6c;
    }

    .nemo-window .path-bar button:active,
    .nemo-window .path-bar button:checked {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* File/folder list view */
    .nemo-window .view {
      background-color: #2c2525;
      color: #e6d9db;
    }

    .nemo-window .view:selected {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* Icon view */
    .nemo-window iconview {
      background-color: #2c2525;
      color: #e6d9db;
    }

    .nemo-window iconview:selected {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* Scrollbars */
    .nemo-window scrollbar slider {
      background-color: #403e41;
      border-radius: 10px;
    }

    .nemo-window scrollbar slider:hover {
      background-color: #f9cc6c;
    }

    /* Context menu */
    .nemo-window menu,
    .nemo-window .menu {
      background-color: #2c2525;
      color: #e6d9db;
      border: 2px solid rgba(249, 204, 108, 0.5);
      border-radius: 10px;
    }

    .nemo-window menuitem:hover,
    .nemo-window .menuitem:hover {
      background-color: rgba(249, 204, 108, 0.2);
      color: #f9cc6c;
    }

    /* Buttons */
    .nemo-window button {
      background-color: #403e41;
      color: #e6d9db;
      border: none;
      border-radius: 6px;
    }

    .nemo-window button:hover {
      background-color: rgba(249, 204, 108, 0.2);
      color: #f9cc6c;
    }

    .nemo-window button:active {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* Entry/search fields */
    .nemo-window entry {
      background-color: #403e41;
      color: #e6d9db;
      border: 1px solid #f9cc6c;
      border-radius: 6px;
      padding: 6px;
    }

    .nemo-window entry:focus {
      border: 2px solid #f9cc6c;
      background-color: #2c2525;
    }

    /* Status bar */
    .nemo-window statusbar {
      background-color: #1f1a1a;
      color: #e6d9db;
      border-top: 1px solid #403e41;
    }

    /* ============================ */
    /* XED TEXT EDITOR              */
    /* ============================ */

    .xed-window {
      background-color: #2c2525;
      color: #e6d9db;
    }

    /* Sidebar (file browser) */
    .xed-window .sidebar,
    .xed-window sidebar {
      background-color: #1f1a1a;
      color: #e6d9db;
    }

    .xed-window .sidebar:selected,
    .xed-window sidebar:selected {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* Toolbar */
    .xed-window toolbar,
    .xed-window headerbar {
      background-color: #2c2525;
      color: #e6d9db;
      border-bottom: 1px solid #403e41;
    }

    /* Text view (editor area) */
    .xed-window textview,
    .xed-window textview text {
      background-color: #2c2525;
      color: #e6d9db;
      caret-color: #f9cc6c;
    }

    .xed-window textview:selected,
    .xed-window textview text:selected {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* Line numbers */
    .xed-window .line-numbers {
      background-color: #1f1a1a;
      color: #948a8b;
    }

    /* Current line highlight */
    .xed-window .current-line {
      background-color: #403e41;
    }

    /* Scrollbars */
    .xed-window scrollbar slider {
      background-color: #403e41;
      border-radius: 10px;
    }

    .xed-window scrollbar slider:hover {
      background-color: #f9cc6c;
    }

    /* Buttons */
    .xed-window button {
      background-color: #403e41;
      color: #e6d9db;
      border: none;
      border-radius: 6px;
    }

    .xed-window button:hover {
      background-color: rgba(249, 204, 108, 0.2);
      color: #f9cc6c;
    }

    .xed-window button:active {
      background-color: #f9cc6c;
      color: #2c2525;
    }

    /* Search bar */
    .xed-window entry {
      background-color: #403e41;
      color: #e6d9db;
      border: 1px solid #f9cc6c;
      border-radius: 6px;
      padding: 6px;
    }

    .xed-window entry:focus {
      border: 2px solid #f9cc6c;
      background-color: #2c2525;
    }

    /* Status bar */
    .xed-window statusbar {
      background-color: #1f1a1a;
      color: #e6d9db;
      border-top: 1px solid #403e41;
    }

    /* Tab bar */
    .xed-window notebook {
      background-color: #2c2525;
    }

    .xed-window notebook tab {
      background-color: #1f1a1a;
      color: #948a8b;
      border: none;
      padding: 8px 12px;
    }

    .xed-window notebook tab:checked {
      background-color: #2c2525;
      color: #f9cc6c;
      font-weight: bold;
    }

    .xed-window notebook tab:hover {
      background-color: #403e41;
      color: #e6d9db;
    }

    /* Context menu */
    .xed-window menu,
    .xed-window .menu {
      background-color: #2c2525;
      color: #e6d9db;
      border: 2px solid rgba(249, 204, 108, 0.5);
      border-radius: 10px;
    }

    .xed-window menuitem:hover,
    .xed-window .menuitem:hover {
      background-color: rgba(249, 204, 108, 0.2);
      color: #f9cc6c;
    }
  '';

  home.packages = with pkgs; [
    gruvbox-gtk-theme
    yaru-theme           # Yaru-yellow icon theme
    bibata-cursors
  ];
}