# ProtonVPN GUI
# Note: proton-core bcrypt test fix applied globally in flake.nix overlays
{ config, pkgs, pkgs-unstable, ... }:

{
  home.packages = [
    pkgs-unstable.protonvpn-gui
  ];
}

