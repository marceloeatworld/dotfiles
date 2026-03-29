# System services configuration
{ pkgs, ... }:

let
  # Script to switch between LLM models for llama-cpp
  # Models are stored in ~/models but symlinked to /var/lib/llama-cpp/ for service access
  # Vision models (OCR) use a systemd drop-in override to add --mmproj and remove text-only flags
  llm-switch = pkgs.writeShellScriptBin "llm-switch" ''
    MODELS_DIR="$HOME/models"
    SERVICE_DIR="/var/lib/llama-cpp"
    SYMLINK="$SERVICE_DIR/active-model.gguf"
    MMPROJ_SYMLINK="$SERVICE_DIR/active-mmproj.gguf"
    DROPIN_DIR="/run/systemd/system/llama-cpp.service.d"
    DROPIN_FILE="$DROPIN_DIR/override.conf"

    MODEL_4B="Qwen3.5-4B-Q4_K_M.gguf"
    MODEL_9B="Qwen3.5-9B-Uncensored-Q4_K_M.gguf"
    MODEL_OCR="GLM-OCR-Q8_0.gguf"
    MMPROJ_OCR="mmproj-GLM-OCR-Q8_0.gguf"

    LN="${pkgs.coreutils}/bin/ln"
    BASENAME="${pkgs.coreutils}/bin/basename"
    READLINK="${pkgs.coreutils}/bin/readlink"
    SYSTEMCTL="/run/current-system/sw/bin/systemctl"
    LLAMA_SERVER="${pkgs.llama-cpp}/bin/llama-server"

    current=""
    if [ -L "$SYMLINK" ]; then
      current=$($BASENAME "$($READLINK "$SYMLINK")")
    fi

    # Remove vision drop-in override (used when switching away from OCR)
    remove_dropin() {
      if [ -d "$DROPIN_DIR" ]; then
        sudo ${pkgs.coreutils}/bin/rm -rf "$DROPIN_DIR"
        sudo $SYSTEMCTL daemon-reload
      fi
    }

    # Create vision drop-in override (adds --mmproj, removes text-only flags)
    create_dropin() {
      sudo ${pkgs.coreutils}/bin/mkdir -p "$DROPIN_DIR"
      echo "[Service]
ExecStart=
ExecStart=$LLAMA_SERVER --log-disable --host 127.0.0.1 --port 8080 -m $SERVICE_DIR/active-model.gguf --mmproj $SERVICE_DIR/active-mmproj.gguf -ngl 99 --no-mmap -c 8192 --jinja" | sudo ${pkgs.coreutils}/bin/tee "$DROPIN_FILE" > /dev/null
      sudo $SYSTEMCTL daemon-reload
    }

    case "''${1:-}" in
      4b|4B|light|lite)
        target="$MODEL_4B"
        label="Qwen3.5-4B (light, 2.7GB)"
        ;;
      9b|9B|uncensored|full)
        target="$MODEL_9B"
        label="Qwen3.5-9B Uncensored (5.6GB)"
        ;;
      ocr|OCR|vision)
        target="$MODEL_OCR"
        label="GLM-OCR 0.9B (vision/OCR, 1.4GB)"
        ;;
      status|"")
        if [ -z "$current" ]; then
          echo "No active model. Run: llm-switch 4b  or  llm-switch 9b"
        else
          echo "Active model: $current"
          [ -f "$DROPIN_FILE" ] && echo "Mode: vision (mmproj active)" || echo "Mode: text"
        fi
        echo ""
        echo "Available models:"
        [ -f "$MODELS_DIR/$MODEL_4B" ] && echo "  4b   → $MODEL_4B (2.7GB) - fast, lightweight" || echo "  4b   → $MODEL_4B (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_9B" ] && echo "  9b   → $MODEL_9B (5.6GB) - uncensored" || echo "  9b   → $MODEL_9B (not downloaded)"
        [ -f "$MODELS_DIR/$MODEL_OCR" ] && echo "  ocr  → $MODEL_OCR (1.4GB) - vision/OCR" || echo "  ocr  → $MODEL_OCR (not downloaded)"
        echo ""
        echo "Usage: llm-switch [4b|9b|ocr|status|stop]"
        exit 0
        ;;
      stop)
        echo "Stopping llama-cpp..."
        sudo $SYSTEMCTL stop llama-cpp
        echo "LLM stopped."
        exit 0
        ;;
      *)
        echo "Usage: llm-switch [4b|9b|ocr|status|stop]"
        echo "  4b    → Qwen3.5-4B (light, fast)"
        echo "  9b    → Qwen3.5-9B Uncensored"
        echo "  ocr   → GLM-OCR (vision/OCR)"
        echo "  stop  → Stop LLM service"
        exit 1
        ;;
    esac

    if [ ! -f "$MODELS_DIR/$target" ]; then
      echo "Error: $MODELS_DIR/$target not found."
      echo "Download it first."
      exit 1
    fi

    if [ "$current" = "$target" ]; then
      echo "Already using $label"
      exit 0
    fi

    echo "Switching to $label..."
    sudo $LN -sf "$MODELS_DIR/$target" "$SYMLINK"

    if [ "$target" = "$MODEL_OCR" ]; then
      # Vision model: symlink mmproj + create systemd drop-in
      if [ ! -f "$MODELS_DIR/$MMPROJ_OCR" ]; then
        echo "Error: $MODELS_DIR/$MMPROJ_OCR not found."
        echo "Download it: wget -P ~/models https://huggingface.co/ggml-org/GLM-OCR-GGUF/resolve/main/$MMPROJ_OCR"
        exit 1
      fi
      sudo $LN -sf "$MODELS_DIR/$MMPROJ_OCR" "$MMPROJ_SYMLINK"
      create_dropin
    else
      # Text model: remove vision drop-in, symlink chat template
      remove_dropin
      if [ -f "$MODELS_DIR/qwen3.5-no-think.jinja" ]; then
        sudo $LN -sf "$MODELS_DIR/qwen3.5-no-think.jinja" "$SERVICE_DIR/qwen3.5-no-think.jinja"
      fi
    fi

    sudo $SYSTEMCTL restart llama-cpp
    echo "Done. LLM now running with $label"
  '';
