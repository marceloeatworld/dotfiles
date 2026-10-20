# ActivityWatch: automated time tracker, local only (http://localhost:5600).
# aw-server-rust stores the events; awatcher reports the active window and
# AFK state on Wayland (wlr-foreign-toplevel + ext-idle-notify, both provided
# by Hyprland). The stock aw-watcher-window is X11-only.
{ pkgs, lib, ... }:

{
  services.activitywatch = {
    enable = true;
    # Server only. The default pkgs.activitywatch bundle also builds the
    # Python aw-qt and X11 watchers, unused here.
    package = pkgs.aw-server-rust;
    watchers.awatcher.package = pkgs.awatcher;
    # Hours-worked summary (today, week, month, per-day table) served by
    # aw-server itself at http://localhost:5600/pages/hours/ so it reads the
    # AFK bucket same-origin. Plain HTML in ./activitywatch-hours.
    settings.custom_static.hours = "${./activitywatch-hours}";
  };

  # The HM module pulls watchers in from default.target, before UWSM imports
  # WAYLAND_DISPLAY into the user manager. Tie the watcher to the graphical
  # session so it starts once the compositor is up (same pattern as mako).
  systemd.user.services.activitywatch-watcher-awatcher = {
    Unit = {
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service.Restart = "on-failure";
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };
}
