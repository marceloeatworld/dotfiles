# GeForce NOW cloud gaming (browser client, no native Linux app)
#
# Self-contained: a dedicated Chromium used ONLY for GeForce NOW, plus one
# desktop entry. Remove the import in home.nix and delete
# ~/.local/share/geforce-now to fully uninstall.
#
# Design notes:
# - Chromium is the officially supported browser for play.geforcenow.com on
#   Linux. It is installed here only for this launcher; the daily browser
#   stays Brave.
# - Intentionally NOT firejailed: the jail can block gamepad access
#   (/dev/input) and adds latency/memory constraints that hurt a long-lived
#   video stream. The dedicated --user-data-dir keeps this profile isolated
#   from everything else anyway.
# - AcceleratedVideoDecodeLinuxGL = VA-API hardware decode of the H.264/AV1
#   stream on the Radeon 780M (radeonsi, LIBVA_DRIVER_NAME set in
#   amd-optimizations.nix) instead of the CPU. Same proven flag set as the
#   brave-wayland override in security.nix.
{ pkgs, ... }:

let
  geforce-now = pkgs.writeShellScriptBin "geforce-now" ''
    USER_DATA_DIR="$HOME/.local/share/geforce-now"
    ${pkgs.coreutils}/bin/mkdir -p "$USER_DATA_DIR"

    exec ${pkgs.chromium}/bin/chromium \
      --user-data-dir="$USER_DATA_DIR" \
      --app=https://play.geforcenow.com/ \
      --no-first-run \
      --no-default-browser-check \
      --ozone-platform=wayland \
      --ozone-platform-hint=wayland \
      --enable-features=UseOzonePlatform,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL \
      --disable-features=WaylandWpColorManagerV1,UseChromeOSDirectVideoDecoder \
      --enable-gpu-rasterization \
      --enable-zero-copy \
      --enable-smooth-scrolling \
      "$@"
  '';
in
{
  home.packages = [ geforce-now ];

  xdg.desktopEntries.geforce-now = {
    name = "GeForce NOW";
    genericName = "Cloud Gaming";
    comment = "NVIDIA GeForce NOW game streaming";
    exec = "geforce-now";
    icon = "input-gaming"; # generic gamepad icon from system theme
    terminal = false;
    categories = [ "Game" "Network" ];
  };
}
