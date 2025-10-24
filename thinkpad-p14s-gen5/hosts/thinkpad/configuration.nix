# Main system configuration for ThinkPad P14s Gen 5 (AMD)
{ config, pkgs, ... }:

{
  # System hostname
  networking.hostName = "pop";

  # Enable flakes and nix command
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Cachix for Hyprland (prevents rebuilding)
    substituters = [
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
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
