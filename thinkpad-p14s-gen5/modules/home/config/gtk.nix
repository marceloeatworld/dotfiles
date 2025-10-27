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
    /* NEMO FILE MANAGER - SIMPLE   */
    /* ============================ */

    /* Main window - clean and simple */
    .nemo-window {
      background-color: #2c2525;
      color: #e6d9db;
    }

    /* Sidebar - darker for contrast */
    .nemo-window sidebar,
    .nemo-window .sidebar {
      background-color: #1f1a1a;
      color: #e6d9db;
      border-right: 1px solid #403e41;
    }

    .nemo-window sidebar row:selected,
    .nemo-window sidebar .sidebar-row:selected {
      background-color: #f9cc6c;
      color: #1f1a1a;
    }

    /* Toolbar - minimal */
    .nemo-window headerbar,
    .nemo-window toolbar {
      background-color: #1f1a1a;
      color: #e6d9db;
      border-bottom: 1px solid #403e41;
      padding: 4px;
    }

    /* Path bar buttons - simple */
    .nemo-window .path-bar button {
      background-color: transparent;
      color: #e6d9db;
      border: none;
      border-radius: 4px;
      padding: 4px 8px;
      margin: 0 2px;
    }

    .nemo-window .path-bar button:hover {
      background-color: #403e41;
      color: #f9cc6c;
    }

    .nemo-window .path-bar button:checked {
      background-color: #f9cc6c;
      color: #1f1a1a;
    }

    /* File list - clean */
    .nemo-window .view,
    .nemo-window iconview,
    .nemo-window treeview {
      background-color: #2c2525;
      color: #e6d9db;
    }

    .nemo-window .view:selected,
    .nemo-window iconview:selected,
    .nemo-window treeview:selected {
      background-color: #f9cc6c;
      color: #1f1a1a;
    }

    /* Scrollbars - minimal */
    .nemo-window scrollbar {
      background-color: transparent;
    }

    .nemo-window scrollbar slider {
      background-color: #403e41;
      border-radius: 10px;
      min-width: 8px;
      min-height: 8px;
    }

    .nemo-window scrollbar slider:hover {
      background-color: #f9cc6c;
    }

    /* Context menus - clean contrast */
    .nemo-window menu,
    .nemo-window popover {
      background-color: #1f1a1a;
      color: #e6d9db;
      border: 1px solid #f9cc6c;
      border-radius: 8px;
      padding: 4px;
    }

    .nemo-window menuitem {
      background-color: transparent;
      color: #e6d9db;
      padding: 6px 12px;
      border-radius: 4px;
    }

    .nemo-window menuitem:hover {
      background-color: #f9cc6c;
      color: #1f1a1a;
    }

    /* Buttons - simple grey */
    .nemo-window button {
      background-color: #403e41;
      color: #e6d9db;
      border: none;
      border-radius: 4px;
      padding: 6px 12px;
    }

    .nemo-window button:hover {
      background-color: #4a4748;
      color: #f9cc6c;
    }

    .nemo-window button:active {
      background-color: #f9cc6c;
      color: #1f1a1a;
    }

    /* Search bar - clean */
    .nemo-window entry {
      background-color: #1f1a1a;
      color: #e6d9db;
      border: 1px solid #403e41;
      border-radius: 4px;
      padding: 6px;
      caret-color: #f9cc6c;
    }

    .nemo-window entry:focus {
      border-color: #f9cc6c;
    }

    /* Status bar - minimal */
    .nemo-window statusbar {
      background-color: #1f1a1a;
      color: #948a8b;
      border-top: 1px solid #403e41;
      padding: 2px 8px;
      font-size: 0.9em;
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

    /* Buttons - NO WHITE, GREY ONLY */
    .xed-window button {
      background-color: #403e41;  /* Dark grey */
      color: #e6d9db;  /* Light beige text */
      border: 1px solid #403e41;
      border-radius: 6px;
      padding: 6px 12px;
    }

    .xed-window button:hover {
      background-color: #4a4748;  /* Slightly lighter grey */
      color: #f9cc6c;  /* Yellow text on hover */
      border-color: #f9cc6c;
    }

    .xed-window button:active,
    .xed-window button:checked {
      background-color: #f9cc6c;  /* Yellow when pressed */
      color: #1f1a1a;  /* Dark text */
      border-color: #f9cc6c;
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

    /* ============================ */
    /* GLOBAL GTK ELEMENTS          */
    /* (Apply to all GTK apps)      */
    /* ============================ */

    /* Global context menus and popovers - MAXIMUM CONTRAST */
    menu,
    .menu,
    popover.background,
    popover {
      background-color: #1f1a1a;  /* Dark background */
      color: #e6d9db;  /* Light text */
      border: 2px solid #f9cc6c;
      border-radius: 10px;
      padding: 4px;
    }

    menuitem,
    .menuitem,
    modelbutton {
      background-color: transparent;
      color: #e6d9db;  /* Always light text */
      padding: 8px 12px;
      border-radius: 6px;
      min-height: 24px;
    }

    menuitem:hover,
    .menuitem:hover,
    modelbutton:hover {
      background-color: #f9cc6c;  /* Bright yellow background */
      color: #1f1a1a;  /* Dark text for contrast */
      font-weight: bold;
    }

    menuitem:disabled,
    .menuitem:disabled {
      color: #948a8b;
      opacity: 0.5;
    }

    /* Tooltips - IMPROVED CONTRAST */
    tooltip,
    .tooltip {
      background-color: #1f1a1a;
      color: #e6d9db;
      border: 2px solid #f9cc6c;
      border-radius: 8px;
      padding: 8px 12px;
    }

    tooltip label,
    .tooltip label {
      color: #e6d9db;
    }

    /* Dialog windows - IMPROVED CONTRAST */
    dialog,
    .dialog {
      background-color: #2c2525;
      color: #e6d9db;
    }

    dialog headerbar,
    .dialog headerbar {
      background-color: #1f1a1a;
      color: #e6d9db;
      border-bottom: 1px solid #403e41;
    }

    /* File chooser dialogs */
    filechooser {
      background-color: #2c2525;
      color: #e6d9db;
    }

    /* Ensure all text inputs have good contrast */
    entry,
    entry text {
      background-color: #1f1a1a;
      color: #e6d9db;
      border: 2px solid #403e41;
      caret-color: #f9cc6c;
    }

    entry:focus,
    entry:focus text {
      border-color: #f9cc6c;
      color: #e6d9db;  /* Explicit color */
      box-shadow: 0 0 0 1px #f9cc6c;
    }

    entry placeholder {
      color: #948a8b;
    }

    /* Separators */
    separator {
      background-color: #403e41;
      min-height: 1px;
      min-width: 1px;
    }

    /* Global buttons - NO WHITE, GREY ONLY */
    button {
      background-color: #403e41;  /* Dark grey */
      color: #e6d9db;  /* Light beige text */
      border: 1px solid #403e41;
      border-radius: 6px;
      padding: 6px 12px;
    }

    button:hover {
      background-color: #4a4748;  /* Slightly lighter grey */
      color: #f9cc6c;  /* Yellow text */
      border-color: #f9cc6c;
    }

    button:active,
    button:checked {
      background-color: #f9cc6c;  /* Yellow */
      color: #1f1a1a;  /* Dark text */
      border-color: #f9cc6c;
    }

    button:disabled {
      background-color: #2c2525;
      color: #948a8b;  /* Grey text */
      border-color: #2c2525;
      opacity: 0.5;
    }

    /* Context menu - IMPROVED CONTRAST */
    .xed-window menu,
    .xed-window .menu,
    .xed-window menubar,
    .xed-window popover {
      background-color: #1f1a1a;  /* Darker background for better contrast */
      color: #e6d9db;
      border: 2px solid #f9cc6c;
      border-radius: 10px;
      padding: 4px;
    }

    .xed-window menuitem,
    .xed-window .menuitem,
    .xed-window modelbutton {
      background-color: transparent;
      color: #e6d9db;  /* Explicit foreground color */
      padding: 8px 12px;
      border-radius: 6px;
    }

    .xed-window menuitem:hover,
    .xed-window .menuitem:hover,
    .xed-window modelbutton:hover {
      background-color: #f9cc6c;  /* Solid yellow background */
      color: #1f1a1a;  /* Dark text on yellow for maximum contrast */
      font-weight: bold;
    }

    .xed-window menuitem:disabled,
    .xed-window .menuitem:disabled {
      color: #948a8b;  /* Grey for disabled items */
      opacity: 0.5;
    }
  '';

  home.packages = with pkgs; [
    gruvbox-gtk-theme
    yaru-theme           # Yaru-yellow icon theme
    bibata-cursors
  ];
}