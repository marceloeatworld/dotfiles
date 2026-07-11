# Autostart (startup commands) and session environment variables.
{ config, pkgs, hyprScripts, ... }:

let
  theme = config.theme;
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
}
