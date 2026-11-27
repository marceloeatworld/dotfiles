# Autostart (startup commands) and session environment variables.
{ config, pkgs, hyprScripts, ... }:

let
  inherit (config) theme;
in
{
  xdg.configFile."hypr/autostart.lua".text = ''
    -- Cursor and GDK settings (system-level has the rest via environment.sessionVariables)
    -- Hyprcursor uses XCursor themes as fallback - Bibata works natively
    hl.env("XCURSOR_THEME", "${theme.appearance.cursorTheme}")
    hl.env("XCURSOR_SIZE", "${toString theme.appearance.cursorSize}")
    hl.env("GDK_BACKEND", "wayland,x11,*")
    hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

    -- Startup commands.
    -- "uwsm app --" launches processes as systemd units for proper session management.
    -- This ensures clean shutdown and prevents stale graphical-session.target on crash.
    -- waybar is started by its own systemd user service (auto-restart on SIGSEGV).
    hl.on("hyprland.start", function()
      -- Hyprland 9927f2e stopped exporting WAYLAND_DISPLAY and
      -- HYPRLAND_INSTANCE_SIGNATURE to systemd when it runs as a systemd unit
      -- (shouldManageSdEnv checks MANAGERPID). Without them uwsm's waitenv
      -- times out after 30s and stops the session.
      hl.exec_cmd("uwsm finalize")
      hl.exec_cmd("uwsm app -- ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent")
      -- mako managed by systemd user service (services/mako.nix); launching it here too
      -- raced two instances for the org.freedesktop.Notifications name.
      -- swayosd-server managed by systemd (services/swayosd.nix)
      hl.exec_cmd("uwsm app -- hyprpaper")
      hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
      hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
      -- hyprlauncher daemon disabled while Super+D uses wofi drun; re-enable
      -- together with the keybind when hyprlauncher gains a browse view.
      -- hl.exec_cmd("uwsm app -- hyprlauncher -d --quiet")
      hl.exec_cmd("uwsm app -- hypridle")
      hl.exec_cmd("audio-init") -- Initialize ALSA mixer for speakers (one-shot)
      hl.exec_cmd("${hyprScripts.bluelight-auto}/bin/bluelight-auto") -- Auto-enable blue light filter at night
      hl.exec_cmd("${hyprScripts.perf-mode-auto}/bin/perf-mode-auto") -- Apply startup perf mode (battery saver on battery, saved mode on AC)
      hl.exec_cmd("uwsm app -- ${hyprScripts.perf-mode-daemon}/bin/perf-mode-daemon") -- Monitor power state
      -- youtube/twitch opacity daemons are lazy: the PiP toggles start them
      -- with the PiP window and they exit when it closes (scripts.nix)
      hl.exec_cmd("sleep 2 && uwsm app -- nm-applet") -- Delay tray applet to avoid "no icon" errors
    end)
  '';

  # autostart.lua runs bluelight-auto only at session start, so a session
  # opened during the day never got the filter. Run it again at 20:00.
  systemd.user.services.bluelight-night = {
    Unit = {
      Description = "Enable the blue light filter at night";
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${hyprScripts.bluelight-auto}/bin/bluelight-auto";
      # The script backgrounds hyprsunset, which must outlive this unit.
      KillMode = "process";
    };
  };
  systemd.user.timers.bluelight-night = {
    Unit.Description = "Enable the blue light filter at 20:00";
    Timer.OnCalendar = "*-*-* 20:00:00";
    Install.WantedBy = [ "timers.target" ];
  };
}
