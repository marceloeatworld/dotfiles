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
    grimblast # Screenshots (region, window, output) — official hyprwm/contrib
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
    hyprScripts.voice-lang
  ];
}
