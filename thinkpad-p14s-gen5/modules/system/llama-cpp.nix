# llama.cpp local LLM service configuration
{ config, pkgs, lib, ... }:

let
  # Qwen3.5 chat template that bypasses thinking by injecting an empty think block.
  qwen-no-think-template = pkgs.writeText "qwen3.5-no-think.jinja" ''
    {%- if not messages %}
        {{- raise_exception('No messages provided.') }}
    {%- endif %}
    {%- if messages[0].role == 'system' %}
        {{- '<|im_start|>system\n' + messages[0].content|trim + '<|im_end|>\n' }}
    {%- endif %}
    {%- for message in messages %}
        {%- if message.role == "system" %}
        {%- elif message.role == "user" %}
            {{- '<|im_start|>' + message.role + '\n' + message.content|trim + '<|im_end|>' + '\n' }}
        {%- elif message.role == "assistant" %}
            {{- '<|im_start|>' + message.role + '\n' + message.content|trim + '<|im_end|>\n' }}
        {%- endif %}
    {%- endfor %}
    {%- if add_generation_prompt %}
        {{- '<|im_start|>assistant\n<think>\n\n</think>\n\n' }}
    {%- endif %}
  '';

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

  llmModelActivate = pkgs.writeShellScriptBin "llm-model-activate" ''
    set -euo pipefail

    MODE="''${1:-}"
    MODEL_PATH="''${2:-}"
    MMPROJ_PATH="''${3:-}"
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
        echo "Usage: llm-model-activate text MODEL.gguf | ocr MODEL.gguf MMPROJ.gguf" >&2
        exit 1
        ;;
    esac

    REAL_MODEL=$(require_model_path "$MODEL_PATH" "model")
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

    ${pkgs.coreutils}/bin/chmod 0644 "$SERVICE_DIR/active-mode"
  '';

  # Models are copied from ~/models into /var/lib/llama-cpp by llm-model-activate.
  # Text and OCR use separate declarative systemd units; no runtime drop-ins.
  llm-switch = pkgs.writeShellScriptBin "llm-switch" ''
    set -euo pipefail

    MODELS_DIR="$HOME/models"
    SERVICE_DIR="/var/lib/llama-cpp"
    ACTIVE_MODEL="$SERVICE_DIR/active-model.gguf"
    MODE_FILE="$SERVICE_DIR/active-mode"

    MODEL_9B="Qwen3.5-9B-Uncensored-Q4_K_M.gguf"
    MODEL_OPUS="Qwopus3.5-9B-v3-Q4_K_M.gguf"
    MODEL_OCR="GLM-OCR-Q8_0.gguf"
    MMPROJ_OCR="mmproj-GLM-OCR-Q8_0.gguf"

    STAT="${pkgs.coreutils}/bin/stat"
    DU="${pkgs.coreutils}/bin/du"
    CUT="${pkgs.coreutils}/bin/cut"
    SYSTEMCTL="/run/current-system/sw/bin/systemctl"
    ACTIVATE="${llmModelActivate}/bin/llm-model-activate"

    current_size=0
    if [ -f "$ACTIVE_MODEL" ] || [ -L "$ACTIVE_MODEL" ]; then
      current_size=$("$STAT" -c%s "$ACTIVE_MODEL" 2>/dev/null || echo 0)
    fi

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
      9b|9B|uncensored|full)
        target="$MODEL_9B"
        label="Qwen3.5-9B Uncensored (5.6GB)"
        mode="text"
        service="llama-cpp"
        ;;
      opus|OPUS|reasoning)
        target="$MODEL_OPUS"
        label="Qwopus 3.5-9B v3 (5.6GB)"
        mode="text"
        service="llama-cpp"
        ;;
      ocr|OCR|vision)
        target="$MODEL_OCR"
        label="GLM-OCR 0.9B (vision/OCR, 1.4GB)"
        mode="ocr"
        service="llama-cpp-ocr"
        ;;
      status|"")
        if [ "$current_size" = "0" ]; then
          echo "No active model. Run: llm-switch opus  or  llm-switch 9b"
        else
          active_name="unknown"
          for m in "$MODEL_9B" "$MODEL_OPUS" "$MODEL_OCR"; do
            ms=$("$STAT" -c%s "$MODELS_DIR/$m" 2>/dev/null || echo -1)
            [ "$ms" = "$current_size" ] && active_name="$m"
          done
          echo "Active model: $active_name"
          echo "Mode: $(cat "$MODE_FILE" 2>/dev/null || echo text)"
        fi
        echo "Services:"
        echo "  text: $("$SYSTEMCTL" is-active llama-cpp 2>/dev/null || echo unknown)"
        echo "  ocr:  $("$SYSTEMCTL" is-active llama-cpp-ocr 2>/dev/null || echo unknown)"
        echo ""
        echo "Available models:"
        [ -f "$MODELS_DIR/$MODEL_9B" ] && echo "  9b   -> $MODEL_9B (5.6GB) - uncensored" || echo "  9b   -> $MODEL_9B (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_OPUS" ] && echo "  opus -> $MODEL_OPUS (5.6GB) - Qwopus v3" || echo "  opus -> $MODEL_OPUS (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_OCR" ] && echo "  ocr  -> $MODEL_OCR (1.4GB) - vision/OCR" || echo "  ocr  -> $MODEL_OCR (not downloaded)"
        echo ""
        echo "Usage: llm-switch [9b|opus|ocr|status|stop]"
        exit 0
        ;;
      stop)
        echo "Stopping llama-cpp services..."
        stop_services
        echo "LLM stopped."
        exit 0
        ;;
      *)
        echo "Usage: llm-switch [9b|opus|ocr|status|stop]"
        echo "  9b    -> Qwen3.5-9B Uncensored"
        echo "  opus  -> Qwen3.5-9B Opus Reasoning Distilled v2"
        echo "  ocr   -> GLM-OCR (vision/OCR)"
        echo "  stop  -> Stop LLM service"
        exit 1
        ;;
    esac

    if [ ! -f "$MODELS_DIR/$target" ]; then
      echo "Error: $MODELS_DIR/$target not found."
      echo "Download it first."
      exit 1
    fi

    target_size=$("$STAT" -c%s "$MODELS_DIR/$target" 2>/dev/null || echo -1)
    active_mode=$(cat "$MODE_FILE" 2>/dev/null || echo text)
    if [ "$current_size" = "$target_size" ] && [ "$current_size" != "0" ] && [ "$active_mode" = "$mode" ]; then
      echo "Already using $label"
      exit 0
    fi

    echo "Switching to $label..."
    echo "Copying model ($("$DU" -h "$MODELS_DIR/$target" | "$CUT" -f1))..."

    if [ "$mode" = "ocr" ]; then
      if [ ! -f "$MODELS_DIR/$MMPROJ_OCR" ]; then
        echo "Error: $MODELS_DIR/$MMPROJ_OCR not found."
        echo "Download it: wget -P ~/models https://huggingface.co/ggml-org/GLM-OCR-GGUF/resolve/main/$MMPROJ_OCR"
        exit 1
      fi
      sudo "$ACTIVATE" ocr "$MODELS_DIR/$target" "$MODELS_DIR/$MMPROJ_OCR"
    else
      sudo "$ACTIVATE" text "$MODELS_DIR/$target"
    fi

    restart_if_running
  '';

  llm-local = pkgs.writeShellScriptBin "llm-local" ''
    set -euo pipefail

    SYSTEMCTL="/run/current-system/sw/bin/systemctl"
    MODE_FILE="/var/lib/llama-cpp/active-mode"
    MODE=$(cat "$MODE_FILE" 2>/dev/null || echo text)

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

    echo "API: http://127.0.0.1:8080/v1"
    echo "Stop: llm-switch stop"
  '';
