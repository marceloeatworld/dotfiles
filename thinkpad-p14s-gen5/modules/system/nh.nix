# NH - Modern Nix Helper (replaces nixos-rebuild)
{ pkgs, ... }:

{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";  # Keep 7 days and 5 generations
    flake = "/home/marcelo/dotfiles/thinkpad-p14s-gen5";
  };

  # Add nh to system packages (for manual usage)
  environment.systemPackages = with pkgs; [
    nh
  ];
}
