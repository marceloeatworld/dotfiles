# Development tools configuration
{ pkgs, pkgs-unstable, lib, config, ... }:

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
    # NOTE: git is provided by programs.git.enable (git.nix)
    # NOTE: lazygit is provided by programs.lazygit.enable (git.nix)
    git-lfs
    gh

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

    # Modern CLI tools (Rust replacements)
    # NOTE: yazi, dust, gum are in home.nix (general user tools)
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

    # AI/ML tools - llama.cpp local inference
    pkgs-unstable.aichat        # Ultra lightweight CLI chat client (Rust) - Daily use
    # NOTE: llama-cpp package is in environment.systemPackages (configuration.nix)
    # CLI tools available: llama-server, llama-cli, llama-quantize, etc.

    # llm - Quick model launcher for llama.cpp (replaces "ollama run <model>")
    (pkgs.writeShellScriptBin "llm" ''
      #!/usr/bin/env bash
      MODELS_DIR="$HOME/models"

      # Available models with display names
      declare -A MODEL_NAMES=(
        ["qwen3-8b"]="Qwen3-8B-Q5_K_M.gguf"
        ["qwen3-4b"]="Qwen3-4B-Q8_0.gguf"
        ["dolphin-q4"]="Dolphin-X1-8B-Q4_K_M.gguf"
        ["dolphin-q8"]="Dolphin-X1-8B-Q8_0.gguf"
        ["mediphi"]="MediPhi-Instruct.Q8_0.gguf"
        ["fara"]="Fara-7B-Q8_0.gguf"
        ["bitnet"]="BitNet-2B.gguf"
        ["bitnet-xl"]="BitNet-XL-Q8_0.gguf"
      )

      usage() {
        echo "Usage: llm [model] [extra-args...]"
        echo "       llm                   Chat with default model ($DEFAULT_MODEL)"
        echo "       llm list              List available models"
        echo "       llm server [model]    Start as OpenAI-compatible server"
        echo ""
        echo "Models:"
        for key in dolphin-q8 dolphin-q4 qwen3-8b qwen3-4b fara mediphi bitnet bitnet-xl; do
          local file="''${MODEL_NAMES[$key]}"
          local size=""
          if [ -f "$MODELS_DIR/$file" ]; then
            size=" ($(du -h "$MODELS_DIR/$file" | cut -f1))"
          fi
          echo "  $key  →  $file$size"
        done
      }

      # Default model when no args
      DEFAULT_MODEL="dolphin-q8"

      if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        usage
        exit 0
      fi

      # No args → chat with default model
      if [ -z "$1" ]; then
        set -- "$DEFAULT_MODEL"
      fi

      if [ "$1" = "list" ]; then
        echo "Models in $MODELS_DIR:"
        ls -lh "$MODELS_DIR"/*.gguf 2>/dev/null | awk '{print "  " $NF " (" $5 ")"}'
        exit 0
      fi

      # Server mode
      if [ "$1" = "server" ]; then
        MODEL_KEY="''${2:-$DEFAULT_MODEL}"
        MODEL_FILE="''${MODEL_NAMES[$MODEL_KEY]}"
        if [ -z "$MODEL_FILE" ]; then
          # Try as direct filename
          MODEL_FILE="$MODEL_KEY"
        fi
        MODEL_PATH="$MODELS_DIR/$MODEL_FILE"
        if [ ! -f "$MODEL_PATH" ]; then
          echo "Model not found: $MODEL_PATH"
          exit 1
        fi
        echo "Starting llama-server with $MODEL_FILE..."
        echo "API: http://127.0.0.1:8080/v1"
        exec llama-server -m "$MODEL_PATH" --host 127.0.0.1 --port 8080 -ngl 99 "''${@:3}"
      fi

      # Interactive chat mode
      MODEL_KEY="$1"
      MODEL_FILE="''${MODEL_NAMES[$MODEL_KEY]}"
      if [ -z "$MODEL_FILE" ]; then
        # Try as direct .gguf filename
        if [ -f "$MODELS_DIR/$MODEL_KEY" ]; then
          MODEL_FILE="$MODEL_KEY"
        elif [ -f "$MODEL_KEY" ]; then
          # Full path provided
          exec llama-cli -m "$MODEL_KEY" -ngl 99 --conversation "''${@:2}"
        else
          echo "Unknown model: $MODEL_KEY"
          echo ""
          usage
          exit 1
        fi
      fi

      MODEL_PATH="$MODELS_DIR/$MODEL_FILE"
      if [ ! -f "$MODEL_PATH" ]; then
        echo "Model file not found: $MODEL_PATH"
        exit 1
      fi

      exec llama-cli -m "$MODEL_PATH" -ngl 99 --conversation "''${@:2}"
    '')

    # AI Coding Agents
    opencode          # OpenCode - AI coding agent for terminal

    # Cloud Development
    wrangler          # Cloudflare Workers CLI (from nixpkgs)

    # Reverse Engineering
    ghidra  # NSA SRE suite

    # Documentation
    zeal              # Offline documentation browser (Dash compatible)

    # Database clients
    postgresql        # PostgreSQL client tools (psql, pg_dump, etc.)
  ];
}
