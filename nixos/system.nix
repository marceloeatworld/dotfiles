{ inputs, pkgs, lib, ... }:
{
  zramSwap.enable = true;
  time.hardwareClockInLocalTime = true;
  #time.timeZone = "Europe/Paris";

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [ "https://nix-gaming.cachix.org" ];
      trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Override packages
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
  };

  nixpkgs.overlays = [
    inputs.self.overlays.default
    inputs.nur.overlay
  ];

  environment.systemPackages = with pkgs; [
    wget
    git
    helix
    dislocker
    ntfs3g
    rocmPackages.rocm-smi
    rocmPackages.rpp
    #rocmPackages.rdc
  ];
}
