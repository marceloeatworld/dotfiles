# Qt theme configuration
{ config, pkgs, ... }:

let
  theme = config.theme;
  kvantumThemePackage = pkgs.qt6Packages.qtstyleplugin-kvantum;
in
{
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style = {
      name = "kvantum";
      package = pkgs.libsForQt5.qtstyleplugin-kvantum;
    };
  };

  # Kvantum dark theme configuration
  xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=${theme.appearance.kvantumTheme}
  '';

  # Themes are shipped with the Qt6 package; the Qt5 style plugin only ships
  # the plugin itself on this nixpkgs revision.
  xdg.configFile."Kvantum/${theme.appearance.kvantumTheme}".source =
    "${kvantumThemePackage}/share/Kvantum/${theme.appearance.kvantumTheme}";

  # qtwayland packages needed for Qt apps to run on Wayland
  # Kvantum Qt6 package needed for Qt6 apps (Qt5 pulled by style.package)
  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum
  ];
}
