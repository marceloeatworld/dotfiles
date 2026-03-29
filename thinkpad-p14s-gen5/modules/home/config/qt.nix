# Qt theme configuration
{ pkgs, ... }:

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
    theme=KvArcDark
  '';

  xdg.configFile."Kvantum/KvArcDark".source = "${pkgs.libsForQt5.qtstyleplugin-kvantum}/share/Kvantum/KvArcDark";

  # qtwayland packages needed for Qt apps to run on Wayland
  # Kvantum Qt6 package needed for Qt6 apps (Qt5 pulled by style.package)
  home.packages = with pkgs; [
    qt5.qtwayland
    qt6.qtwayland
    qt6Packages.qtstyleplugin-kvantum
  ];
}
