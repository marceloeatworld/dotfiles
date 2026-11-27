# Hyprpaper wallpaper configuration
{ pkgs, hyprlandPackages, ... }:

let
  hyprlandPkg = hyprlandPackages.hyprland;
  wallDir = "${hyprlandPkg}/share/hypr";

  # The three wallpapers shipped with Hyprland (wall0/wall1/wall2). wall0 is
  # the login default; the timer below rotates through the set. Each swap
  # exposes one frame of misc.background_color, which is themed, so it no
  # longer reads as a white flash on light themes.
  wallpaperPath = "${wallDir}/wall0.png";
  rotationInterval = "30min";

  wallpaperNext = pkgs.writeShellScriptBin "wallpaper-next" ''
    set -eu
    HYPRCTL="${hyprlandPkg}/bin/hyprctl"
    WALLS=(${wallDir}/wall*.png)
    CURRENT="$("$HYPRCTL" hyprpaper listactive | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.coreutils}/bin/cut -d' ' -f2-)"
    NEXT="''${WALLS[0]}"
    for i in "''${!WALLS[@]}"; do
      if [ "''${WALLS[$i]}" = "$CURRENT" ]; then
        NEXT="''${WALLS[$(( (i + 1) % ''${#WALLS[@]} ))]}"
        break
      fi
    done
    exec "$HYPRCTL" hyprpaper wallpaper ",$NEXT"
  '';
in
{
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    wallpaper {
        monitor =
        path = ${wallpaperPath}
        fit_mode = cover
    }

    # Disable splash
    splash = false

    # Enable IPC for wallpaper switching
    ipc = on
  '';

  home.packages = [ wallpaperNext ];

  systemd.user.services.wallpaper-rotate = {
    Unit.Description = "Switch to the next Hyprland wallpaper";
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperNext}/bin/wallpaper-next";
    };
  };

  systemd.user.timers.wallpaper-rotate = {
    Unit = {
      Description = "Rotate the wallpaper every ${rotationInterval}";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Timer = {
      OnUnitActiveSec = rotationInterval;
      OnStartupSec = rotationInterval;
      Unit = "wallpaper-rotate.service";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
