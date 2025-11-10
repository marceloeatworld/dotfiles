{ config, pkgs, ... }:

let
  # Override TeamSpeak to beta3.2
  teamspeak6-beta = pkgs.teamspeak6-client.overrideAttrs (oldAttrs: rec {
    version = "6.0.0-beta3.2";

    src = pkgs.fetchurl {
      url = "https://files.teamspeak-services.com/pre_releases/client/${version}/teamspeak-client.tar.gz";
      sha256 = "sZrYGonBw3BgUSExovs8GW5E54vhr3i/VR9eH9/qjWM=";
    };
  });
in
{
  home.packages = [
    teamspeak6-beta
  ];
}
