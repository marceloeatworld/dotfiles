# Development tools configuration
{ pkgs, pkgs-unstable, ... }:

{
  # NPM configuration for NixOS
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  # Development packages
  # VS Code - installed without Nix configuration (use GitHub account sync instead)
  home.packages = with pkgs; [
    vscode  # All settings and extensions are managed through GitHub account sync
    # Version control
    git
    git-lfs
    gh
    lazygit       # Git TUI (beautiful interactive Git)

    # Languages (base compilers)
    (python313.withPackages (ps: with ps; [
      pip
      virtualenv
      requests        # HTTP requests for API calls (wallet monitor, etc.)
    ]))
    nodejs_22
    go
    rustup
    gcc
    # clang - REMOVED: collision between clang 19 and 14 (gcc is sufficient)
    gnumake
    cmake

    # Tools
    docker-compose
    lazydocker    # Docker TUI (better than docker ps)
    # kubectl         # Kubernetes CLI - REMOVED (not needed)
    # kubernetes-helm # Helm for K8s - REMOVED (not needed)
    # terraform       # Infrastructure as Code - REMOVED (not needed)
    ansible

    # CLI utilities
    gum           # Beautiful shell scripts

    # Nix tools only
    nixpkgs-fmt   # Nix formatter
    nil           # Nix LSP (for editing NixOS configs)
    nix-tree      # Visualize dependencies
    nix-index     # Search files

    # AI/ML tools - Ollama TUI clients
    aichat        # Ultra lightweight CLI for Ollama (Rust) - Daily use
    # NOTE: parllama not available in nixpkgs, install via pip if needed:
    # python3 -m pip install --user parllama
  ];
}
