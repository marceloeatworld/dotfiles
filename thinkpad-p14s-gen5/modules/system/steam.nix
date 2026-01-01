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

    # Extra packages available in Steam environment
    extraPackages = with pkgs; [
      mangohud       # GPU/CPU overlay for monitoring in games
    ];
  };

  # Gaming packages
  environment.systemPackages = with pkgs; [
    mangohud       # Also available outside Steam
    # Usage: mangohud %command% in Steam launch options
    # Or: MANGOHUD=1 game-executable
  ];

  # Note: GameMode is configured in performance.nix (with notifications)
  # Note: hardware.graphics configured in hardware-configuration.nix
}
