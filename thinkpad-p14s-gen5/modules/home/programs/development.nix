# Development tools configuration
{ pkgs, lib, ... }:

{
  # npm-global removed: claude-code, opencode, codex, forgecode, pnpm are all
  # provided by Nix overlays (home.packages). No global npm installs needed.
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  # Development packages
  home.packages = with pkgs; [
    # Version control
    # NOTE: git is provided by programs.git.enable (git.nix)
    # NOTE: lazygit is provided by programs.lazygit.enable (git.nix)
    git-lfs
    gh

    # Languages (base compilers)
    python313 # Project dependencies are managed with uv
    nodejs_22
    pnpm # Fast Node package manager (latest from overlay)
    # Bun wrapped with libstdc++ for NixOS compatibility (fixes sharp, canvas, etc.)
    (pkgs.writeShellScriptBin "bun" ''
      export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.bun}/bin/bun "$@"
    '')
    go
    rustup
    jdk # Java Development Kit (latest LTS)
    # .NET SDK 10 (latest)
    dotnetCorePackages.sdk_10_0
    icu # Required by .NET for globalization support

    # C++ Development (complete modern toolchain)
    gcc # GCC 14.3.0 - Primary C++ compiler with C++23 support
    gdb # GDB debugger (essential for C++ debugging)
    gef # GDB Enhanced Features - better debugging UX
    gnumake # Make build system
    cmake # CMake build system
    ninja # Ninja build system (faster than Make)
    ccache # Compiler cache (speeds up recompilation)

    # C++ Code Quality & Analysis
    valgrind # Memory leak detection and profiling
    cppcheck # Static analysis tool

    # C++ Libraries & Package Management
    pkg-config # Library dependency management
    boost # Boost C++ libraries (commonly used)

    # NOTE: Full clang compiler excluded due to collision with GCC
    # clang-tools (clangd, clang-tidy) is installed separately without collision
    # For full Clang compiler, use: nix shell nixpkgs#clang_19 nixpkgs#lldb

    # Filesystem & Archive Tools
    squashfsTools # SquashFS filesystem tools (unsquashfs, mksquashfs for ISO extraction)

    # Tools
    podman-compose
    lazydocker # Container TUI (works with Podman via docker-compat socket)
    ansible
    # NOTE: google-cloud-sdk (gcloud) is installed via Firejail wrapper in security.nix

    # Modern CLI tools (Rust replacements)
    # NOTE: yazi, dust, gum are in home.nix (general user tools)
    duf # df modern (filesystem display)
    bottom # btop alternative (faster, Rust)
    procs # ps modern (colored process list)
    gping # ping with graph
    bandwhich # Network monitor (which process uses bandwidth)
    dog # dig modern (DNS queries)
    tokei # Lines of code counter (fast)
    sd # sed modern (simpler syntax)
    choose # cut/awk modern
    hyperfine # CLI benchmarking
    ouch # Compression/decompression (auto-detects format)
    zellij # Verified against locked nixpkgs: rustc 1.94.1 builds zellij 0.44.1
    gitui # TUI Git (alternative to lazygit, faster)
    gh-dash # GitHub dashboard TUI

    # Nix tools only
    nixpkgs-fmt # Nix formatter
    nil # Nix LSP (for editing NixOS configs)
    nix-tree # Visualize dependencies
    nix-index # Search files

    # Language Servers (for Claude Code LSP integration)
    typescript-language-server # TypeScript/JavaScript LSP
    (lib.lowPrio typescript) # Low priority to avoid collision with wrangler's bundled typescript
    pyright # Python LSP (Microsoft)
    clang-tools # clangd, clang-tidy, clang-format (no collision with GCC)
    csharp-ls # C# LSP (uses .NET 9 from combined SDK above)

    # AI/ML tools - llama.cpp local inference
    # NOTE: llama-cpp package is in environment.systemPackages (configuration.nix)
    # CLI tools available: llama-server, llama-cli, llama-quantize, etc.

    # llm - Quick model launcher for llama.cpp
    # Uses the active model set by llm-switch (symlink ~/models/active-model.gguf)
    # Both models: thinking disabled (--reasoning-budget 0 + --chat-template-kwargs)
    (pkgs.writeShellScriptBin "llm" ''
      # Use unified memory — spills into GTT when VRAM is full
      # Prevents display freeze on 9B model (5.6GB > 4GB VRAM shared with Hyprland)
      export GGML_CUDA_ENABLE_UNIFIED_MEMORY="1"

      MODELS_DIR="$HOME/models"
      ACTIVE="$MODELS_DIR/active-model.gguf"

      # Available models (alias → filename)
      declare -A MODEL_NAMES=(
        ["9b"]="Qwen3.5-9B-Uncensored-Q4_K_M.gguf"
        ["opus"]="Qwen3.5-9B-Opus-Reasoning-v2-Q4_K_M.gguf"
        ["ocr"]="GLM-OCR-Q8_0.gguf"
      )
      MMPROJ_OCR="$MODELS_DIR/mmproj-GLM-OCR-Q8_0.gguf"

      usage() {
        echo "Usage: llm [model] [extra-args...]"
        echo "       llm              Chat with active model (set by llm-switch)"
        echo "       llm 9b           Chat with Qwen3.5-9B Uncensored (no thinking)"
        echo "       llm opus         Chat with Qwen3.5-9B Opus Reasoning Distilled v2"
        echo "       llm ocr <image>  OCR an image with GLM-OCR"
        echo "       llm local        Start local llama-cpp API service"
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
      COMMON_FLAGS=(-ngl 99 --temp 0.7 --top-p 0.8 --top-k 20 --no-mmap -c 8192 --jinja --chat-template-file "$MODELS_DIR/qwen3.5-no-think.jinja")

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
        ocr)
          # OCR mode: use GLM-OCR vision model, saves output to .txt next to image
          MODEL_PATH="$MODELS_DIR/''${MODEL_NAMES[ocr]}"
          [ ! -f "$MODEL_PATH" ] && { echo "Model not found: $MODEL_PATH"; echo "Download: wget -P ~/models https://huggingface.co/ggml-org/GLM-OCR-GGUF/resolve/main/GLM-OCR-Q8_0.gguf"; exit 1; }
          [ ! -f "$MMPROJ_OCR" ] && { echo "mmproj not found: $MMPROJ_OCR"; echo "Download: wget -P ~/models https://huggingface.co/ggml-org/GLM-OCR-GGUF/resolve/main/mmproj-GLM-OCR-Q8_0.gguf"; exit 1; }
          IMAGE="''${2:-}"
          [ -z "$IMAGE" ] && { echo "Usage: llm ocr <image> [prompt]"; echo "  llm ocr photo.jpg                    # default: Text Recognition"; echo "  llm ocr doc.png 'Table Recognition:'"; exit 1; }
          [ ! -f "$IMAGE" ] && { echo "File not found: $IMAGE"; exit 1; }
          PROMPT="''${3:-Text Recognition:}"
          OUTPUT="''${IMAGE%.*}.txt"
          echo "OCR: $IMAGE → $OUTPUT (prompt: $PROMPT)"
          llama-mtmd-cli -m "$MODEL_PATH" --mmproj "$MMPROJ_OCR" -ngl 99 --no-mmap -c 8192 --image "$IMAGE" -p "$PROMPT" --temp 0.1 -n 8192 "''${@:4}" | tee "$OUTPUT"
          echo ""
          echo "Saved: $OUTPUT"
          ;;
        local)
          exec /run/current-system/sw/bin/llm-local
          ;;
        server)
          MODEL_PATH="''${2:-$ACTIVE}"
          [ -n "''${MODEL_NAMES[''${2:-}]}" ] && MODEL_PATH="$MODELS_DIR/''${MODEL_NAMES[$2]}"
          [ ! -f "$MODEL_PATH" ] && { echo "Model not found. Run: llm-switch opus"; exit 1; }
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
          [ ! -f "$MODEL_PATH" ] && { echo "No active model. Run: llm-switch opus"; exit 1; }
          exec llama-cli -m "$MODEL_PATH" "''${COMMON_FLAGS[@]}" --conversation "$@"
          ;;
      esac
    '')

    # AI Coding Agents
    opencode # OpenCode - AI coding agent for terminal

    # NOTE: wrangler is installed via Firejail wrapper in security.nix

    # Reverse Engineering
    # NOTE: ghidra is installed via Firejail wrapper in security.nix
    jadx # Android APK/DEX decompiler (used by android-reverse-engineering skill)

    # Database clients
    postgresql # PostgreSQL client tools (psql, pg_dump, etc.)
  ];
}
