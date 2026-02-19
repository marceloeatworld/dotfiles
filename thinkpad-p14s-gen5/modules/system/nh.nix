# NH - Modern Nix Helper (replaces nixos-rebuild)
{ ... }:

{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";  # Keep 7 days and 5 generations
    # NOTE: Hardcoded path required - programs.nh.flake is a Nix string, not shell expression
    flake = "/home/marcelo/dotfiles/thinkpad-p14s-gen5";
  };
  # NOTE: programs.nh.enable already adds nh to PATH, no need for systemPackages
}
