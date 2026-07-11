# Flatpak support
# Used for GeForce Now (com.nvidia.geforcenow) and other sandboxed apps
# unavailable in nixpkgs.
#
# GeForce NOW one-time setup (after first rebuild):
#   flatpak remote-add --user --if-not-exists flathub \
#     https://flathub.org/repo/flathub.flatpakrepo
#   flatpak install --user -y flathub com.nvidia.geforcenow
#
# Required runtime extensions (silences warnings + enables full codec/gamescope
# vulkan-layer support for hardware video decode):
#   flatpak install --user -y flathub \
#     org.freedesktop.Sdk//24.08 \
#     org.freedesktop.Platform.VulkanLayer.gamescope//24.08 \
#     org.freedesktop.Platform.ffmpeg-full//24.08
#
# Host binaries probed via xdg-desktop-portal (wireguard-tools, xrandr)
# are installed system-wide in hosts/thinkpad/configuration.nix. Mesa env
# (LIBVA_DRIVER_NAME=radeonsi, AMD_VULKAN_ICD=RADV) is inherited from the host
# session, so VAAPI hardware decode on the Radeon 780M works inside the
# sandbox without overrides.
#
# Wayland workaround: if the GFN window refuses to open under Hyprland/Wayland,
# fall back to XWayland with:
#   flatpak override --user --nosocket=wayland com.nvidia.geforcenow
# (NVIDIA officially recommends X.org for now; Mesa 24.2+ on AMD usually
# works fine on Wayland.)
#
# Recommended in-app GFN settings on this machine (Ryzen 7 PRO 8840HS +
# Radeon 780M, Mesa 26+, Linux client only does H.264/H.265 — no AV1 yet):
#   - Codec: HEVC (H.265) for best quality/bitrate ratio
#   - Resolution/FPS: 1440p @ 120 FPS for the best general tradeoff
#   - NVIDIA Reflex: ON for competitive games
#   - Wired ethernet preferred over Wi-Fi; target <50 ms latency
{ ... }:

{
  services.flatpak.enable = true;
}
