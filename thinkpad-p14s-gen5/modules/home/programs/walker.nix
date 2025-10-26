# walker.nix - With Ristretto theme
{ inputs, ... }:

{
  imports = [
    inputs.walker.homeManagerModules.default
  ];

  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      placeholder = "Search...";
      force_keyboard_focus = true;

      # Module configurations
      modules = {
        calc = {
          async = false;
        };

        desktopapplications = {
          show_actions = false;
          only_search_title = true;
          history = false;
        };
      };
    };
  };

  # Ristretto theme for Walker
  xdg.configFile."walker/style.css".text = ''
    /* Ristretto color palette */
    @define-color selected-text #fabd2f;
    @define-color text #e6d9db;
    @define-color base #2c2525;
    @define-color border #e6d9db;
    @define-color foreground #e6d9db;
    @define-color background #2c2525;

    /* Main window */
    window {
      background-color: alpha(@background, 0.95);
      border: 2px solid @border;
      border-radius: 12px;
    }

    /* Input field */
    #input {
      background-color: alpha(@base, 0.9);
      color: @foreground;
      border: 1px solid @border;
      border-radius: 8px;
      padding: 12px;
      font-size: 14px;
      margin: 10px;
    }

    /* List items */
    #item {
      color: @text;
      padding: 8px 12px;
      border-radius: 6px;
    }

    /* Selected/hovered item */
    #item:selected,
    #item:hover {
      background-color: alpha(@selected-text, 0.2);
      color: @selected-text;
    }

    /* Item text */
    #text {
      color: @text;
    }

    #text:selected {
      color: @selected-text;
    }

    /* Scrollbar */
    scrollbar {
      background-color: alpha(@base, 0.5);
      border-radius: 4px;
    }

    scrollbar slider {
      background-color: alpha(@border, 0.5);
      border-radius: 4px;
    }

    scrollbar slider:hover {
      background-color: @border;
    }
  '';
}