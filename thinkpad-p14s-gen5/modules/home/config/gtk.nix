{ pkgs, config, ... }:

let
  theme = config.theme;
in
{
  gtk = {
    enable = true;

    # Yaru variants are selected from config.theme so GTK follows the active theme.
    theme = {
      name = theme.appearance.gtkTheme;
      package = pkgs.yaru-theme;
    };

    iconTheme = {
      name = theme.appearance.iconTheme;
      package = pkgs.yaru-theme;
    };

    cursorTheme = {
      name = theme.appearance.cursorTheme;
      package = pkgs.bibata-cursors;
      size = theme.appearance.cursorSize;
    };

    font = {
      name = theme.fonts.sans;
      size = theme.fonts.sansSize;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-enable-animations = true;
      gtk-decoration-layout = "menu:";
    };

    gtk4 = {
      theme = null;
      extraConfig = {
        gtk-application-prefer-dark-theme = true;
        gtk-decoration-layout = "menu:";
      };
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = theme.appearance.cursorTheme;
    package = pkgs.bibata-cursors;
    size = theme.appearance.cursorSize;
  };

  # GTK3 CSS - Global tweaks + app-specific imports
  home.file.".config/gtk-3.0/gtk.css".text = ''
    /* Global GTK3 tweaks */

    /* Disable backdrop dimming effects */
    * {
      -gtk-icon-effect: none;
    }

    *:backdrop {
      opacity: 1.0;
    }

    /* Import app-specific CSS */
    @import url("nemo.css");
  '';
}
