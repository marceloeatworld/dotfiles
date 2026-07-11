# Git configuration
{ pkgs, ... }:

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

      # Use the gh CLI's stored token as git credential helper. Works for
      # both terminal pushes and VS Code's source-control integration, which
      # otherwise silently fails on HTTPS push without a configured helper.
      credential."https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      credential."https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
    };
  };

  # Delta diff viewer (separate module in home-manager 25.11)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "current"; # follow the theme-selector bat theme (~/.config/bat/themes/current.tmTheme)
    };
  };

  # Lazygit TUI
  programs.lazygit = {
    enable = true;
  };
}
