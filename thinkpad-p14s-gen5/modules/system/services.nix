# System services configuration
{ pkgs, ... }:

{
  # Enable CUPS for printing
  services.printing = {
    enable = true;
    # Keep local/manual printing support, but avoid the always-running remote
    # printer discovery daemon.
    browsed.enable = false;
    drivers = with pkgs; [
      brlaser # Brother laser printers only
    ];
  };

  # Avahi for mDNS and manual/network printer discovery
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
      # With amd-pstate-epp, the "performance" governor forces EPP to
      # performance permanently. Use the active-mode default governor and let
      # EPP/platform profile keep the laptop reactive without full-throttle idle.
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

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
      PCIE_ASPM_ON_BAT = "powersave"; # "powersupersave" can cause GPU hangs and link recovery failures on AMD

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
      PLATFORM_PROFILE_ON_AC = "balanced";
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

  # Journald: cap log storage to reduce SSD wear
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    SystemKeepFree=1G
    MaxFileSec=1week
  '';

  # Logind: lid switch and power button handling
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend"; # Lid close → suspend
    HandleLidSwitchExternalPower = "suspend"; # Same behavior on AC
    HandlePowerKey = "suspend";
    HandleHibernateKey = "ignore";
  };

  systemd.sleep.settings.Sleep = {
    # s2idle (freeze) is the only mode available on this hardware (no S3 deep sleep)
    # Tradeoff: faster wake but higher battery drain (~2-5%/hr vs <1%/hr with S3)
    SuspendState = "freeze";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Enable upower for battery monitoring
  services.upower = {
    enable = true;
    percentageLow = 15;
    percentageCritical = 5;
    percentageAction = 3;
    criticalPowerAction = "PowerOff"; # Hibernation is intentionally disabled in sleep.conf.
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

  # Enable udisks2 for automatic mounting
  services.udisks2.enable = true;

  # Enable GVFS for virtual filesystems
  services.gvfs.enable = true;

  # Locate database (plocate - fast file indexing)
  services.locate = {
    enable = true;
    package = pkgs.plocate;
    # Note: localuser option removed in modern NixOS (only for findutils)
  };

  # BitBox Bridge - Hardware wallet communication bridge
  # Provides udev rules and WebSocket bridge for BitBox02 hardware wallets
  services.bitbox-bridge = {
    enable = true;
    runOnMount = true; # Only run when BitBox is plugged in (saves power)
  };

  # Udev rules for USB device access (non-root)
  # - rtl-sdr: SDR dongles
  # - qFlipper: Flipper Zero device
  # Blacklist DVB-T kernel module (conflicts with SDR use)
  # NOTE: boot.blacklistedKernelModules also set in boot.nix (amdxdna) - NixOS merges lists
  services.udev.packages = [
    pkgs.rtl-sdr
    pkgs.qFlipper
  ];
  boot.blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];
}
