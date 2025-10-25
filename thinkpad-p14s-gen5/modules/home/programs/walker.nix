# walker.nix - CORRIGÉ
{ inputs, ... }:

{
  imports = [
    inputs.walker.homeManagerModules.default
  ];

  programs.walker = {
    enable = true;
    runAsService = true;
    
    config = {
      placeholder = "Search...";
      force_keyboard_focus = true;
    };
  };
}