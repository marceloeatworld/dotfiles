{ pkgs, ... }: 
{
  programs.git = {
    enable = true;
    
    userName = "marceloeatworld";
    userEmail = "marcelo.pereira@meucartao.pt";
    
    extraConfig = { 
      init.defaultBranch = "main";
      credential.helper = "store";
    };
  };

  home.packages = [ pkgs.gh pkgs.git-lfs ];
}
