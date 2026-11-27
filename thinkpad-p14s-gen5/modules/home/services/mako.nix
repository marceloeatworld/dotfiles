# Mako notification daemon configuration
{ config, lib, ... }:

let
  themeConfigs = import ../lib/theme-configs.nix { inherit lib; };
in
{
  services.mako.enable = true;

  # Build-time fallback; theme-switch relinks ~/.config/mako/config to the
  # runtime theme's copy. Both come from theme-configs.nix.
  xdg.configFile."mako/config" = {
    force = lib.mkForce true;
    text = themeConfigs.makoConf config.theme;
  };

  # The package-shipped mako.service is never wanted by the session (empty
  # WantedBy) and its WAYLAND_DISPLAY ExecCondition skipped it at login, so
  # mako ran unsupervised via D-Bus activation. This unit shadows it and is
  # pulled in by graphical-session.target, which under UWSM only activates
  # after WAYLAND_DISPLAY is imported (same pattern as waybar/swayosd).
  systemd.user.services.mako = {
    Unit = {
      Description = "mako notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${config.services.mako.package}/bin/mako";
      ExecReload = "${config.services.mako.package}/bin/makoctl reload";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
