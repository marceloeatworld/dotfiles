# System services configuration
{ pkgs, ... }:

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
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

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

  # Enable thermald for thermal management
  services.thermald.enable = true;

  # Enable dconf for GTK applications
  programs.dconf.enable = true;

  # Enable D-Bus
  services.dbus.enable = true;

  # Gnome Keyring (password management)
  services.gnome.gnome-keyring.enable = true;

  # Enable udisks2 for automatic mounting
  services.udisks2.enable = true;

  # Enable GVFS for virtual filesystems
  services.gvfs.enable = true;

  # Flatpak support (optional)
  services.flatpak.enable = true;

  # Locate database
  services.locate = {
    enable = true;
    package = pkgs.plocate;
    localuser = null;
  };

  # Ollama - Local LLM inference with AMD GPU acceleration
  services.ollama = {
    enable = true;
    acceleration = "rocm";  # AMD GPU support via ROCm

    # AMD Radeon 780M (gfx1103) requires override
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";  # Fix for RDNA 3 iGPU
      ROCR_VISIBLE_DEVICES = "0";           # Use first GPU
      ROC_ENABLE_PRE_VEGA = "1";            # Compatibility
    };

    # Listen on all interfaces (for API access)
    # Default: http://localhost:11434
    listenAddress = "127.0.0.1:11434";

    # Models will be stored in /var/lib/ollama
  };
}
