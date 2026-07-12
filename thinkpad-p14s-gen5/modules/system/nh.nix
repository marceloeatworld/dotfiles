# NH - Modern Nix Helper (replaces nixos-rebuild)
{ ... }:

{
  programs.nh = {
    enable = true;
    clean.enable = true;
    # A time-based retention window kept hundreds of rapid rebuild generations.
    # Clean every night and retain exactly three rollback-capable generations.
    clean.dates = "daily";
    clean.extraArgs = "--keep 3";
  };
  systemd.services.nh-clean.serviceConfig = {
    Nice = 10;
    IOSchedulingClass = "idle";
  };
  # NOTE: programs.nh.enable already adds nh to PATH, no need for systemPackages
}
