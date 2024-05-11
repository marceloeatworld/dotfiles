{ self, inputs, pkgs, lib, ... }:

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
#  nixpkgs = {
 #   overlays = [
  #   self.overlays.default
   #   inputs.nur.overlay
   #];
  #};
  environment.systemPackages = with pkgs; [
    wget
    git
    helix
    dislocker
    ntfs3g
rocmPackages.rocm-smi
rocmPackages.rpp
#rocmPackages.rdc
rocmPackages.clr
rocmPackages.rccl
#cups-brother-hll2350dw
oterm
alejandra
  ];
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "fr_FR.UTF-8/UTF-8"
  ];
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
  };
}


