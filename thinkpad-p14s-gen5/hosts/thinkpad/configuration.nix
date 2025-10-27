# Main system configuration for ThinkPad P14s Gen 5 (AMD)
{ config, pkgs, ... }:

{
  # System hostname
  networking.hostName = "pop";

  # Enable flakes and nix command
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Build optimizations
    max-jobs = "auto";  # Use all cores
    cores = 16;         # 8840HS has 8 cores / 16 threads
    builders-use-substitutes = true;

    # Eval optimizations
    warn-dirty = false;
    eval-cache = true;

    # Cachix for Hyprland + community caches (prevents rebuilding)
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"  # Devenv and dev tools
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };

  # Garbage collection (now managed by NH)
  # NH handles garbage collection with smarter logic
  # See modules/system/nh.nix for configuration
  nix.gc = {
    automatic = false;  # Disabled - NH manages this
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    neofetch
    usbutils
    pciutils
  ];

  # Enable documentation
  documentation.enable = true;
  documentation.man.enable = true;
  documentation.dev.enable = true;

  # This value determines the NixOS release with which your system is compatible
  # DON'T CHANGE THIS unless you know what you're doing
  system.stateVersion = "25.05";
}
