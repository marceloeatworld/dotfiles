# Hyprland - pinned official flake, no plugins (stability).
#
# Config follows the official Lua recommendation:
#   https://wiki.hypr.land/Configuring/Start/
#
# hyprland.lua is the entrypoint and just `require()`s sibling .lua files.
# Each sibling lives in ~/.config/hypr/ (written by the matching Nix module
# via xdg.configFile) and runs in its own Lua scope, so a syntax error in one
# file does not abort loading of the others.
{ pkgs, inputs, hyprlandPackages, ... }:

let
  hyprlandPkg = hyprlandPackages.hyprland;

  hyprScripts = import ./scripts.nix {
    inherit pkgs hyprlandPkg;
  };
in
{
  imports = [
    ./monitors.nix
    ./autostart.nix
    ./input.nix
    ./look-feel.nix
    ./behavior.nix
    ./keybinds.nix
    ./window-rules.nix
    ./desktop-entries.nix
  ];

  _module.args.hyprScripts = hyprScripts;

  # The Hyprland HM module enables xdg.portal, which points
  # NIX_XDG_DESKTOP_PORTAL_DIR at the user profile and shadows the system
  # portal dir. Without gtk here, FileChooser/OpenURI/Settings backends
  # vanish (Electron apps log "No such interface FileChooser").
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprlandPkg;
    configType = "lua";
    # Disable home-manager systemd integration - conflicts with UWSM
    systemd.enable = false;

    plugins = [
      # hyprlandPlugins.hyprexpo  # DISABLED: known SEGV on AMD iGPU (hyprwm/hyprland-plugins#475)
      # hyprfocus DISABLED 2026-07-08: SEGV in libhyprfocus.so when closing a
      # window (focus handler fires during unmapWindow). Crashed the session
      # twice on Super+Q; watchdog then restarts Hyprland in safe mode.
    ];

    # hyprland.lua entrypoint - load each module in deterministic order.
    # Curves must load before animations (within look-feel); mod must be
    # defined before binds reference it (handled inside keybinds.lua).
    extraConfig = ''
      require("monitors")
      require("autostart")
      require("input")
      require("look-feel")
      require("behavior")
      require("keybinds")
      require("window-rules")
    '';
  };

  # uwsm's wayland-wm@.service inherits systemd's default OOMPolicy=stop: if
  # the kernel OOM killer picks ANY process inside the unit's cgroup (apps
  # spawned by Hyprland autostart, e.g. ferdium), systemd stops the whole unit
  # and the session dies with it. Happened on 2026-08-13: a magick fan-out
  # exhausted RAM, the kernel killed ferdium, systemd tore down Hyprland.
  # continue = only a kill of the main (compositor) process ends the unit.
  xdg.configFile."systemd/user/wayland-wm@.service.d/oom-policy.conf".text = ''
    [Service]
    OOMPolicy=continue
  '';

  # Hyprland-specific packages (core Wayland tools are in system/hyprland.nix)
  home.packages = with pkgs; [
    # ── Hypr ecosystem ──
    hyprpaper # Wallpaper daemon
    inputs.hyprshutdown.packages.${pkgs.stdenv.hostPlatform.system}.default # Graceful shutdown GUI
    hypridle # Idle daemon
    hyprlock # Screen locker
    hyprcursor # Native Hyprland cursor library
    hyprsunset # Blue light filter
    hyprsysteminfo # System info display (GPU, CPU, Hyprland version)
    wl-freeze # Freeze window (SIGSTOP) — pause/resume resource-heavy apps
    # Screenshots (region, window, output) — official hyprwm/contrib.
    # grimblast only needs hyprctl, but it wraps its PATH with nixpkgs' own
    # hyprland. Pointing it at the flake package keeps nixpkgs' hyprland out of
    # the closure entirely; otherwise every nixpkgs bump drags in a second
    # Hyprland that is not on hyprland.cachix.org and must compile from source.
    # Patched to capture windows by geometry (grim -g) instead of by toplevel
    # handle (grim -T): toplevel capture hangs forever on Hyprland 0.56
    # (hyprwm/Hyprland#16109), so clicking a window in `area` or using `active`
    # never returned. Drop the patch once hyprwm/Hyprland#16132 ships.
    ((grimblast.override { hyprland = hyprlandPackages.hyprland; }).overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [ ./grimblast-geometry-capture.patch ];
    }))
    hyprprop # Window property inspector (click to inspect, like xprop)
    hyprmon # TUI monitor configuration (native, replaces nwg-displays)
    # ── Wayland tools ──
    cliphist # Clipboard history manager
    brightnessctl # Brightness control (for hypridle dim)
    # ── Custom scripts ──
    hyprScripts.bluelight-toggle
    hyprScripts.bluelight-off
    hyprScripts.bluelight-auto
    hyprScripts.battery-mode
    hyprScripts.perf-mode
    hyprScripts.touchpad-toggle
    hyprScripts.monitor-toggle
    hyprScripts.hypr-current-workspace-launch
    hyprScripts.ferdium-current-workspace
    hyprScripts.vesktop-current-workspace
    hyprScripts.spotify-current-workspace
    hyprScripts.telegram-current-workspace
    hyprScripts.keepassxc-current-workspace
    hyprScripts.joplin-current-workspace
    hyprScripts.bruno-current-workspace
    hyprScripts.rustdesk-current-workspace
    hyprScripts.perf-mode-auto
    hyprScripts.perf-mode-daemon
    hyprScripts.wifi-manage
    hyprScripts.youtube-toggle
    hyprScripts.youtube-pip-dock-toggle
    hyprScripts.pip-dock-toggle
    hyprScripts.youtube-opacity-daemon
    hyprScripts.twitch-toggle
    hyprScripts.twitch-pip-dock-toggle
    hyprScripts.twitch-opacity-daemon
    hyprScripts.quick-notes
    hyprScripts.sysinfo-panel
    hyprScripts.hypr-keys
    hyprScripts.voice-terminal
    hyprScripts.voice-command
  ];

  # Voice logs (what was heard, what Gemini returned, what ran): keep 7 days
  systemd.user.tmpfiles.rules = [ "d %h/.local/state/voice-terminal 0700 - - 7d" ];
}
