# Development tools configuration
{ pkgs, pkgs-unstable, config, ... }:

{
  # NPM configuration for NixOS
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  # Home activation scripts
  home.activation.installGeminiCLI = config.lib.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c "
      if ! ${pkgs.nodejs_22}/bin/npm list -g @google/gemini-cli &>/dev/null; then
        echo 'Installing Gemini CLI globally...'
        ${pkgs.nodejs_22}/bin/npm install -g @google/gemini-cli
      else
        echo 'Gemini CLI already installed'
      fi
    "
  '';

  # Development packages
  # VS Code - installed with Nix configuration
  home.packages = with pkgs; [
    # VS Code (FHS version) with native Wayland support
    # FHS version provides better compatibility with binary extensions
    (vscode.fhs.overrideAttrs (oldAttrs: {
      buildInputs = oldAttrs.buildInputs or [];
    }))  # All settings and extensions are managed through GitHub account sync
    # Note: Wayland flags are set via ~/.config/code-flags.conf
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
    jdk24             # Java Development Kit 24 (required for Audiveris 5.7.1)

    # C++ Development (complete modern toolchain)
    gcc              # GCC 14.3.0 - Primary C++ compiler with C++23 support
    gdb              # GDB debugger (essential for C++ debugging)
    gnumake          # Make build system
    cmake            # CMake build system
    ninja            # Ninja build system (faster than Make)
    ccache           # Compiler cache (speeds up recompilation)

    # C++ Code Quality & Analysis
    valgrind         # Memory leak detection and profiling
    cppcheck         # Static analysis tool

    # C++ Libraries & Package Management
    pkg-config       # Library dependency management
    boost            # Boost C++ libraries (commonly used)

    # NOTE: Clang tools excluded due to cpp collision with GCC
    # For Clang features, use: nix shell nixpkgs#clang_19 nixpkgs#lldb nixpkgs#clang-tools
    # Or create a project-specific shell.nix when needed

    # Filesystem & Archive Tools
    squashfsTools    # SquashFS filesystem tools (unsquashfs, mksquashfs for ISO extraction)

    # Tools
    docker-compose
    lazydocker    # Docker TUI (better than docker ps)
    # kubectl         # Kubernetes CLI - REMOVED (not needed)
    # kubernetes-helm # Helm for K8s - REMOVED (not needed)
    # terraform       # Infrastructure as Code - REMOVED (not needed)
    ansible

    # CLI utilities
    gum           # Beautiful shell scripts

    # Modern CLI tools (Rust replacements)
    yazi          # Terminal file manager (modern, replaces ranger/lf)
    dust          # du modern (disk usage visualization)
    duf           # df modern (filesystem display)
    bottom        # btop alternative (faster, Rust)
    procs         # ps modern (colored process list)
    gping         # ping with graph
    bandwhich     # Network monitor (which process uses bandwidth)
    dog           # dig modern (DNS queries)
    tokei         # Lines of code counter (fast)
    sd            # sed modern (simpler syntax)
    choose        # cut/awk modern
    hyperfine     # CLI benchmarking
    ouch          # Compression/decompression (auto-detects format)
    zellij        # tmux modern (Rust, better UX)
    gitui         # TUI Git (alternative to lazygit, faster)
    gh-dash       # GitHub dashboard TUI

    # Nix tools only
    nixpkgs-fmt   # Nix formatter
    nil           # Nix LSP (for editing NixOS configs)
    nix-tree      # Visualize dependencies
    nix-index     # Search files

    # AI/ML tools - Ollama TUI clients
    pkgs-unstable.aichat        # Ultra lightweight CLI for Ollama (Rust) - Daily use
    # NOTE: parllama not available in nixpkgs, install via pip if needed:
    # python3 -m pip install --user parllama

    # Reverse Engineering
    pkgs-unstable.ghidra  # NSA Software Reverse Engineering (SRE) suite - compiled from source (11.4.2)
  ];
}
