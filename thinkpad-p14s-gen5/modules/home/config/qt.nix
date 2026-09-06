# Qt theme configuration
{ config, pkgs, ... }:

let
  theme = config.theme;
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

  # Build-time fallback; theme-switch relinks this file to the runtime theme's
  # kvantum.kvconfig at activation. The per-theme Kvantum theme directories
  # (stock theme + theme selection colors) are generated in runtime-theme.nix.
  xdg.configFile."Kvantum/kvantum.kvconfig" = {
    force = true;
    text = ''
      [General]
      theme=${theme.appearance.kvantumTheme}-${theme.name}
    '';
  };

  # qtwayland packages needed for Qt apps to run on Wayland
  # Kvantum Qt6 package needed for Qt6 apps (Qt5 pulled by style.package)
  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum
  ];
}
