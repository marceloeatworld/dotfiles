# Hyprland Wayland Compositor Configuration
{ pkgs, pkgs-unstable, inputs, ... }:

{
  # NOTE: hardware.graphics.enable32Bit is in hardware-configuration.nix

  # Enable Hyprland with UWSM (recommended for NixOS 25.11)
  # Using official Hyprland flake for latest version + plugin compatibility
  programs.hyprland = {
    enable = true;
    withUWSM = true;  # Universal Wayland Session Manager - recommended
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;  # Official flake
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # XDG Desktop Portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = false;  # Disabled - use Hyprland's own portal instead
    xdgOpenUsePortal = false;  # Disabled - hyprland portal doesn't fully support OpenURI
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];  # Use GTK for opening URIs
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];  # Use GTK for settings (theme detection)
      };
    };
  };

  # Environment variables for Wayland
  environment.sessionVariables = {
    # Wayland
    NIXOS_OZONE_WL = "1";  # Electron apps use Wayland
    MOZ_ENABLE_WAYLAND = "1";  # Firefox uses Wayland

    # XDG
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";

    # Qt
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # Clutter
    CLUTTER_BACKEND = "wayland";

    # SDL - removed forced wayland: breaks SDL apps without Wayland support
    # SDL auto-detects Wayland when running under a Wayland compositor

    # Java
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Polkit authentication agent (Official Hyprland - uses hyprtoolkit theme)
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprland Polkit Authentication Agent";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # Freeze Hyprland before suspend to prevent GPU access during s2idle transition
  # Prevents SEGV crashes caused by Hyprland touching stale DRM/GPU state
  # Reference: https://github.com/0xFMD/hyprland-suspend-fix
  systemd.services.hyprland-suspend = {
    description = "Freeze Hyprland before suspend";
    before = [ "systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service" ];
    wantedBy = [ "systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.procps}/bin/pkill -STOP -x Hyprland";
    };
  };

  systemd.services.hyprland-resume = {
    description = "Unfreeze Hyprland after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      # 2s delay gives GPU/DRM time to reinitialize after s2idle on AMD
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 2 && ${pkgs.procps}/bin/pkill -CONT -x Hyprland'";
    };
  };

  # Additional Wayland-related packages
  environment.systemPackages = with pkgs; [
    # Wayland tools
    wayland
    wayland-protocols
    wayland-utils
    wl-clipboard
    wl-clipboard-x11

    # Screenshot and screen recording
    grim
    slurp
    wf-recorder

    # Notifications
    libnotify

    # XWayland
    xwayland

    # NOTE: xdg-utils is in configuration.nix (environment.systemPackages)
  ];
}
