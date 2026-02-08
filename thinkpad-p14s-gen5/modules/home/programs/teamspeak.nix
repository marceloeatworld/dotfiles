{ config, pkgs, ... }:

let
  # Override TeamSpeak 6 to beta3.2 (official TeamSpeak servers)
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
    # NOTE: TeamSpeak 3 removed - depends on qtwebengine-5.15.19 (insecure, ~1h30 compile time)
    teamspeak6-beta  # TeamSpeak 6 (pre-compiled binary from official servers)
  ];
}
