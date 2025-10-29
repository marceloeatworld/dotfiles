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

      # GPU power management
      RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
      RADEON_POWER_PROFILE_ON_AC = "high";
      RADEON_POWER_PROFILE_ON_BAT = "low";

      # PCIe power saving
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersupersave";

      # Runtime power management
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  # Alternative: auto-cpufreq (comment out TLP if using this)
  # services.auto-cpufreq.enable = true;

  # Enable laptop mode
  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  # Enable upower for battery monitoring
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "Hibernate";
  };

  # NOTE: thermald is INTEL-ONLY, do NOT enable on AMD systems
  # services.thermald.enable = true;

  # Enable dconf for GTK applications
  programs.dconf.enable = true;

  # Enable D-Bus
  services.dbus.enable = true;

  # NOTE: gnome-keyring configured in security.nix with PAM integration

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

  # Ollama - Local LLM inference with AMD GPU acceleration
  services.ollama = {
    enable = true;
    package = pkgs-unstable.ollama;  # Use latest version from unstable for new models
    acceleration = "rocm";  # AMD GPU support via ROCm

    # AMD Radeon 780M (gfx1103) requires override
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # Fix for RDNA 3 iGPU
      ROCR_VISIBLE_DEVICES = "0";           # Use first GPU
      ROC_ENABLE_PRE_VEGA = "1";            # Compatibility
    };

    # Host address (IP only, port is separate)
    host = "127.0.0.1";
    port = 11434;

    # Models will be stored in /var/lib/ollama
  };

  # BitBox Bridge - Hardware wallet communication bridge
  # Provides udev rules and WebSocket bridge for BitBox02 hardware wallets
  services.bitbox-bridge = {
    enable = true;
    runOnMount = true;  # Only run when BitBox is plugged in (saves power)
  };
}
