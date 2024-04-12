{ pkgs, ... }:
{
  users.users.marcelo = {
    isNormalUser = true;
    description = "marcelo";
    extraGroups = [ "networkmanager" "input" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
  };


}
