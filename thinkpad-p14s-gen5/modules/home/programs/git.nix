# Git configuration
{ ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Marcelo";
        email = "20625497+marceloeatworld@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "nvim";
      color.ui = true;
    };
  };

  # Delta diff viewer (separate module in home-manager 25.11)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Catppuccin-mocha";
    };
  };

  # Lazygit TUI
  programs.lazygit = {
    enable = true;
  };
}
