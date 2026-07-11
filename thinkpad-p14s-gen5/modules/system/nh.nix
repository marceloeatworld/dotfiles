# NH - Modern Nix Helper (replaces nixos-rebuild)
{ ... }:

{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.dates = "Sun 04:30";
    clean.extraArgs = "--keep-since 7d --keep 5"; # Keep 7 days and 5 generations
  };
  systemd.services.nh-clean.serviceConfig = {
    Nice = 10;
    IOSchedulingClass = "idle";
  };
  # NOTE: programs.nh.enable already adds nh to PATH, no need for systemPackages
}
