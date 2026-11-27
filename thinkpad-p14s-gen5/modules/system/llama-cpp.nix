# llama.cpp local LLM service configuration
{ config, pkgs, lib, ... }:

let
  llamaRocmEnvironment = {
    HSA_OVERRIDE_GFX_VERSION = config.hardware.amd.rocm.gfxVersion; # Fix for RDNA 3 iGPU
    ROCR_VISIBLE_DEVICES = "0"; # Use first GPU
    ROC_ENABLE_PRE_VEGA = "1"; # Compatibility
    # Use hipMallocManaged: spills into GTT (system RAM) when VRAM is full.
    GGML_CUDA_ENABLE_UNIFIED_MEMORY = "1";
    # Reduce iGPU pressure and avoid known ROCm hang sources on APUs.
    GPU_MAX_HW_QUEUES = "1";
    HSA_ENABLE_SDMA = "0";
  };
  llamaSafeGpuLayers = "20";

  llmModelActivate = pkgs.writeShellScriptBin "llm-model-activate" ''
    set -euo pipefail

    MODE="''${1:-}"
    MODEL_PATH="''${2:-}"
    MMPROJ_PATH="''${3:-}"
    # Text mode: optional MTP draft head of the model (speculative decoding).
    DRAFT_PATH="''${3:-}"
    SERVICE_DIR="/var/lib/llama-cpp"

    GETENT="${pkgs.getent}/bin/getent"
    AWK="${pkgs.gawk}/bin/awk"
    READLINK="${pkgs.coreutils}/bin/readlink"
    INSTALL="${pkgs.coreutils}/bin/install"
    RM="${pkgs.coreutils}/bin/rm"
    PRINTF="${pkgs.coreutils}/bin/printf"

    user_home="''${HOME:-${config.users.users.marcelo.home}}"
    if [ -n "''${SUDO_USER:-}" ] && [ "''${SUDO_USER:-}" != "root" ]; then
      user_home=$("$GETENT" passwd "$SUDO_USER" | "$AWK" -F: '{ print $6 }')
    fi
    MODELS_DIR="$user_home/models"

    require_model_path() {
      local path="$1"
      local kind="$2"
      local real
      real=$("$READLINK" -f "$path")
      case "$real" in
        "$MODELS_DIR"/*.gguf) ;;
        *)
          echo "Refusing $kind outside $MODELS_DIR/*.gguf: $path" >&2
          exit 1
          ;;
      esac
      if [ ! -f "$real" ]; then
        echo "$kind not found: $real" >&2
        exit 1
      fi
      echo "$real"
    }

    case "$MODE" in
      text|ocr) ;;
      *)
        echo "Usage: llm-model-activate text MODEL.gguf [MTP_HEAD.gguf] | ocr MODEL.gguf MMPROJ.gguf" >&2
        exit 1
        ;;
    esac

    REAL_MODEL=$(require_model_path "$MODEL_PATH" "model")
    REAL_DRAFT=""
    if [ "$MODE" = "text" ] && [ -n "$DRAFT_PATH" ]; then
      REAL_DRAFT=$(require_model_path "$DRAFT_PATH" "MTP head")
    fi
    "$INSTALL" -d -m 0755 -o root -g root "$SERVICE_DIR"
    "$INSTALL" -m 0644 -o root -g root "$REAL_MODEL" "$SERVICE_DIR/active-model.gguf"

    if [ "$MODE" = "ocr" ]; then
      REAL_MMPROJ=$(require_model_path "$MMPROJ_PATH" "mmproj")
      "$INSTALL" -m 0644 -o root -g root "$REAL_MMPROJ" "$SERVICE_DIR/active-mmproj.gguf"
      "$PRINTF" '%s\n' "ocr" > "$SERVICE_DIR/active-mode"
    else
      "$RM" -f "$SERVICE_DIR/active-mmproj.gguf"
      "$PRINTF" '%s\n' "text" > "$SERVICE_DIR/active-mode"
    fi

    # Speculative decoding is switched on per staged model through an
    # optional EnvironmentFile of the llama-cpp unit, so models without an
    # MTP head start with the same unit. The file content is fixed here,
    # never taken from the caller.
    if [ -n "$REAL_DRAFT" ]; then
      "$INSTALL" -m 0644 -o root -g root "$REAL_DRAFT" "$SERVICE_DIR/active-draft.gguf"
      "$PRINTF" '%s\n' \
        "LLAMA_ARG_SPEC_DRAFT_MODEL=$SERVICE_DIR/active-draft.gguf" \
        "LLAMA_ARG_SPEC_TYPE=draft-mtp" \
        "LLAMA_ARG_SPEC_DRAFT_N_MAX=1" \
        "LLAMA_ARG_N_GPU_LAYERS_DRAFT=all" > "$SERVICE_DIR/active-spec.env"
      ${pkgs.coreutils}/bin/chmod 0644 "$SERVICE_DIR/active-spec.env"
    else
      "$RM" -f "$SERVICE_DIR/active-draft.gguf" "$SERVICE_DIR/active-spec.env"
    fi

    ${pkgs.coreutils}/bin/chmod 0644 "$SERVICE_DIR/active-mode"
  '';

  # Models are copied from ~/models into /var/lib/llama-cpp by llm-model-activate.
  # Text and OCR use separate declarative systemd units; no runtime drop-ins.
  llm-switch = pkgs.writeShellScriptBin "llm-switch" ''
    set -euo pipefail

    MODELS_DIR="$HOME/models"

    MODEL_QWYTHOS="Qwythos-9B-v2-Q4_K_M.gguf"
    MODEL_MELLUM="Mellum2.1-12B-A2.5B-Thinking-Q4_K_M.gguf"
    # Official MTP draft head for Mellum (speculative decoding): +14 to +16%
    # decode with the head on the GPU, measured 2026-11-24
    # (~/models/benchmarks). Optional: without the file Mellum runs plain.
    MTP_MELLUM="mtp-Mellum2.1-12B-A2.5B-Thinking-BF16.gguf"
    MODEL_BOLT="Nemotron-3.5-Bolt-E4B-Uncensored-Q4_K_M.gguf"
    MODEL_OCR="Xiaomi-OCR-0.BF16.gguf"
    MMPROJ_OCR="Xiaomi-OCR-0.mmproj-bf16.gguf"
    USER_ACTIVE_MODEL="$MODELS_DIR/active-model.gguf"

    DU="${pkgs.coreutils}/bin/du"
    CUT="${pkgs.coreutils}/bin/cut"
    LN="${pkgs.coreutils}/bin/ln"
    MV="${pkgs.coreutils}/bin/mv"
    READLINK="${pkgs.coreutils}/bin/readlink"
    BASENAME="${pkgs.coreutils}/bin/basename"
    SYSTEMCTL="/run/current-system/sw/bin/systemctl"
    ACTIVATE="${llmModelActivate}/bin/llm-model-activate"

    # "MODE MODEL" marker kept by llm-switch (below) because /var/lib/llama-cpp
    # itself is unreadable here: the units use DynamicUser, so it resolves
    # through /var/lib/private (0700 root). Written as the user, never by the
    # root helper: ~/models is user-owned, so a root write there follows any
    # symlink the user plants.
    active_mode=text
    current_name=""
    current_draft=""
    read -r active_mode current_name current_draft 2>/dev/null < "$MODELS_DIR/.llm-active" || true
    draft=""

    stop_services() {
      sudo "$SYSTEMCTL" stop llama-cpp 2>/dev/null || true
      sudo "$SYSTEMCTL" stop llama-cpp-ocr 2>/dev/null || true
    }

    restart_if_running() {
      if "$SYSTEMCTL" is-active --quiet llama-cpp || "$SYSTEMCTL" is-active --quiet llama-cpp-ocr; then
        stop_services
        sudo "$SYSTEMCTL" start "$service"
        echo "Done. LLM now running with $label"
      else
        echo "Done. Model is ready. Run: llm local"
      fi
    }

    case "''${1:-}" in
      qwythos|mythos|claude-mythos|qwen35|qwen3.5)
        target="$MODEL_QWYTHOS"
        label="Qwythos 9B v2 Q4_K_M (5.74GB)"
        mode="text"
        service="llama-cpp"
        ;;
      # Default: fastest model on this APU (20 tokens/s, Qwythos 7.7, Bolt 12;
      # measured 2026-11-24) and both API consumers (Neovim, OpenCode) code.
      mellum|mellum2|mellum2.1|jetbrains|code|coding|agent|text|default|fast)
        target="$MODEL_MELLUM"
        label="Mellum2.1 12B-A2.5B Thinking Q4_K_M (8.07GB)"
        mode="text"
        service="llama-cpp"
        draft="$MTP_MELLUM"
        ;;
      bolt|nemotron|research|uncensored|chat)
        target="$MODEL_BOLT"
        label="Nemotron 3.5 Bolt E4B Uncensored Q4_K_M (5.06GB)"
        mode="text"
        service="llama-cpp"
        ;;
      ocr|OCR|vision)
        target="$MODEL_OCR"
        label="Xiaomi-OCR-0 0.8B BF16 (vision/OCR, 1.7GB)"
        mode="ocr"
        service="llama-cpp-ocr"
        ;;
      status|"")
        user_active=$("$READLINK" "$USER_ACTIVE_MODEL" 2>/dev/null || true)
        if [ -n "$user_active" ]; then
          echo "User active model: $("$BASENAME" "$user_active")"
        else
          echo "User active model: none. Run: llm-switch mellum"
        fi

        if [ -n "$current_name" ]; then
          echo "Service staged model: $current_name"
          echo "Mode: $active_mode"
          echo "Speculative decoding (MTP head): ''${current_draft:-off}"
        else
          echo "Service staged model: not staged"
        fi
        echo "Services:"
        echo "  text: $("$SYSTEMCTL" is-active llama-cpp 2>/dev/null)"
        echo "  ocr:  $("$SYSTEMCTL" is-active llama-cpp-ocr 2>/dev/null)"
        echo ""
        echo "Available models:"
        [ -f "$MODELS_DIR/$MODEL_QWYTHOS" ] && echo "  qwythos   -> $MODEL_QWYTHOS (5.74GB)" || echo "  qwythos   -> $MODEL_QWYTHOS (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_MELLUM" ] && echo "  mellum    -> $MODEL_MELLUM (8.07GB)" || echo "  mellum    -> $MODEL_MELLUM (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_BOLT" ] && echo "  bolt      -> $MODEL_BOLT (5.06GB)" || echo "  bolt      -> $MODEL_BOLT (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_OCR" ] && echo "  ocr       -> $MODEL_OCR (1.7GB) - vision/OCR" || echo "  ocr       -> $MODEL_OCR (not downloaded)"
        echo ""
        echo "Usage: llm-switch [qwythos|mellum|bolt|ocr|status|stop]"
        exit 0
        ;;
      stop)
        echo "Stopping llama-cpp services..."
        stop_services
        echo "LLM stopped."
        exit 0
        ;;
      *)
        echo "Usage: llm-switch [qwythos|mellum|bolt|ocr|status|stop]"
        echo "  mellum   -> Mellum2.1 12B MoE (2.5B active) coding, fast (default)"
        echo "  qwythos  -> Qwythos 9B v2 uncensored research, long reasoning"
        echo "  bolt     -> Nemotron 3.5 Bolt E4B uncensored, chat and research"
        echo "  ocr      -> Xiaomi-OCR-0 0.8B vision/OCR utility"
        echo "  stop     -> Stop LLM service"
        exit 1
        ;;
    esac

    if [ ! -f "$MODELS_DIR/$target" ]; then
      echo "Error: $MODELS_DIR/$target not found."
      echo "Download it first."
      if [ "$target" = "$MODEL_QWYTHOS" ]; then
        echo "  wget -P ~/models https://huggingface.co/empero-ai/Qwythos-9B-v2-GGUF/resolve/main/$MODEL_QWYTHOS"
      elif [ "$target" = "$MODEL_OCR" ]; then
        echo "  wget -P ~/models https://huggingface.co/prithivMLmods/Xiaomi-OCR-0-GGUF/resolve/main/$MODEL_OCR"
      elif [ "$target" = "$MODEL_MELLUM" ]; then
        echo "  wget -P ~/models https://huggingface.co/JetBrains/Mellum2.1-12B-A2.5B-Thinking-GGUF/resolve/main/$MODEL_MELLUM"
      elif [ "$target" = "$MODEL_BOLT" ]; then
        echo "  wget -O ~/models/$MODEL_BOLT https://huggingface.co/AtomicChat/NVIDIA-Nemotron-3.5-Bolt-E4B-Uncensored-GGUF/resolve/main/NVIDIA-Nemotron-3.5-Bolt-E4B-Uncensored-AD-Q4_K_M/NVIDIA-Nemotron-3.5-Bolt-E4B-Uncensored-AD-Q4_K_M-00001-of-00001.gguf"
      fi
      exit 1
    fi

    if [ -n "$draft" ] && [ ! -f "$MODELS_DIR/$draft" ]; then
      echo "MTP head not found, staging without speculative decoding. To enable it:"
      echo "  wget -P ~/models https://huggingface.co/JetBrains/Mellum2.1-12B-A2.5B-Thinking-GGUF/resolve/main/$draft"
      draft=""
    fi

    if [ "$current_name" = "$target" ] && [ "$active_mode" = "$mode" ] && [ "$current_draft" = "$draft" ]; then
      echo "Already using $label"
      exit 0
    fi

    echo "Switching to $label..."
    echo "Copying model ($("$DU" -h "$MODELS_DIR/$target" | "$CUT" -f1))..."

    if [ "$mode" = "ocr" ]; then
      if [ ! -f "$MODELS_DIR/$MMPROJ_OCR" ]; then
        echo "Error: $MODELS_DIR/$MMPROJ_OCR not found."
        echo "Download it: wget -P ~/models https://huggingface.co/prithivMLmods/Xiaomi-OCR-0-GGUF/resolve/main/$MMPROJ_OCR"
        exit 1
      fi
      sudo "$ACTIVATE" ocr "$MODELS_DIR/$target" "$MODELS_DIR/$MMPROJ_OCR"
    else
      "$LN" -sfn "$MODELS_DIR/$target" "$USER_ACTIVE_MODEL"
      sudo "$ACTIVATE" text "$MODELS_DIR/$target" ''${draft:+"$MODELS_DIR/$draft"}
    fi
    # Replace by rename: an old root-owned marker cannot be overwritten in place.
    # Third field: staged MTP head, empty when speculative decoding is off.
    printf '%s %s %s\n' "$mode" "$target" "$draft" > "$MODELS_DIR/.llm-active.tmp"
    "$MV" -f "$MODELS_DIR/.llm-active.tmp" "$MODELS_DIR/.llm-active"

    restart_if_running
  '';

  llm-local = pkgs.writeShellScriptBin "llm-local" ''
    set -euo pipefail

    SYSTEMCTL="/run/current-system/sw/bin/systemctl"
    URL="http://127.0.0.1:8080"

    # --wait: return only once the model is loaded (used by opencode-local).
    WAIT=0
    [ "''${1:-}" = "--wait" ] && WAIT=1

    # Nothing staged yet: stage the default model first, so one command is
    # enough on a fresh setup.
    if [ ! -f "$HOME/models/.llm-active" ]; then
      ${llm-switch}/bin/llm-switch default
    fi

    # Mode comes from the user-readable marker written by llm-switch;
    # /var/lib/llama-cpp/active-mode is behind /var/lib/private (0700 root).
    MODE=$(${pkgs.coreutils}/bin/cut -d' ' -f1 "$HOME/models/.llm-active" 2>/dev/null || echo text)

    if [ "$MODE" = "ocr" ]; then
      SERVICE="llama-cpp-ocr"
      OTHER="llama-cpp"
    else
      SERVICE="llama-cpp"
      OTHER="llama-cpp-ocr"
    fi

    if ! "$SYSTEMCTL" is-active --quiet "$SERVICE"; then
      echo "Starting local LLM API..."
      sudo "$SYSTEMCTL" stop "$OTHER" 2>/dev/null || true
      sudo "$SYSTEMCTL" start "$SERVICE"
    else
      echo "Local LLM API already running."
    fi

    if [ "$WAIT" = 1 ] && ! ${pkgs.curl}/bin/curl -sf -m 2 "$URL/health" >/dev/null 2>&1; then
      printf 'Loading local model'
      for _ in $(${pkgs.coreutils}/bin/seq 120); do
        ${pkgs.curl}/bin/curl -sf -m 2 "$URL/health" >/dev/null 2>&1 && break
        printf '.'
        ${pkgs.coreutils}/bin/sleep 1
      done
      printf '\n'
    fi

    echo "API: $URL/v1"
    echo "Stop: llm-switch stop"
  '';
in
{
  # llama.cpp - Local LLM inference with conservative AMD GPU offload.
  #
  # The Radeon 780M/ROCm path wedged the compositor GPU with full 9B offload
  # (-ngl 99), automatic 4 slots, and the 8 GiB prompt cache. Keep GPU enabled,
  # but cap the layer offload and remove the extra server-side pressure.
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp; # Uses overlay version, not nixpkgs default
    settings = {
      host = "127.0.0.1";
      port = 8080;
      model = "/var/lib/llama-cpp/active-model.gguf";
      gpu-layers = llamaSafeGpuLayers;
      no-kv-offload = true;
      load-mode = "none"; # No mmap: better for iGPU with shared memory (--no-mmap removed in b11883)
      # 32768, not 16384: the Claude Code harness (claude-local, shell.nix)
      # hit its auto-compaction on a one-line fix at 16384 (6 min, no edit
      # made) and finished the same task in 78 s at 32768. Mellum 12B at
      # 32768 measured 8.6 GB RSS (2026-11-24); KV stays in system RAM.
      ctx-size = 32768;
      # Cap hidden thinking at 128 tokens for every text model. The cap only
      # works together with LLAMA_ARG_THINK_BUDGET_MESSAGE (set on the unit
      # below): alone, Mellum keeps reasoning inside the visible answer and
      # saves no time. Measured 2026-11-24 on Mellum, same bug-fix prompt:
      # no cap 1719 tokens / 85 s, cap 128 with message 393 tokens / 18 s,
      # cap 512 with message 807 tokens / 39 s; all three fixes correct.
      # Without a cap the LRU cache prompt thought for about 2165 tokens and
      # never reached the answer. Raise it if answers get shallow; -1
      # removes the cap.
      reasoning-budget = 128;
      parallel = 1;
      cache-ram = 0;
      no-warmup = true;
      jinja = true;
    };
  };

  # Keep the unit available but do not burn RAM/VRAM/battery at boot.
  systemd.services.llama-cpp.wantedBy = lib.mkForce [ ];

  environment.systemPackages = [ llm-switch llm-local llmModelActivate ];

  # Passwordless LLM controls are constrained to fixed service operations and
  # llm-model-activate, which validates that model inputs live under ~/models.
  security.sudo.extraRules = [
    {
      users = [ "marcelo" ];
      commands = [
        {
          command = "${llmModelActivate}/bin/llm-model-activate *";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl start llama-cpp";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop llama-cpp";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl start llama-cpp-ocr";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl stop llama-cpp-ocr";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  systemd.services.llama-cpp.environment = llamaRocmEnvironment // {
    # Injected when the thinking budget (settings.reasoning-budget) runs
    # out, so the model answers instead of reasoning on in the answer. Set
    # here, not in settings: the module joins ExecStart arguments with
    # spaces and would split the sentence.
    LLAMA_ARG_THINK_BUDGET_MESSAGE = "Thinking budget reached. I stop reasoning here and write the final answer directly.";
  };
  systemd.services.llama-cpp.serviceConfig = {
    # llama.cpp's UMA memory probe reads /proc/meminfo. The upstream NixOS unit
    # hides non-process /proc entries, making it fall back to cudaMemGetInfo and
    # overestimate the usable iGPU memory.
    ProcSubset = lib.mkForce "all";
    ProtectProc = lib.mkForce "default";
    # Speculative decoding (MTP head on the GPU) for models staged with one;
    # written by llm-model-activate, absent otherwise ("-" makes it optional).
    # The 780M ran it for two 2-minute benchmarks without amdgpu errors; if
    # long sessions wedge the compositor, change LLAMA_ARG_N_GPU_LAYERS_DRAFT
    # to 0 in llm-model-activate (head on CPU: +5 to +13% instead of +14 to
    # +16%).
    EnvironmentFile = "-/var/lib/llama-cpp/active-spec.env";
  };

  # OCR mode uses a separate declarative unit instead of a runtime drop-in.
  systemd.services.llama-cpp-ocr = {
    description = "llama.cpp OCR API server";
    after = [ "network.target" ];
    wantedBy = lib.mkForce [ ];
    # Both servers bind 127.0.0.1:8080 — make systemd guarantee mutual exclusion
    # so they can never restart-loop fighting for the port.
    conflicts = [ "llama-cpp.service" ];
    # Don't start (and restart-loop) if llm-switch hasn't staged the mmproj yet.
    unitConfig.ConditionPathExists = "/var/lib/llama-cpp/active-mmproj.gguf";
    environment = llamaRocmEnvironment;
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "llama-cpp";
      WorkingDirectory = "/var/lib/llama-cpp";
      ExecStart = "${pkgs.llama-cpp}/bin/llama-server --log-disable --host 127.0.0.1 --port 8080 -m /var/lib/llama-cpp/active-model.gguf --mmproj /var/lib/llama-cpp/active-mmproj.gguf -ngl ${llamaSafeGpuLayers} --no-kv-offload --load-mode none -c 8192 --parallel 1 --cache-ram 0 --no-warmup --jinja";
      Restart = "on-failure";
      RestartSec = 10;
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  # llm-switch copies models into /var/lib/llama-cpp, so no /home access is needed.
  systemd.services.llama-cpp.serviceConfig.RestartSec = lib.mkForce 10;
  # Mirror of the OCR unit's Conflicts= so either start order stops the other.
  systemd.services.llama-cpp.conflicts = [ "llama-cpp-ocr.service" ];
}
