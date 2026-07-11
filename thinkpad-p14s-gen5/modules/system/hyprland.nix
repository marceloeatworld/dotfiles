# Hyprland Wayland Compositor Configuration
{ pkgs, inputs, hyprlandPackages, ... }:

let
  hyprlandPkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Keep Mesa in sync with the Hyprland flake input. Hyprland's Nix docs call
  # out Mesa mismatches as a common cause of FPS drops/stutter with games.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = hyprlandPkgs.mesa;
    package32 = hyprlandPkgs.pkgsi686Linux.mesa;
  };

  # Enable Hyprland with UWSM.
  # Hyprland itself is pinned in flake.nix for session stability.
  programs.hyprland = {
    enable = true;
    withUWSM = true; # Universal Wayland Session Manager - recommended
    xwayland.enable = true;
    package = hyprlandPackages.hyprland; # Official flake, unmodified for cachix hits
    portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
  };

  # XDG Desktop Portal configuration
  xdg.portal = {
    enable = true;
    wlr.enable = false; # Disabled - use Hyprland's own portal instead
    xdgOpenUsePortal = false; # Disabled - hyprland portal doesn't fully support OpenURI
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ]; # Use GTK for opening URIs
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ]; # Use GTK for settings (theme detection)
      };
    };
  };

  # Environment variables for Wayland
  # NOTE: XDG_CURRENT_DESKTOP, XDG_SESSION_TYPE, XDG_SESSION_DESKTOP are set by UWSM automatically
  environment.sessionVariables = {
    # Wayland
    NIXOS_OZONE_WL = "1"; # Electron apps use Wayland
    MOZ_ENABLE_WAYLAND = "1"; # Firefox uses Wayland

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

  # Polkit authentication agent launched at session start in Hyprland config
  # (see modules/home/programs/hyprland/autostart.nix)

  # Freeze Hyprland before suspend to prevent GPU access during s2idle transition
  # Prevents SEGV crashes caused by Hyprland touching stale DRM/GPU state
  # Reference: https://github.com/0xFMD/hyprland-suspend-fix
  systemd.services.hyprland-suspend = {
    description = "Freeze Hyprland before suspend";
    before = [ "systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service" ];
    wantedBy = [ "systemd-suspend.service" "systemd-hibernate.service" "systemd-suspend-then-hibernate.service" ];
    serviceConfig = {
      Type = "oneshot";
      # NixOS wraps the binary: the live comm is ".Hyprland-wrapp" (15-char
      # truncation of .Hyprland-wrapped), so the pattern must match the wrapped
      # name too - a bare `-x Hyprland` matches nothing.
      ExecStart = "${pkgs.procps}/bin/pkill -STOP Hyprland";
    };
  };

  systemd.services.hyprland-resume = {
    description = "Unfreeze Hyprland after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      # 4s delay gives GPU/DRM time to reinitialize after s2idle on AMD
      # Increased from 2s — resume freezes observed with shorter delay
      ExecStart = "${pkgs.bash}/bin/bash -c 'sleep 4 && ${pkgs.procps}/bin/pkill -CONT Hyprland'";
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
