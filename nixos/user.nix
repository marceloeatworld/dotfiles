{ pkgs, ... }:
{
  users.users.marcelo = {
    isNormalUser = true;
    description = "marcelo";
    extraGroups = [ "networkmanager" "input" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
    #subUidRanges = [{ startUid = 100000; count = 65536; }];
    #subGidRanges = [{ startGid = 100000; count = 65536; }];

  };


}
