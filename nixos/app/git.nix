{ pkgs, ... }: 
{
  programs.git = {
    enable = true;
    
    userName = "marceloeatworld";
    userEmail = "20625497+marceloeatworld@users.noreply.github.com";
    
    extraConfig = { 
      init.defaultBranch = "main";
      credential.helper = "store";
    };
  };

  home.packages = [ pkgs.gh pkgs.git-lfs ];
}
