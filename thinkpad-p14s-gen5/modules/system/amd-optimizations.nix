# AMD-specific optimizations for Ryzen 7 PRO 8840HS + Radeon 780M
{ config, lib, pkgs, ... }:

{
  # CPU Governor - AMD P-State EPP (Energy Performance Preference)
  # Zen 4 architecture supports advanced power management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "schedutil"; # Better than "powersave" for Zen 4
  };

  # AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable AMD SEV (Secure Encrypted Virtualization) support
  boot.kernelModules = [ "kvm-amd" "ccp" ];

  # AMD GPU firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # LACT - Linux AMDGPU Control Tool
  # GUI for overclock/undervolt/fan control for Radeon 780M
  services.lact = {
    enable = true;
  };

  # Vulkan layers and ROCm for AMD
  hardware.graphics.extraPackages = with pkgs; [
    # Vulkan tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    vulkan-extension-layer

    # ROCm OpenCL for AI/ML workloads
    rocmPackages.clr.icd

    # Note: amdvlk removed - using RADV (Mesa) exclusively for better performance
  ];

  # ROCm hip symlink for compatibility
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # Mesa environment variables for better performance
  environment.variables = {
    # Force Vulkan ICD to use RADV (Mesa) instead of AMDVLK
    # RADV has better performance for Radeon 780M
    VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";

    # AMD GPU optimizations
    AMD_VULKAN_ICD = "RADV";
    RADV_PERFTEST = "gpl,nggc"; # Enable GPL (Graphics Pipeline Library) and NGG Culling

    # OpenCL for compute workloads (ROCm)
    OCL_ICD_VENDORS = "${pkgs.rocmPackages.clr.icd}/etc/OpenCL/vendors";

    # Mesa tweaks for Radeon 780M
    MESA_LOADER_DRIVER_OVERRIDE = "radeonsi"; # Use RadeonSI for OpenGL

    # Enable threaded optimization
    mesa_glthread = "true";
  };

  # Sysctl tweaks for AMD
  boot.kernel.sysctl = {
    # VM (Virtual Memory) optimizations
    "vm.swappiness" = 10; # Reduce swap usage (we have 16GB+ RAM)
    "vm.vfs_cache_pressure" = 50; # Keep more inodes/dentries in cache

    # Disable watchdog (can cause issues with AMD)
    "kernel.nmi_watchdog" = 0;
  };

  # CPU frequency scaling for Zen 4
  # AMD P-State EPP provides better performance than acpi-cpufreq
  boot.kernelParams = [
    "initcall_blacklist=acpi_cpufreq_init" # Disable old driver
  ];

  # Enable CPU boost
  systemd.tmpfiles.rules = [
    "w /sys/devices/system/cpu/cpufreq/boost - - - - 1"
  ];

  # AMD PSP (Platform Security Processor) firmware
  # Required for fTPM and SEV
  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # Performance tuning for NVMe SSD
  services.udev.extraRules = ''
    # NVMe power management
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{power/control}="auto"

    # Set I/O scheduler to none for NVMe (best for SSDs)
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
  '';

  # Zen 4 specific optimizations
  # Enable AVX-512 support (Ryzen 7 PRO 8840HS supports it)
  nix.settings = {
    system-features = [ "gccarch-znver4" "avx512" "avx2" "sse4" ];
  };

  # Thermald configuration in services.nix to avoid duplication
  # services.thermald.enable = true;

  # AMD Sensors monitoring
  boot.kernelModules = [ "k10temp" ]; # CPU temperature sensor

  environment.systemPackages = with pkgs; [
    # AMD monitoring tools
    lm_sensors   # Hardware monitoring (sensors command)
    radeontop    # GPU usage monitor

    # LACT GUI (already enabled as service above)
    lact

    # Power monitoring
    powertop
  ];
}
