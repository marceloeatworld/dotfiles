# Brave browser flags configuration
# Optimized for Wayland/Hyprland
{ config, lib, ... }:

{
  # Brave flags file
  home.file.".config/brave-flags.conf".text = ''
    # Wayland support (native)
    --ozone-platform=wayland
    --ozone-platform-hint=wayland

    # Enable features
    --enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,WaylandWindowDecorations

    # Disable problematic features
    --disable-features=WaylandWpColorManagerV1

    # Hardware acceleration
    --enable-gpu-rasterization
    --enable-zero-copy

    # Performance
    --enable-smooth-scrolling

    # Privacy (optional - uncomment if desired)
    # --disable-webrtc-apm-in-audio-service
  '';
}