in
{
  # Enable CUPS for printing
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      brlaser  # Brother laser printers only
    ];
  };

  # Avahi for network printer discovery
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Power management with TLP (optimized for AMD)
  services.tlp = {
    enable = true;
    settings = {
      # CPU settings
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 60;

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Battery care
      # Note: Conservation mode 55-60% for always-plugged usage (maximizes lifespan)
      # Change to 75-80 for balanced use, or 95-100 for full charge
      START_CHARGE_THRESH_BAT0 = 55;
      STOP_CHARGE_THRESH_BAT0 = 60;

      # NOTE: RADEON_DPM/RADEON_POWER_PROFILE removed - only for legacy radeon driver
      # Radeon 780M uses amdgpu driver, managed via kernel sysfs and TLP's AMDGPU_ABM_LEVEL

      # PCIe power saving
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";  # "powersupersave" can cause GPU hangs and link recovery failures on AMD

      # Runtime power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # Disk devices (NVMe - APM not applicable, NVMe uses APST natively)
      DISK_DEVICES = "nvme0n1";

      # USB autosuspend (saves ~0.5W per idle device)
      USB_AUTOSUSPEND = 1;

      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # Audio power saving (snd_hda_intel)
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      # AMD Adaptive Backlight Management (saves power by adjusting panel brightness at GPU level)
      # Values: 0=off, 1=light, 2=medium, 3=aggressive, 4=maximum
      AMDGPU_ABM_LEVEL_ON_AC = 0;
      AMDGPU_ABM_LEVEL_ON_BAT = 3;

      # Platform profile (AMD-specific)
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };

  # Alternative: auto-cpufreq (comment out TLP if using this)
  # services.auto-cpufreq.enable = true;

  # Enable laptop mode (powertop auto-tune disabled - conflicts with TLP)
  powerManagement = {
    enable = true;
    powertop.enable = false;
  };

  # Logind: lid switch and power button handling
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";              # Lid close → suspend
    HandleLidSwitchExternalPower = "suspend"; # Same behavior on AC
    HandlePowerKey = "suspend";
    # s2idle (freeze) is the only mode available on this hardware (no S3 deep sleep)
    # Tradeoff: faster wake but higher battery drain (~2-5%/hr vs <1%/hr with S3)
    SuspendState = "freeze";
  };

  # Enable upower for battery monitoring
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "PowerOff";  # Hibernate is not configured (kernel params commented out in btrfs.nix)
  };

  # NOTE: thermald is INTEL-ONLY, do NOT enable on AMD systems
  # services.thermald.enable = true;

  # Disable XHC0 ACPI wakeup to reach deepest s2idle state
  # XHC0 is the main USB3 controller that causes spurious wakeups on Lenovo ThinkPads
  # Without this, amd_pmc reports "Last suspend didn't reach deepest state" → freeze on resume
  # Keyboard/trackpad (PS/2 or internal USB) and LID/SLPB still wake the system
  # Reference: https://github.com/0FL01/fix-s2idle-instant-wakeup (Lenovo-specific fix)
  systemd.services.disable-usb-wakeup = {
    description = "Disable XHC0 wakeup for deeper s2idle";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if grep -q "XHC0.*enabled" /proc/acpi/wakeup 2>/dev/null; then
        echo "XHC0" > /proc/acpi/wakeup
      fi
    '';
  };

  # Enable dconf for GTK applications
  programs.dconf.enable = true;

  # Enable D-Bus
  services.dbus.enable = true;

  # Enable udisks2 for automatic mounting
  services.udisks2.enable = true;

  # Enable GVFS for virtual filesystems
  services.gvfs.enable = true;

  # Flatpak support (optional)
  services.flatpak.enable = true;

  # Locate database (plocate - fast file indexing)
  services.locate = {
    enable = true;
    package = pkgs.plocate;
    # Note: localuser option removed in modern NixOS (only for findutils)
  };

  # llama.cpp - Local LLM inference with AMD GPU acceleration (replaces Ollama)
  # API compatible with OpenAI format on http://127.0.0.1:8080
  # Models: ~/models/*.gguf (downloaded from Hugging Face)
  # Switch models with: llm-switch (toggles between 4B and 9B)
  services.llama-cpp = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    model = "/var/lib/llama-cpp/active-model.gguf";  # Symlink managed by llm-switch
    extraFlags = [
      "-ngl" "99"       # Offload all possible layers to GPU (llama.cpp caps at available)
      "--no-mmap"       # Better for iGPU with shared memory
      "-c" "8192"       # Limit context to 8K (default=max model ctx, wastes VRAM on iGPU)
      "--jinja"
      "--chat-template-file" "/var/lib/llama-cpp/qwen3.5-no-think.jinja"  # Reliably disables thinking
    ];
  };

  # llm-switch command to toggle between models
  environment.systemPackages = [ llm-switch ];

  # Create /var/lib/llama-cpp/ directory for model symlinks (readable by service)
  systemd.tmpfiles.rules = [
    "d /var/lib/llama-cpp 0755 root root -"
  ];

  # AMD Radeon 780M (gfx1103) ROCm environment for llama-cpp
  # NOTE: HSA_OVERRIDE_GFX_VERSION also set in home.nix for user-session GPU tools (hashcat, etc.)
  systemd.services.llama-cpp.environment = {
    HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # Fix for RDNA 3 iGPU
    ROCR_VISIBLE_DEVICES = "0";           # Use first GPU
    ROC_ENABLE_PRE_VEGA = "1";            # Compatibility
  };

  # BitBox Bridge - Hardware wallet communication bridge
  # Provides udev rules and WebSocket bridge for BitBox02 hardware wallets
  services.bitbox-bridge = {
    enable = true;
    runOnMount = true;  # Only run when BitBox is plugged in (saves power)
  };

  # RTL-SDR and SDR device support
  # Udev rules allow non-root access to SDR dongles
  # Blacklist DVB-T kernel module (conflicts with SDR use)
  # NOTE: boot.blacklistedKernelModules also set in boot.nix (amdxdna) - NixOS merges lists
  services.udev.packages = [ pkgs.rtl-sdr ];
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];
}
