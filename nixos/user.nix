{ pkgs, ... }:
{
  users.users.marcelo = {
    isNormalUser = true;
    description = "marcelo";
    extraGroups = [ "networkmanager" "input" "wheel" "video" "audio" "plugdev" "lp" "udev-acl" ];
    shell = pkgs.zsh;
    #subUidRanges = [{ startUid = 100000; count = 65536; }];
    #subGidRanges = [{ startGid = 100000; count = 65536; }];


  };
users.groups.plugdev = {};

}
