{ pkgs, ... }:

{
  gtk = {
    enable = true;

    # Adwaita-dark - Simple, clean, and very dark (GNOME default)
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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
      gtk-enable-animations = true;
      gtk-decoration-layout = "menu:";
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-decoration-layout = "menu:";
    };
  };

  home.pointerCursor = {
    gtk.enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
  };

  # GTK3 CSS - Light customizations on top of Catppuccin
  home.file.".config/gtk-3.0/gtk.css".text = ''
    /* Catppuccin Mocha with custom tweaks */

    /* Disable backdrop dimming effects */
    * {
      -gtk-icon-effect: none;
    }

    *:backdrop {
      opacity: 1.0;
    }
  '';
}
