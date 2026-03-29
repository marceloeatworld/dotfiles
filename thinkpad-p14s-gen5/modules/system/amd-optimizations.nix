# AMD-specific optimizations for Ryzen 7 PRO 8840HS + Radeon 780M
{ config, lib, pkgs, ... }:

{
  # NOTE: CPU Governor is managed by TLP in services.nix
  # TLP handles CPU_SCALING_GOVERNOR_ON_AC/BAT dynamically
  # Do not set powerManagement.cpuFreqGovernor here to avoid conflicts

  # AMD CPU microcode updates
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # AMD kernel modules: SEV, sensors, suspend
  # NOTE: kvm-amd is in hardware-configuration.nix (auto-generated)
  boot.kernelModules = [ "ccp" "k10temp" "amd_pmc" ];

  # AMD GPU firmware (enableAllFirmware includes enableRedistributableFirmware)
  hardware.enableAllFirmware = true;

  # LACT - Linux AMDGPU Control Tool
  # GUI for overclock/undervolt/fan control for Radeon 780M
  # NOTE: LACT (Linux AMDGPU Control Tool) - enable when available
  # services.lact.enable = true;

  # Enable AMD GPU overclocking features (works independently of LACT service)
  # This allows manual GPU control and is required if installing LACT later
  hardware.amdgpu.overdrive.enable = true;

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
    RADV_PERFTEST = "nggc"; # NGG Culling for RDNA 3 (gpl removed - default since Mesa 23.1)

    # OpenCL for compute workloads (ROCm)
    OCL_ICD_VENDORS = "${pkgs.rocmPackages.clr.icd}/etc/OpenCL/vendors";

    # VA-API driver for hardware video acceleration (VDPAU removed from Mesa 25.3+)
    LIBVA_DRIVER_NAME = "radeonsi";

    # Mesa tweaks for Radeon 780M
    MESA_LOADER_DRIVER_OVERRIDE = "radeonsi"; # Use RadeonSI for OpenGL

    # mesa_glthread removed - enabled by default since Mesa 22.3 for radeonsi
  };

  # NOTE: All sysctl settings are consolidated in performance.nix
  # (vm.swappiness, vm.vfs_cache_pressure, kernel.nmi_watchdog)

  # CPU frequency scaling for Zen 4
  # AMD P-State EPP provides better performance than acpi-cpufreq
  # NOTE: initcall_blacklist=acpi_cpufreq_init removed - redundant with amd_pstate=active in boot.nix
  # NOTE: GPU parameters are in boot.nix to centralize boot configuration
  # See boot.nix for amdgpu.* kernel parameters including DMCUB fix

  # NOTE: CPU boost is managed by TLP in services.nix
  # TLP handles CPU_BOOST_ON_AC and CPU_BOOST_ON_BAT dynamically
  # Do not force boost settings here to avoid conflicts with TLP

  # NOTE: linux-firmware already included by hardware.enableAllFirmware = true (line 16)

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

  # NOTE: thermald is Intel-only and NOT compatible with AMD CPUs

  environment.systemPackages = with pkgs; [
    # AMD monitoring tools
    lm_sensors   # Hardware monitoring (sensors command)
    radeontop    # GPU usage monitor
    # NOTE: LACT can be added when available in nixpkgs:
    # lact

    # Power monitoring
    powertop
  ];
}
