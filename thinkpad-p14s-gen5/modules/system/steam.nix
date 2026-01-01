# Steam gaming platform
{ pkgs, ... }:

{
  # Steam with Proton for Windows games compatibility
  programs.steam = {
    enable = true;

    # Proton GE (community version with better compatibility)
    gamescopeSession.enable = true;

    # Additional packages for better game support
    extraCompatPackages = with pkgs; [
      proton-ge-bin  # Proton GE for better Windows game compatibility
    ];
  };

  # Note: GameMode is configured in performance.nix (with notifications)
  # Note: hardware.graphics configured in hardware-configuration.nix
}
