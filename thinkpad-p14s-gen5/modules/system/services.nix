# System services configuration
{ pkgs, pkgs-unstable, ... }:

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
  services.llama-cpp = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    model = "/home/marcelo/models/Dolphin-X1-8B-Q8_0.gguf";  # Default model for server
    extraFlags = [
      "-ngl" "99"       # Offload all layers to GPU
      "--no-mmap"       # Better for iGPU with shared memory
    ];
  };

  # AMD Radeon 780M (gfx1103) ROCm environment for llama-cpp
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
  services.udev.packages = [ pkgs.rtl-sdr ];
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];
}
