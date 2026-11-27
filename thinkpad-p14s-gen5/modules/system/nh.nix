# NH - Modern Nix Helper (replaces nixos-rebuild)
{ ... }:

{
  programs.nh = {
    enable = true;
    clean.enable = true;
    # A time-based retention window kept hundreds of rapid rebuild generations.
    # Clean every evening and retain exactly three rollback-capable generations.
    # Not "daily" (00:00): the laptop is off at midnight, so the Persistent
    # timer caught up at every boot and ran during login.
    clean.dates = "21:00";
    clean.extraArgs = "--keep 3";
  };
  systemd.services.nh-clean.serviceConfig = {
    Nice = 10;
    IOSchedulingClass = "idle";
  };
  # NOTE: programs.nh.enable already adds nh to PATH, no need for systemPackages
}
