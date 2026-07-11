# Development tools configuration
{ pkgs, lib, ... }:

let
  headroomPythonPackage = "headroom-ai[proxy,mcp,code]==0.25.0";
  headroomUvArgs = "--no-python-downloads --python ${pkgs.python313}/bin/python3 --from '${headroomPythonPackage}'";
  # Use the newest libstdc++ available (backward compatible with older symbols).
  # stdenv's gcc-15 lib lacks GLIBCXX_3.4.35, and since LD_LIBRARY_PATH leaks to
  # every child of the wrapped agent, it broke newer C++ binaries (hyprctl from
  # the Hyprland flake) inside headroom-claude/codex sessions.
  headroomNativeLibraryPath = lib.makeLibraryPath [
    pkgs.gcc16.cc.lib
  ];
  headroomRuntimeEnv = ''
    export LD_LIBRARY_PATH="${headroomNativeLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export HEADROOM_TELEMETRY="''${HEADROOM_TELEMETRY:-off}"
    export HEADROOM_OPTIMIZE="''${HEADROOM_OPTIMIZE:-1}"
    export HEADROOM_MODE="''${HEADROOM_MODE:-token}"
    export HEADROOM_SAVINGS_PROFILE="''${HEADROOM_SAVINGS_PROFILE:-balanced}"
    export HEADROOM_CODE_AWARE_ENABLED="''${HEADROOM_CODE_AWARE_ENABLED:-1}"
    export HEADROOM_CACHE_ENABLED="''${HEADROOM_CACHE_ENABLED:-1}"
    export HEADROOM_MIN_TOKENS="''${HEADROOM_MIN_TOKENS:-250}"
    export HEADROOM_MAX_ITEMS="''${HEADROOM_MAX_ITEMS:-15}"
    export HEADROOM_DISABLE_KOMPRESS="''${HEADROOM_DISABLE_KOMPRESS:-1}"
    export HEADROOM_OUTPUT_SHAPER="''${HEADROOM_OUTPUT_SHAPER:-0}"
    export HEADROOM_LOG_MESSAGES="''${HEADROOM_LOG_MESSAGES:-false}"
  '';

  headroom = pkgs.writeShellScriptBin "headroom" ''
    ${headroomRuntimeEnv}
    exec ${pkgs.uv}/bin/uvx ${headroomUvArgs} headroom "$@"
  '';

  headroom-claude = pkgs.writeShellScriptBin "headroom-claude" ''
    ${headroomRuntimeEnv}
    exec ${pkgs.uv}/bin/uvx ${headroomUvArgs} headroom wrap claude --no-context-tool --no-serena "$@"
  '';

  headroom-codex = pkgs.writeShellScriptBin "headroom-codex" ''
    ${headroomRuntimeEnv}
    exec ${pkgs.uv}/bin/uvx ${headroomUvArgs} headroom wrap codex --no-context-tool --no-serena "$@"
  '';