in
{
  # llama.cpp - Local LLM inference with AMD GPU acceleration.
  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp; # Uses overlay version, not nixpkgs default
    host = "127.0.0.1";
    port = 8080;
    model = "/var/lib/llama-cpp/active-model.gguf";
    extraFlags = [
      "-ngl"
      "99" # Offload all possible layers to GPU
      "--no-mmap" # Better for iGPU with shared memory
      "-c"
      "8192" # Limit context to 8K
      "--jinja"
      "--chat-template-file"
      "${qwen-no-think-template}"
    ];
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

  systemd.tmpfiles.rules = [
    "d /var/lib/llama-cpp 0755 root root -"
  ];

  systemd.services.llama-cpp.environment = llamaRocmEnvironment;

  # OCR mode uses a separate declarative unit instead of a runtime drop-in.
  systemd.services.llama-cpp-ocr = {
    description = "llama.cpp OCR API server";
    after = [ "network.target" ];
    wantedBy = lib.mkForce [ ];
    environment = llamaRocmEnvironment;
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "llama-cpp";
      WorkingDirectory = "/var/lib/llama-cpp";
      ExecStart = "${pkgs.llama-cpp}/bin/llama-server --log-disable --host 127.0.0.1 --port 8080 -m /var/lib/llama-cpp/active-model.gguf --mmproj /var/lib/llama-cpp/active-mmproj.gguf -ngl 99 --no-mmap -c 8192 --jinja";
      Restart = "on-failure";
      RestartSec = 10;
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  # llm-switch copies models into /var/lib/llama-cpp, so no /home access is needed.
  systemd.services.llama-cpp.serviceConfig.RestartSec = lib.mkForce 10;
}
