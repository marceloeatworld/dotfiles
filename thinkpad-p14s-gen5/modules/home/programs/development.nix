# Development tools configuration
{ pkgs, lib, config, ... }:

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
    # NOTE: llama-cpp package is in environment.systemPackages (configuration.nix)
    # CLI tools available: llama-server, llama-cli, llama-quantize, etc.

    # llm - Quick model launcher for llama.cpp
    # Uses the active model set by llm-switch (symlink ~/models/active-model.gguf)
    # Both models: thinking disabled (--reasoning-budget 0 + --chat-template-kwargs)
    (pkgs.writeShellScriptBin "llm" ''
      #!/usr/bin/env bash
      MODELS_DIR="$HOME/models"
      ACTIVE="$MODELS_DIR/active-model.gguf"

      # Available models (alias → filename)
      declare -A MODEL_NAMES=(
        ["4b"]="Qwen3.5-4B-Q4_K_M.gguf"
        ["9b"]="Qwen3.5-9B-Uncensored-Q4_K_M.gguf"
      )

      usage() {
        echo "Usage: llm [model] [extra-args...]"
        echo "       llm              Chat with active model (set by llm-switch)"
        echo "       llm 4b           Chat with Qwen3.5-4B (thinking enabled)"
        echo "       llm 9b           Chat with Qwen3.5-9B Uncensored (no thinking)"
        echo "       llm list         List available models"
        echo "       llm server       Start OpenAI-compatible API server"
        echo ""
        echo "Active model: $(basename "$(readlink "$ACTIVE" 2>/dev/null)" 2>/dev/null || echo "none")"
      }

      # Resolve model: alias → path
      resolve_model() {
        local key="$1"
        if [ -n "''${MODEL_NAMES[$key]}" ]; then
          echo "$MODELS_DIR/''${MODEL_NAMES[$key]}"
          return 0
        fi
        if [ -f "$MODELS_DIR/$key" ]; then
          echo "$MODELS_DIR/$key"
          return 0
        fi
        if [ -f "$key" ]; then
          echo "$key"
          return 0
        fi
        return 1
      }

      # Common flags for all models
      # Use custom template that forces empty <think></think> to reliably disable thinking
      COMMON_FLAGS=(-ngl 99 --temp 0.7 --top-p 0.8 --top-k 20 --no-mmap --jinja --chat-template-file "$MODELS_DIR/qwen3.5-no-think.jinja")

      case "''${1:-}" in
        help|--help|-h)
          usage
          exit 0
          ;;
        list)
          echo "Models in $MODELS_DIR:"
          ls -lh "$MODELS_DIR"/*.gguf 2>/dev/null | grep -v active-model | awk '{print "  " $NF " (" $5 ")"}'
          echo ""
          echo "Active: $(basename "$(readlink "$ACTIVE" 2>/dev/null)" 2>/dev/null || echo "none")"
          exit 0
          ;;
        server)
          MODEL_PATH="''${2:-$ACTIVE}"
          [ -n "''${MODEL_NAMES[''${2:-}]}" ] && MODEL_PATH="$MODELS_DIR/''${MODEL_NAMES[$2]}"
          [ ! -f "$MODEL_PATH" ] && { echo "Model not found. Run: llm-switch 4b"; exit 1; }
          echo "Starting llama-server with $(basename "$MODEL_PATH")..."
          echo "API: http://127.0.0.1:8080/v1"
          exec llama-server -m "$MODEL_PATH" --host 127.0.0.1 --port 8080 "''${COMMON_FLAGS[@]}" "''${@:3}"
          ;;
        *)
          # Determine model path
          if [ -n "''${1:-}" ] && resolve_model "$1" > /dev/null 2>&1; then
            MODEL_PATH=$(resolve_model "$1")
            shift
          else
            MODEL_PATH="$ACTIVE"
          fi
          [ ! -f "$MODEL_PATH" ] && { echo "No active model. Run: llm-switch 4b"; exit 1; }
          exec llama-cli -m "$MODEL_PATH" "''${COMMON_FLAGS[@]}" --conversation "$@"
          ;;
      esac
    '')

    # AI Coding Agents
    opencode          # OpenCode - AI coding agent for terminal

    # Cloud Development
    wrangler          # Cloudflare Workers CLI (from nixpkgs)

    # Reverse Engineering
    ghidra  # NSA SRE suite - wrapped by Firejail in security.nix

    # Documentation
    zeal              # Offline documentation browser (Dash compatible)

    # Database clients
    postgresql        # PostgreSQL client tools (psql, pg_dump, etc.)
  ];
}