in
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
    nodejs-slim_22
    pnpm # Fast Node package manager (latest from overlay)
    # Bun wrapped with libstdc++ for NixOS compatibility (fixes sharp, canvas, etc.)
    # gcc16 lib: newest GLIBCXX symbols, so the leaked LD_LIBRARY_PATH doesn't
    # break newer C++ binaries (hyprctl) in child processes.
    (pkgs.writeShellScriptBin "bun" ''
      export LD_LIBRARY_PATH="${pkgs.gcc16.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
      exec ${pkgs.bun}/bin/bun "$@"
    '')
    go
    rustup
    jdk # Java Development Kit (latest LTS)
    flutter # Flutter SDK (includes the matching Dart SDK)
    # .NET SDK 10 (latest)
    dotnetCorePackages.sdk_10_0
    icu # Required by .NET for globalization support

    # C++ Development (complete modern toolchain)
    gcc # GCC 15.2.0 - Primary C++ compiler with C++23 support
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
    zellij # Verified against locked nixpkgs: rustc 1.95.0 builds zellij 0.44.3
    gitui # TUI Git (alternative to lazygit, faster)
    gh-dash # GitHub dashboard TUI

    # Nix tools only
    nixpkgs-fmt # Nix formatter
    nil # Nix LSP (for editing NixOS configs)
    nix-tree # Visualize dependencies
    statix # Nix static analysis
    deadnix # Detect unused Nix code
    shellcheck # Shell script static analysis
    # NOTE: nix-index is managed by programs.nix-index in shell.nix

    # Language Servers (for Claude Code LSP integration)
    typescript-language-server # TypeScript/JavaScript LSP
    (lib.lowPrio typescript) # Low priority to avoid collision with wrangler's bundled typescript
    pyright # Python LSP (Microsoft)
    clang-tools # clangd, clang-tidy, clang-format (no collision with GCC)
    csharp-ls # C# LSP (uses .NET 10 from combined SDK above)

    # AI/ML tools - llama.cpp local inference
    # NOTE: llama-cpp package is in environment.systemPackages (configuration.nix)
    # CLI tools available: llama-server, llama-cli, llama-quantize, etc.

    # llm - Quick model launcher for llama.cpp
    # Uses the active text model set by llm-switch (symlink ~/models/active-model.gguf)
    # Text models use their GGUF chat template metadata.
    (pkgs.writeShellScriptBin "llm" ''
      MODELS_DIR="$HOME/models"
      ACTIVE="$MODELS_DIR/active-model.gguf"
      LLM_GPU_LAYERS="''${LLM_GPU_LAYERS:-20}"
      LLM_CTX_SIZE="''${LLM_CTX_SIZE:-16384}"
      LLM_TEMP="''${LLM_TEMP:-0.7}"
      LLM_TOP_P="''${LLM_TOP_P:-0.95}"
      LLM_TOP_K="''${LLM_TOP_K:-64}"

      # Available models (alias → filename)
      declare -A MODEL_NAMES=(
        ["qwythos"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["mythos"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["claude-mythos"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["qwen35"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["qwen3.5"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["text"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["default"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["fast"]="Qwythos-9B-Claude-Mythos-5-1M-Q4_K_M.gguf"
        ["gemma"]="gemma4-coding-Q4_K_M.gguf"
        ["gemma4"]="gemma4-coding-Q4_K_M.gguf"
        ["gemma-coder"]="gemma4-coding-Q4_K_M.gguf"
        ["code"]="gemma4-coding-Q4_K_M.gguf"
        ["coding"]="gemma4-coding-Q4_K_M.gguf"
        ["qwopus"]="Qwopus3.6-27B-Coder-MTP-IQ4_XS.gguf"
        ["qwen"]="Qwopus3.6-27B-Coder-MTP-IQ4_XS.gguf"
        ["qwen36"]="Qwopus3.6-27B-Coder-MTP-IQ4_XS.gguf"
        ["qwen3.6"]="Qwopus3.6-27B-Coder-MTP-IQ4_XS.gguf"
        ["heavy"]="Qwopus3.6-27B-Coder-MTP-IQ4_XS.gguf"
        ["devstral"]="Devstral-Small-2507-Q4_K_M.gguf"
        ["agent"]="Devstral-Small-2507-Q4_K_M.gguf"
        ["ocr"]="GLM-OCR-Q8_0.gguf"
      )
      MMPROJ_OCR="$MODELS_DIR/mmproj-GLM-OCR-Q8_0.gguf"

      usage() {
        echo "Usage: llm [model] [extra-args...]"
        echo "       llm              Chat with active model (set by llm-switch)"
        echo "       llm qwythos      Chat with Qwythos 9B Claude Mythos"
        echo "       llm gemma        Chat with Gemma 4 12B Coder"
        echo "       llm qwopus       Chat with Qwopus3.6 27B Coder MTP"
        echo "       llm devstral     Chat with Devstral Small 2507"
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
        if [ -n "''${MODEL_NAMES[$key]:-}" ]; then
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

      # Common flags for local text models. Let GGUF metadata provide the chat template.
      # Conservative GPU offload. Full ROCm offload on the Radeon 780M has
      # caused amdgpu MES hangs and compositor resets with larger local models.
      COMMON_FLAGS=(-ngl "$LLM_GPU_LAYERS" --no-kv-offload --temp "$LLM_TEMP" --top-p "$LLM_TOP_P" --top-k "$LLM_TOP_K" --no-mmap -c "$LLM_CTX_SIZE" --jinja)

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
          ${pkgs.llama-cpp}/bin/llama-mtmd-cli -m "$MODEL_PATH" --mmproj "$MMPROJ_OCR" -ngl "$LLM_GPU_LAYERS" --no-kv-offload --no-mmap -c 8192 --image "$IMAGE" -p "$PROMPT" --temp 0.1 -n 8192 "''${@:4}" | tee "$OUTPUT"
          echo ""
          echo "Saved: $OUTPUT"
          ;;
        local)
          exec /run/current-system/sw/bin/llm-local
          ;;
        server)
          MODEL_PATH="''${2:-$ACTIVE}"
          [ -n "''${MODEL_NAMES[''${2:-}]:-}" ] && MODEL_PATH="$MODELS_DIR/''${MODEL_NAMES[$2]}"
          [ ! -f "$MODEL_PATH" ] && { echo "Model not found. Run: llm-switch qwythos"; exit 1; }
          echo "Starting llama-server with $(basename "$MODEL_PATH")..."
          echo "API: http://127.0.0.1:8080/v1"
          exec ${pkgs.llama-cpp}/bin/llama-server -m "$MODEL_PATH" --host 127.0.0.1 --port 8080 "''${COMMON_FLAGS[@]}" --parallel 1 --cache-ram 0 --no-warmup "''${@:3}"
          ;;
        *)
          # Determine model path
          if [ -n "''${1:-}" ] && resolve_model "$1" > /dev/null 2>&1; then
            MODEL_PATH=$(resolve_model "$1")
            shift
          else
            MODEL_PATH="$ACTIVE"
          fi
          [ ! -f "$MODEL_PATH" ] && { echo "No active model. Run: llm-switch qwythos"; exit 1; }
          exec ${pkgs.llama-cpp}/bin/llama-cli -m "$MODEL_PATH" "''${COMMON_FLAGS[@]}" --conversation "$@"
          ;;
      esac
    '')

    # AI Coding Agents
    opencode # OpenCode - AI coding agent for terminal
    headroom # Headroom CLI via PyPI, pinned through uvx
    headroom-claude # Launch Claude through Headroom without mutable config writes
    headroom-codex # Launch Codex through Headroom without mutable config writes

    # NOTE: wrangler is installed via Firejail wrapper in security.nix

    # Reverse Engineering
    # NOTE: ghidra is installed via Firejail wrapper in security.nix
    jadx # Android APK/DEX decompiler (used by android-reverse-engineering skill)

    # Database clients
    postgresql # PostgreSQL client tools (psql, pg_dump, etc.)

    # Embedded / microcontrollers
    arduino-cli # Compile & upload to Arduino/ESP boards (CH340/CH341 serial)
  ];

  # systemd searches dash-truncated drop-in dirs (libpod-.scope.d matches the
  # libpod-<id>.scope units rootless podman creates), and transient units
  # honor drop-ins. Caps each container at 8 of 16 threads and makes it yield
  # to interactive work, so a runaway build inside a container cannot cook
  # the laptop. Same pattern as the app-code memory cap in vscode.nix.
  xdg.configFile."systemd/user/libpod-.scope.d/50-cpu-cap.conf".text = ''
    [Scope]
    CPUQuota=800%
    CPUWeight=50
  '';
}
