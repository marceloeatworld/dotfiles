# Git configuration
{ ... }:

{
  programs.git = {
    enable = true;
    userName = "Marcelo";
    userEmail = "20625497+marceloeatworld@users.noreply.github.com";  # Change this!

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
      color.ui = true;
    };

    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = "Catppuccin-mocha";
      };
    };
  };

  # Lazygit TUI
  programs.lazygit = {
    enable = true;
  };
}
