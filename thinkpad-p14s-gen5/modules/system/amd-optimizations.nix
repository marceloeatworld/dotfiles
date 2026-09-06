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

    # AMD GPU/CPU + WiFi firmware all ship in linux-firmware (redistributable);
    # no non-redistributable blob is needed on this hardware, so the narrower
    # option keeps the closure smaller than enableAllFirmware.
    hardware.enableRedistributableFirmware = true;

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

    # Sysctls live in performance.nix, amdgpu.* kernel parameters in boot.nix,
    # amd-pstate active mode comes from the nixos-hardware P14s profile, and
    # CPU boost is TLP's job (services.nix).

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

    environment.systemPackages = with pkgs; [
      # AMD monitoring tools
      lm_sensors # Hardware monitoring (sensors command)
      radeontop # GPU usage monitor

      # Power monitoring
      powertop

      # Storage health (smartd service configured in services.nix)
      smartmontools # smartctl
      nvme-cli # NVMe-specific health/error-log queries

      # Vulkan CLI tools (vulkaninfo, vkcube) — CLI, not drivers
      vulkan-tools
    ];
  };
}
