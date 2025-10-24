# Development tools configuration
{ pkgs, pkgs-unstable, ... }:

{
  # Official Visual Studio Code
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      bbenoist.nix
      ms-python.python
      ms-vscode.cpptools
      rust-lang.rust-analyzer
      tamasfe.even-better-toml
      eamodio.gitlens
      github.copilot
      catppuccin.catppuccin-vsc
    ];

    userSettings = {
      "workbench.colorTheme" = "Catppuccin Mocha";
      "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
      "editor.fontSize" = 13;
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "editor.minimap.enabled" = false;
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "files.autoSave" = "afterDelay";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
    };
  };

  # Development packages
  home.packages = with pkgs; [
    # Version control
    git
    git-lfs
    gh
    lazygit       # Git TUI (beautiful interactive Git)

    # Languages (base compilers)
    python3
    python3Packages.pip
    python3Packages.virtualenv
    nodejs_22
    go
    rustup
    gcc
    clang         # Alternative C/C++ compiler
    gnumake
    cmake

    # Tools
    docker-compose
    lazydocker    # Docker TUI (better than docker ps)
    kubectl
    kubernetes-helm
    terraform
    ansible

    # CLI utilities (Omarchy additions)
    gum           # Beautiful shell scripts
    jq            # JSON processor (already in home.nix but critical)

    # Nix tools only
    nixpkgs-fmt   # Nix formatter
    nil           # Nix LSP (for editing NixOS configs)
    nix-tree      # Visualize dependencies
    nix-index     # Search files
  ];
}
