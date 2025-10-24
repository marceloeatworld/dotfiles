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

  # Note: hardware.graphics configured in hardware-configuration.nix

  # Gaming performance optimizations
  programs.gamemode = {
    enable = true;  # Automatic performance mode when gaming
    settings = {
      general = {
        renice = 10;  # Lower nice value for games
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";  # Max performance for Radeon 780M
      };
    };
  };
}
