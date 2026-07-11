# Mako notification daemon configuration
{ config, lib, ... }:

let
  theme = config.theme;
in
{
  xdg.configFile."mako/config".force = lib.mkForce true;

  services.mako = {
    enable = true;

    # Use settings instead of deprecated extraConfig (NixOS 25.05)
    settings = {
      # Minimal with colored accent borders
      background-color = theme.colors.backgroundAlt;
      text-color = theme.colors.foreground;
      border-color = theme.colors.accent;
      progress-color = "over ${theme.colors.surface}";

      # Subtle rounding, accent left border
      border-radius = 6;
      border-size = 2;
      width = 360;
      height = 150;
      max-visible = 3;
      margin = "8";
      padding = "14";

      default-timeout = 4000;
      ignore-timeout = false;

      font = "${theme.fonts.mono} 10"; # Keep in sync with runtime-theme.nix makoConf

      # Minimal icons
      icons = true;
      max-icon-size = 32;
      icon-location = "left";

      actions = true;
      group-by = "app-name";
      format = "<b>%s</b>\\n%b";

      layer = "overlay";
      anchor = "top-right";

      # Low urgency - dim border, shorter timeout
      "urgency=low" = {
        default-timeout = 2000;
        border-color = theme.colors.border;
      };

      # Normal urgency - green accent (default above)

      # High urgency - red border, persistent
      "urgency=high" = {
        border-color = theme.colors.red;
        default-timeout = 0;
      };

      # SwayOSD - quick dismiss
      "app-name=SwayOSD" = {
        default-timeout = 1000;
        group-by = "app-name";
      };
    };
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
