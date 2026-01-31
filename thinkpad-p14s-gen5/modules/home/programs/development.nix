# Development tools configuration
{ pkgs, pkgs-unstable, pkgs-ghidra, lib, config, ... }:

{
  # NPM configuration for NixOS
  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "$HOME/.npm-global";
  };

  home.sessionPath = [
    "$HOME/.npm-global/bin"
  ];

  # Development packages
  # VS Code - Latest version from Microsoft (updated via overlays/vscode-latest.nix)
  home.packages = with pkgs; [
    # VS Code Latest - Always the newest release from Microsoft
    # To update: run update-apps or edit overlays/vscode-latest.nix
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
    # Bun wrapped with libstdc++ for NixOS compatibility (fixes sharp, canvas, etc.)
    (pkgs.writeShellScriptBin "bun" ''
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.bun}/bin/bun "$@"
    '')
    go
    rustup
    jdk                # Java Development Kit (latest LTS)
    # .NET SDK 10 (latest)
    dotnetCorePackages.sdk_10_0
    icu                # Required by .NET for globalization support

    # C++ Development (complete modern toolchain)
    gcc              # GCC 14.3.0 - Primary C++ compiler with C++23 support
    gdb              # GDB debugger (essential for C++ debugging)
    gef              # GDB Enhanced Features - better debugging UX
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

    # NOTE: Full clang compiler excluded due to collision with GCC
    # clang-tools (clangd, clang-tidy) is installed separately without collision
    # For full Clang compiler, use: nix shell nixpkgs#clang_19 nixpkgs#lldb

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

    # Language Servers (for Claude Code LSP integration)
    nodePackages.typescript-language-server  # TypeScript/JavaScript LSP
    (lib.lowPrio nodePackages.typescript)    # Low priority to avoid collision with wrangler's bundled typescript
    pyright                                  # Python LSP (Microsoft)
    clang-tools                              # clangd, clang-tidy, clang-format (no collision with GCC)
    csharp-ls          # C# LSP (uses .NET 9 from combined SDK above)

    # AI/ML tools - Ollama TUI clients
    pkgs-unstable.aichat        # Ultra lightweight CLI for Ollama (Rust) - Daily use
    # NOTE: parllama not available in nixpkgs, install via pip if needed:
    # python3 -m pip install --user parllama

    # AI Coding Agents
    opencode          # OpenCode - AI coding agent for terminal (latest from overlay)
    # To update: run update-apps or edit overlays/opencode-latest.nix

    # Cloud Development
    wrangler          # Cloudflare Workers CLI (from nixpkgs)

    # Reverse Engineering
    pkgs-ghidra.ghidra  # NSA SRE suite (pinned nixpkgs - unstable has Gradle 8.12 build issues)

    # Documentation
    zeal              # Offline documentation browser (Dash compatible)

    # Database clients
    postgresql        # PostgreSQL client tools (psql, pg_dump, etc.)
  ];
}
