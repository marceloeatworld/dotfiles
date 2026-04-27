# AMD-specific optimizations for Ryzen 7 PRO 8840HS + Radeon 780M
{ config, lib, pkgs, ... }:

let
  rocmCfg = config.hardware.amd.rocm;
in
{
  options.hardware.amd.rocm.gfxVersion = lib.mkOption {
    type = lib.types.str;
    default = "11.0.0";
    description = ''
      ROCm GFX override used by RDNA 3 iGPU workloads that do not yet
      identify the Radeon 780M correctly.
    '';
  };

  config = {
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
    # NOTE: Keep overdrive disabled unless actively tuning with LACT/pp_od_clk_voltage.
    # services.lact.enable = true;

    hardware.amdgpu.overdrive.enable = false;

    # Vulkan layers and ROCm for AMD
    hardware.graphics.extraPackages = with pkgs; [
      # Loader + layers live here (discovered by the Vulkan runtime)
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
      # Use RADV (Mesa) Vulkan driver exclusively (AMDVLK not installed)
      AMD_VULKAN_ICD = "RADV";
      RADV_PERFTEST = "nggc"; # NGG Culling — still required for GFX11/RDNA 3 (not yet default in Mesa 25.x)

      # OpenCL for compute workloads (ROCm)
      OCL_ICD_VENDORS = "${pkgs.rocmPackages.clr.icd}/etc/OpenCL/vendors";

      # VA-API driver for hardware video acceleration (VDPAU removed from Mesa 25.3+)
      LIBVA_DRIVER_NAME = "radeonsi";

      # Mesa tweaks for Radeon 780M
      MESA_LOADER_DRIVER_OVERRIDE = "radeonsi"; # Use RadeonSI for OpenGL

      # mesa_glthread removed - enabled by default since Mesa 22.3 for radeonsi
    };

    environment.sessionVariables = {
      # Required for Radeon 780M ROCm/hashcat/llama.cpp acceleration.
      HSA_OVERRIDE_GFX_VERSION = rocmCfg.gfxVersion;
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
      lm_sensors # Hardware monitoring (sensors command)
      radeontop # GPU usage monitor
      # NOTE: LACT can be added when available in nixpkgs:
      # lact

      # Power monitoring
      powertop

      # Vulkan CLI tools (vulkaninfo, vkcube) — CLI, not drivers
      vulkan-tools
    ];
  };
}
