# Development tools configuration
{ pkgs, lib, ... }:

let
  headroomPythonPackage = "headroom-ai[proxy,mcp,code]==0.25.0";
  # mcp<2: headroom 0.25.0 declares mcp>=1.0.0 but uses the 1.x low-level
  # Server API (Server.list_tools); mcp 2.x removed it and `headroom mcp serve`
  # crashed at startup, so every Claude session reported the server as failed.
  headroomPython = "${pkgs.python313}/bin/python3";
  headroomRequirements = "'mcp<2' '${headroomPythonPackage}'";
  # One persistent environment per interpreter and requirement set, built on
  # first use. `uvx` resolved the unpinned dependencies again on each launch
  # and built a new 645 MB environment for every boto3 or openai release:
  # 46 environments / 30 GB in ~/.cache/uv on 2026-11-25. It also stayed
  # alive as a 41 MB parent of every headroom process.
  headroomEnvId = builtins.substring 0 16 (
    builtins.hashString "sha256" "${headroomPython} ${headroomRequirements}"
  );
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

    HEADROOM_ENV_BASE="$HOME/.local/share/headroom-env"
    HEADROOM_ENV="$HEADROOM_ENV_BASE/${headroomEnvId}"
    if [ ! -e "$HEADROOM_ENV/.ready" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$HEADROOM_ENV_BASE"
      # Several agent sessions can start at once: build under a lock. All
      # output goes to stderr because `headroom mcp serve` speaks on stdout.
      (
        ${pkgs.util-linux}/bin/flock 9
        if [ ! -e "$HEADROOM_ENV/.ready" ]; then
          echo "headroom: building environment (first run, about 645 MB)" >&2
          ${pkgs.coreutils}/bin/rm -rf "$HEADROOM_ENV"
          ${pkgs.uv}/bin/uv venv --quiet --no-python-downloads --python ${headroomPython} "$HEADROOM_ENV" \
            && ${pkgs.uv}/bin/uv pip install --quiet --python "$HEADROOM_ENV/bin/python" ${headroomRequirements} \
            && ${pkgs.coreutils}/bin/touch "$HEADROOM_ENV/.ready"
        fi
        # Drop environments of earlier pins, unless a process still runs from one.
        for old in "$HEADROOM_ENV_BASE"/*/; do
          old="''${old%/}"
          [ -d "$old" ] && [ "$old" != "$HEADROOM_ENV" ] || continue
          ${pkgs.procps}/bin/pgrep -f "$old/" >/dev/null || ${pkgs.coreutils}/bin/rm -rf "$old"
        done
      ) 9>"$HEADROOM_ENV_BASE/.lock" >&2
    fi
  '';

  # One Headroom proxy for every terminal: a systemd user unit per port
  # (headroom-proxy-8787 for Anthropic, OpenAI and Gemini; headroom-proxy-8788
  # for the GLM upstream), defined at the end of this file. systemd restarts a
  # proxy that dies, so open sessions get their API back within seconds, and
  # MemoryMax caps the slow growth measured on 2026-11-25: 153 MB idle,
  # 487 MB after the first request, then about +0.1 MB per request with no
  # plateau at 3200 requests.
  # The wrappers below start the unit, attach with `headroom wrap --no-proxy`
  # and stop the unit when the last session leaves. Sessions are counted with
  # headroom's own client markers (~/.headroom/clients/<port>/<pid>.json);
  # each wrapper writes one for itself, with the start_time field headroom
  # compares to detect a recycled PID (field 22 of /proc/<pid>/stat).
  # Marker, start and stop run under one lock per port, so a session that
  # starts while another one stops the unit gets a running proxy.
  # The proxy settings (HEADROOM_MODE and the other variables above) are read
  # by the unit, not by the shell that runs `claude`: `HEADROOM_MODE=cache
  # claude` does not change a shared proxy. Change the defaults above, or run
  # `systemctl --user set-environment HEADROOM_MODE=cache` before the first
  # session starts the unit.
  headroomSession = ''
    headroom_session_begin() {
      local port="$1" stat_fields
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.headroom/clients/$port"
      HEADROOM_OWN_MARKER="$HOME/.headroom/clients/$port/$$.json"
      read -r -a stat_fields < <(${pkgs.gnused}/bin/sed 's/^.*) //' "/proc/$$/stat")
      (
        ${pkgs.util-linux}/bin/flock 9
        printf '{"pid": %s, "started_at": %s, "start_src": "proc", "start_time": %s.0}\n' \
          "$$" "$(${pkgs.coreutils}/bin/date +%s)" "''${stat_fields[19]}" > "$HEADROOM_OWN_MARKER"
        ${pkgs.systemd}/bin/systemctl --user start "headroom-proxy-$port.service"
      ) 9>"$HOME/.headroom/lifecycle-$port.lock"
    }

    headroom_session_end() {
      local port="$1" marker pid recorded actual
      ${pkgs.coreutils}/bin/rm -f "$HEADROOM_OWN_MARKER"
      (
        ${pkgs.util-linux}/bin/flock 9
        # A marker counts while its PID is alive and, when it records a /proc
        # start time, while that still matches: after a crash or a reboot the
        # PID can belong to an unrelated process. Other markers are removed;
        # headroom only prunes them on a path `--no-proxy` never takes.
        for marker in "$HOME/.headroom/clients/$port"/*.json; do
          [ -e "$marker" ] || continue
          pid=$(${pkgs.coreutils}/bin/basename "$marker" .json)
          if kill -0 "$pid" 2>/dev/null; then
            recorded=$(${pkgs.jq}/bin/jq -r 'select(.start_src == "proc") | .start_time | floor' "$marker" 2>/dev/null)
            actual=$(${pkgs.gnused}/bin/sed 's/^.*) //' "/proc/$pid/stat" 2>/dev/null | ${pkgs.coreutils}/bin/cut -d' ' -f20)
            { [ -n "$recorded" ] && [ -n "$actual" ] && [ "$recorded" != "$actual" ]; } || exit 0
          fi
          ${pkgs.coreutils}/bin/rm -f "$marker"
        done
        ${pkgs.systemd}/bin/systemctl --user stop "headroom-proxy-$port.service"
      ) 9>"$HOME/.headroom/lifecycle-$port.lock"
      return 0
    }
  '';

  # ExecStart of the proxy units. It builds the command and environment the
  # way `headroom wrap claude` does for a proxy it starts itself (agent type,
  # stack and the savings-profile defaults from headroom's own code), so the
  # compression settings are the same as before.
  headroom-proxy-run = pkgs.writeShellScriptBin "headroom-proxy-run" ''
    ${headroomRuntimeEnv}
    export HEADROOM_AGENT_TYPE=claude HEADROOM_STACK=wrap_claude
    exec "$HEADROOM_ENV/bin/python" -c '
    import os, sys
    from headroom.agent_savings import apply_agent_savings_env_defaults
    env = dict(os.environ)
    apply_agent_savings_env_defaults(env, env.get("HEADROOM_SAVINGS_PROFILE"))
    cmd = [sys.executable, "-m", "headroom.cli", "proxy", "--port", sys.argv[1], "--mode", env["HEADROOM_MODE"]]
    os.execve(sys.executable, cmd, env)
    ' "$1"
  '';

  # ExecStartPost: `systemctl start` returns once the proxy answers.
  headroomProxyReady = pkgs.writeShellScript "headroom-proxy-ready" ''
    for _ in $(${pkgs.coreutils}/bin/seq 240); do
      ${pkgs.curl}/bin/curl -sf -m 2 "http://127.0.0.1:$1/livez" >/dev/null 2>&1 && exit 0
      ${pkgs.coreutils}/bin/sleep 1
    done
    exit 1
  '';

  headroomProxyUnit =
    {
      port,
      description,
      environment ? [ ],
    }:
    {
      Unit.Description = description;
      Service = {
        ExecStart = "${headroom-proxy-run}/bin/headroom-proxy-run ${toString port}";
        ExecStartPost = "${headroomProxyReady} ${toString port}";
        Environment = environment;
        Restart = "on-failure";
        RestartSec = 2;
        MemoryMax = "1G";
        # The first start after a pin change builds the 645 MB environment.
        TimeoutStartSec = 600;
        # The proxy writes ~/.headroom/logs/proxy.log itself.
        StandardOutput = "null";
      };
    };

  headroom = pkgs.writeShellScriptBin "headroom" ''
    ${headroomRuntimeEnv}
    exec "$HEADROOM_ENV/bin/headroom" "$@"
  '';

  # Every argument goes to Claude Code after `--`: without it headroom takes
  # `-p` (print mode) as its own --port and `-v` as --verbose.
  # `headroom wrap` prints a 15-line banner on stdout. When stdout is a pipe
  # or a file (`claude -p ... | jq`), Claude Code runs directly so the output
  # stays clean; such one-shot runs have little to compress. A custom upstream
  # (claude-glm) is kept by pointing ANTHROPIC_BASE_URL straight at it; the
  # same direct path is the fallback when the proxy unit does not start.
  # HEADROOM_WRAP_PORT selects a proxy other than the shared one on 8787
  # (claude-glm, whose proxy has another upstream). On such a port --no-mcp
  # keeps the user-scope headroom MCP entry on the default port, and
  # HEADROOM_PROXY_URL sends this session's MCP server to the right proxy.
  headroom-claude = pkgs.writeShellScriptBin "headroom-claude" ''
    direct() {
      [ -z "''${ANTHROPIC_TARGET_API_URL:-}" ] || export ANTHROPIC_BASE_URL="$ANTHROPIC_TARGET_API_URL"
      exec claude "$@"
    }
    [ -t 1 ] || direct "$@"
    ${headroomRuntimeEnv}
    ${headroomSession}
    port="''${HEADROOM_WRAP_PORT:-8787}"
    wrap_args=(--no-proxy --port "$port" --no-context-tool --no-serena)
    if [ "$port" != 8787 ]; then
      wrap_args+=(--no-mcp)
      export HEADROOM_PROXY_URL="http://127.0.0.1:$port"
    fi
    # Survive a closed terminal or Ctrl+C long enough to leave the session.
    trap : HUP INT TERM
    if ! headroom_session_begin "$port"; then
      echo "headroom-claude: headroom-proxy-$port.service did not start, running Claude Code directly" >&2
      headroom_session_end "$port"
      direct "$@"
    fi
    "$HEADROOM_ENV/bin/headroom" wrap claude "''${wrap_args[@]}" -- "$@"
    rc=$?
    headroom_session_end "$port"
    exit $rc
  '';

  # `headroom wrap codex` points ~/.codex/config.toml at the proxy
  # (model_provider, openai_base_url) and leaves it that way after exit.
  # Direct Codex calls (ask-gpt, codex-jail) would then fail whenever the
  # proxy is down, so the last wrapped session to exit removes the injected
  # blocks again. The byte-for-byte backup is dropped first: restoring it
  # would discard what Codex itself wrote during the session (project trust,
  # model choice), while without it `unwrap` only strips Headroom's blocks.
  # The session lock lives in the Codex home it protects, so sessions with
  # different CODEX_HOME values do not hold back each other's cleanup.
  # Not aliased to `codex`: on 2026-11-25, with Codex 0.172 logged in through
  # ChatGPT, the injected provider sent no Authorization header and OpenAI
  # answered 401 ("WS: no Authorization header from client" in proxy.log).
  headroom-codex = pkgs.writeShellScriptBin "headroom-codex" ''
    ${headroomRuntimeEnv}
    ${headroomSession}
    codex_home="''${CODEX_HOME:-$HOME/.codex}"
    ${pkgs.coreutils}/bin/mkdir -p "$codex_home"
    exec 8>"$codex_home/headroom-sessions.lock"
    ${pkgs.util-linux}/bin/flock -s 8
    # Survive a closed terminal or Ctrl+C long enough to restore the config.
    trap : HUP INT TERM
    if ! headroom_session_begin 8787; then
      echo "headroom-codex: headroom-proxy-8787.service did not start" >&2
      headroom_session_end 8787
      exit 1
    fi
    "$HEADROOM_ENV/bin/headroom" wrap codex --no-proxy --no-context-tool --no-serena -- "$@" 8>&-
    rc=$?
    if ${pkgs.util-linux}/bin/flock -xn 8; then
      ${pkgs.coreutils}/bin/rm -f "$codex_home/config.toml.headroom-backup"
      # --no-stop-proxy: the unit is stopped by headroom_session_end, and
      # only when no other session uses it.
      "$HEADROOM_ENV/bin/headroom" unwrap codex --no-stop-proxy >/dev/null 2>&1
    fi
    headroom_session_end 8787
    exit $rc
  '';

  # OpenCode through the shared proxy. `headroom wrap` has no opencode target,
  # so this script only joins the session count and points the google
  # provider at the proxy (Gemini API under /v1beta); the local-llm provider
  # stays direct. Verified 2026-11-25 with opencode 1.19.6.
  headroom-opencode = pkgs.writeShellScriptBin "headroom-opencode" ''
    ${headroomRuntimeEnv}
    ${headroomSession}
    # Survive a closed terminal or Ctrl+C long enough to leave the session.
    trap : HUP INT TERM
    if ! headroom_session_begin 8787; then
      echo "headroom-opencode: headroom-proxy-8787.service did not start, running OpenCode directly" >&2
      headroom_session_end 8787
      exec opencode "$@"
    fi
    # Merge into an inline config the caller already set instead of replacing
    # it. A value jq cannot parse is left alone: that session then reaches
    # Gemini directly.
    if merged=$(${pkgs.jq}/bin/jq -c '.provider.google.options.baseURL = "http://127.0.0.1:8787/v1beta"' \
      <<< "''${OPENCODE_CONFIG_CONTENT:-{\}}" 2>/dev/null); then
      export OPENCODE_CONFIG_CONTENT="$merged"
    else
      echo "headroom-opencode: OPENCODE_CONFIG_CONTENT is not plain JSON, google provider stays direct" >&2
    fi
    opencode "$@"
    rc=$?
    headroom_session_end 8787
    exit $rc
  '';
in
{
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
    universal-modder # `um`: game recon, assets, backups and mod packaging

    # Languages (base compilers)
    python313 # Project dependencies are managed with uv
    nodejs_22 # Full Node (npm/npx): Medusa tooling and skills run `npx medusa ...`
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
    # .NET SDK 10 (latest)
    dotnetCorePackages.sdk_10_0
    icu # Required by .NET for globalization support

    # C++ Development (complete modern toolchain)
    gcc # Primary C/C++ compiler
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
    zellij # Terminal multiplexer
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
        ["qwythos"]="Qwythos-9B-v2-Q4_K_M.gguf"
        ["mythos"]="Qwythos-9B-v2-Q4_K_M.gguf"
        ["claude-mythos"]="Qwythos-9B-v2-Q4_K_M.gguf"
        ["qwen35"]="Qwythos-9B-v2-Q4_K_M.gguf"
        ["qwen3.5"]="Qwythos-9B-v2-Q4_K_M.gguf"
        ["mellum"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["mellum2"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["mellum2.1"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["jetbrains"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["code"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["coding"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["agent"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["text"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["default"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["fast"]="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
        ["bolt"]="Nemotron-3.5-Bolt-E4B-Uncensored-Q4_K_M.gguf"
        ["nemotron"]="Nemotron-3.5-Bolt-E4B-Uncensored-Q4_K_M.gguf"
        ["research"]="Nemotron-3.5-Bolt-E4B-Uncensored-Q4_K_M.gguf"
        ["uncensored"]="Nemotron-3.5-Bolt-E4B-Uncensored-Q4_K_M.gguf"
        ["chat"]="Nemotron-3.5-Bolt-E4B-Uncensored-Q4_K_M.gguf"
        ["ocr"]="Xiaomi-OCR-0.BF16.gguf"
      )
      MMPROJ_OCR="$MODELS_DIR/Xiaomi-OCR-0.mmproj-bf16.gguf"

      usage() {
        echo "Usage: llm [model] [extra-args...]"
        echo "       llm              Chat with active model (set by llm-switch)"
        echo "       llm qwythos      Chat with Qwythos 9B v2"
        echo "       llm mellum       Chat with Mellum2.1 12B MoE coder"
        echo "       llm bolt         Chat with Nemotron 3.5 Bolt E4B uncensored"
        echo "       llm ocr <image>  OCR an image with Xiaomi-OCR-0"
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
      # Thinking cap with its end-of-thinking message: same values as the
      # llama-cpp service; modules/system/llama-cpp.nix has the measurements.
      COMMON_FLAGS=(-ngl "$LLM_GPU_LAYERS" --no-kv-offload --temp "$LLM_TEMP" --top-p "$LLM_TOP_P" --top-k "$LLM_TOP_K" --load-mode none -c "$LLM_CTX_SIZE" --jinja
        --reasoning-budget 128
        --reasoning-budget-message "Thinking budget reached. I stop reasoning here and write the final answer directly.")

      # Speculative decoding like the service: Mellum's MTP head on the GPU,
      # when the head file is in ~/models. Other models have no head.
      MTP_MELLUM="$MODELS_DIR/mtp-Mellum2.1-12B-A2.5B-Thinking-BF16.gguf"
      SPEC_FLAGS=()
      spec_flags() {
        if [ "$(basename "$(readlink -f "$1")")" = "''${MODEL_NAMES[mellum]}" ] && [ -f "$MTP_MELLUM" ]; then
          SPEC_FLAGS=(-md "$MTP_MELLUM" --spec-type draft-mtp --spec-draft-n-max 1 -ngld all)
        fi
      }

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
          # OCR mode: use Xiaomi-OCR-0 vision model, saves output to .txt next to image
          MODEL_PATH="$MODELS_DIR/''${MODEL_NAMES[ocr]}"
          [ ! -f "$MODEL_PATH" ] && { echo "Model not found: $MODEL_PATH"; echo "Download: wget -P ~/models https://huggingface.co/prithivMLmods/Xiaomi-OCR-0-GGUF/resolve/main/Xiaomi-OCR-0.BF16.gguf"; exit 1; }
          [ ! -f "$MMPROJ_OCR" ] && { echo "mmproj not found: $MMPROJ_OCR"; echo "Download: wget -P ~/models https://huggingface.co/prithivMLmods/Xiaomi-OCR-0-GGUF/resolve/main/Xiaomi-OCR-0.mmproj-bf16.gguf"; exit 1; }
          IMAGE="''${2:-}"
          [ -z "$IMAGE" ] && { echo "Usage: llm ocr <image> [prompt]"; echo "  llm ocr photo.jpg                    # default: full document to markdown"; echo "  llm ocr table.png 'Parse the table in the image into OTSL.'"; echo "  llm ocr eq.png 'Identify the formula in the image and represent it using LATEX format.'"; exit 1; }
          [ ! -f "$IMAGE" ] && { echo "File not found: $IMAGE"; exit 1; }
          PROMPT="''${3:-Extract all information from the main body of the document image and represent it in markdown format, ignoring headers and footers. Tables should be expressed in OTSL format, formulas in the document should be represented using LATEX format, and the parsing should be organized according to the reading order.}"
          OUTPUT="''${IMAGE%.*}.txt"
          echo "OCR: $IMAGE → $OUTPUT (prompt: $PROMPT)"
          ${pkgs.llama-cpp}/bin/llama-mtmd-cli -m "$MODEL_PATH" --mmproj "$MMPROJ_OCR" -ngl "$LLM_GPU_LAYERS" --no-kv-offload --load-mode none -c 8192 --image "$IMAGE" -p "$PROMPT" --temp 0.1 -n 8192 "''${@:4}" | tee "$OUTPUT"
          echo ""
          echo "Saved: $OUTPUT"
          ;;
        local)
          exec /run/current-system/sw/bin/llm-local
          ;;
        server)
          MODEL_PATH="''${2:-$ACTIVE}"
          [ -n "''${MODEL_NAMES[''${2:-}]:-}" ] && MODEL_PATH="$MODELS_DIR/''${MODEL_NAMES[$2]}"
          [ ! -f "$MODEL_PATH" ] && { echo "Model not found. Run: llm-switch mellum"; exit 1; }
          echo "Starting llama-server with $(basename "$MODEL_PATH")..."
          echo "API: http://127.0.0.1:8080/v1"
          spec_flags "$MODEL_PATH"
          exec ${pkgs.llama-cpp}/bin/llama-server -m "$MODEL_PATH" --host 127.0.0.1 --port 8080 "''${COMMON_FLAGS[@]}" "''${SPEC_FLAGS[@]}" --parallel 1 --cache-ram 0 --no-warmup "''${@:3}"
          ;;
        *)
          # Determine model path
          if [ -n "''${1:-}" ] && resolve_model "$1" > /dev/null 2>&1; then
            MODEL_PATH=$(resolve_model "$1")
            shift
          else
            MODEL_PATH="$ACTIVE"
          fi
          [ ! -f "$MODEL_PATH" ] && { echo "No active model. Run: llm-switch mellum"; exit 1; }
          spec_flags "$MODEL_PATH"
          exec ${pkgs.llama-cpp}/bin/llama-cli -m "$MODEL_PATH" "''${COMMON_FLAGS[@]}" "''${SPEC_FLAGS[@]}" "$@"
          ;;
      esac
    '')

    # AI Coding Agents
    opencode # OpenCode - AI coding agent for terminal
    headroom # Headroom CLI via PyPI, pinned, in a persistent uv environment
    headroom-claude # Launch Claude through Headroom without mutable config writes
    headroom-codex # Launch Codex through Headroom; cleans ~/.codex/config.toml on exit
    headroom-opencode # Launch OpenCode (google provider) through the shared Headroom proxy
    beads # `bd`: per-project issue tracker for coding agents; enable a project with `bd init`

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

  # Rootless podman keeps every image ever built under
  # ~/.local/share/containers; the system podman-prune timer only cleans
  # root's storage. 1810 images / 69 GB had accumulated by 2026-09-06.
  # Weekly: drop untagged images and images unused for a week. Images used
  # by a container (running or stopped) are never removed.
  systemd.user.services.podman-image-prune = {
    Unit.Description = "Prune unused rootless podman images";
    Service = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.podman}/bin/podman image prune -f"
        "${pkgs.podman}/bin/podman image prune -a -f --filter until=168h"
      ];
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };
  systemd.user.timers.podman-image-prune = {
    Unit.Description = "Weekly rootless podman image prune";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # Headroom proxies, started and stopped on demand by the headroom-* wrappers
  # (headroomSession at the top of this file); no Install section on purpose.
  systemd.user.services.headroom-proxy-8787 = headroomProxyUnit {
    port = 8787;
    description = "Headroom proxy (Anthropic, OpenAI, Gemini)";
  };
  # GLM Coding Plan upstream for claude-glm (shell.nix). No subscription
  # tracking: that poller asks Anthropic for usage.
  systemd.user.services.headroom-proxy-8788 = headroomProxyUnit {
    port = 8788;
    description = "Headroom proxy (Z.AI GLM)";
    environment = [
      "ANTHROPIC_TARGET_API_URL=https://api.z.ai/api/anthropic"
      "HEADROOM_NO_SUBSCRIPTION_TRACKING=1"
    ];
  };

  # bd (beads) sends anonymous usage metrics unless its global config says
  # otherwise. Seed the opt-out once; bd owns the file afterwards
  # (`bd metrics on` reverses it).
  home.activation.beadsMetricsOff = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.config/bd/config.yaml" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 ${pkgs.writeText "bd-config.yaml" "metrics:\n  disabled: true\n"} "$HOME/.config/bd/config.yaml"
    fi
  '';

  # uvx builds a fresh ~0.5 GB headroom environment whenever the pinned
  # interpreter store path changes (every nixpkgs bump) and never removes the
  # old ones: 665 environments / 55 GB by 2026-09-06. `uv cache prune` cannot
  # run while any uvx-launched MCP server holds the cache lock, so drop
  # environments older than 14 days ourselves, skipping any a running
  # process executes from.
  # Headroom left uvx on 2026-11-25 (persistent environment, see the top of
  # this file); the prune stays for the remaining uvx users (blender-mcp) and
  # clears the headroom environments left in the cache.
  systemd.user.services.uv-archive-prune = {
    Unit.Description = "Prune old uvx environments";
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "uv-archive-prune" ''
        set -eu
        dir="$HOME/.cache/uv/archive-v0"
        [ -d "$dir" ] || exit 0
        inuse=$(${pkgs.coreutils}/bin/readlink /proc/[0-9]*/exe 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -oE 'archive-v0/[^/]+' | ${pkgs.coreutils}/bin/sort -u || true)
        ${pkgs.findutils}/bin/find "$dir" -mindepth 1 -maxdepth 1 -mtime +14 -print0 \
          | while IFS= read -r -d "" entry; do
              case "$inuse" in *"archive-v0/$(${pkgs.coreutils}/bin/basename "$entry")"*) continue ;; esac
              ${pkgs.coreutils}/bin/rm -rf "$entry"
            done
      '';
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };
  systemd.user.timers.uv-archive-prune = {
    Unit.Description = "Weekly uvx environment prune";
    Timer = {
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
