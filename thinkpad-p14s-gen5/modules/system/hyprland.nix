# Hyprland Wayland Compositor Configuration
{ pkgs, inputs, ... }:

{
  # NOTE: Mesa synchronization with Hyprland disabled - causes Kitty/OpenGL crashes
  # If you need it for games, re-enable, but it may break terminal emulators
  # hardware.graphics.package = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.system}.mesa;

  # Enable 32-bit graphics support (required for Steam and 32-bit games)
  hardware.graphics.enable32Bit = true;

  # Enable Hyprland (without UWSM - recommended for most users per official docs)
  programs.hyprland = {
    enable = true;
    withUWSM = false;  # UWSM disabled - "for the majority of users, it's recommended to use Hyprland without it"
    xwayland.enable = true;

    # Use flake version (required for plugins and latest features)
    # IMPORTANT: Both NixOS and Home Manager must use the SAME source!
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
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
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # Clutter
    CLUTTER_BACKEND = "wayland";

    # SDL
    SDL_VIDEODRIVER = "wayland";

    # Java
    _JAVA_AWT_WM_NONREPARENTING = "1";
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;

  # Polkit authentication agent
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
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

    # Portal
    xdg-utils
  ];
}
