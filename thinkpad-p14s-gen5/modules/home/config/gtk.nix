{ pkgs, config, ... }:

let
  theme = config.theme;
  runtimeThemePath = "${config.home.homeDirectory}/.config/theme/current";
  runtimeLink = path: config.lib.file.mkOutOfStoreSymlink "${runtimeThemePath}/${path}";
in
{
  # GTK settings are runtime links, not static Home Manager files. This lets
  # Nemo and other GTK apps follow theme-switch without a rebuild.
  home.packages = with pkgs; [
    bibata-cursors
    yaru-theme
  ];

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    name = theme.appearance.cursorTheme;
    package = pkgs.bibata-cursors;
    size = theme.appearance.cursorSize;
  };

  home.file = {
    ".gtkrc-2.0".source = runtimeLink "gtkrc-2.0";
    ".config/gtk-3.0/settings.ini".source = runtimeLink "gtk-3.0-settings.ini";
    ".config/gtk-4.0/settings.ini".source = runtimeLink "gtk-4.0-settings.ini";
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
