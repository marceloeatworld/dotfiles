# Boot configuration
{ lib, pkgs, ... }:

{
  # Use systemd-boot as the bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5; # 5 generations fit in 512MB ESP
      editor = false; # Disable editing boot parameters for security
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 1; # Quick boot (hold Space for menu)
  };

  # Latest supported kernel for current AMDGPU/Zen 4 laptop fixes.
  # linuxPackages_zen was on the 6.19 branch, which is EOL upstream; latest
  # keeps the Radeon 780M and s2idle stack on the newest maintained code.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Boot-menu fallback in case a latest-kernel regression affects graphics,
  # suspend, Wi-Fi, or thermals. Default remains linuxPackages_latest.
  specialisation.stable-kernel.configuration = {
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    system.nixos.tags = [ "stable-kernel" ];
  };

  # Kernel parameters optimized for Ryzen 7 PRO 8840HS
  boot.kernelParams = [
    "quiet"
    # "splash"  # Disabled (no Plymouth)

    # AMD P-State active mode is provided by nixos-hardware's AMD pstate profile.

    # AMD GPU optimizations for Radeon 780M (RDNA 3 iGPU, gfx1103)
    "amdgpu.gpu_recovery=1" # Enable GPU recovery on hang
    # NOTE: amdgpu.gfx_off removed — invalid param (kernel ignores it). GFXOFF
    #   is already disabled via hardware.amdgpu.overdrive.enable ppfeaturemask
    # NOTE: amdgpu.runpm removed — runtime PM is a dGPU feature only.
    #   iGPU auto-detection already results in RUNPM_NONE (verified in kernel log)

    # FIX: DMCUB errors and display freezes (common on kernel 6.12+)
    # Disables PSR (Panel Self Refresh), PSR-SU, and Panel Replay
    # Fixes: dc_dmub_srv_log_diagnostic_data errors, flip_done timeouts
    # Source: ArchWiki ThinkPad P14s Gen 5 AMD (still recommended as of kernel 6.19)
    "amdgpu.dcdebugmask=0x410"

    # FIX: S/G display flickering and TLB fence timeouts on APU under memory pressure
    # No kernel fix as of 6.19 — still recommended for RDNA 3 APU (especially with ROCm)
    "amdgpu.sg_display=0"

    # NOTE: amdgpu.cwsr_enable=0 removed — fixed in kernel 6.18.17+ (running 6.19.9-zen1)

    # FIX: s2idle resume on AMD Ryzen (ThinkPad P14s Gen 5)
    # acpi.ec_no_wakeup=1 - Prevents ACPI EC from waking device during s2idle
    #   Documented fix for P14s Gen 5 AMD (ArchWiki + Lenovo forums)
    #   Without this, EC repeatedly wakes the device causing it to freeze
    # rtc_cmos.use_acpi_alarm=1 - Ensures RTC wakeup works via ACPI on modern AMD
    "acpi.ec_no_wakeup=1"
    "rtc_cmos.use_acpi_alarm=1"

    # Enable AMD SEV (Secure Encrypted Virtualization) if needed
    # "mem_encrypt=on"  # Uncomment for extra VM security

    # IOMMU for virtualization (KVM/QEMU)
    # NOTE: amd_iommu=on removed - invalid option (AMD IOMMU is enabled by default)
    "iommu=pt"
  ];

  # Plymouth boot splash disabled (faster boot, see boot messages)
  boot.plymouth.enable = false;

  # /tmp in RAM (tmpfs) - 32GB RAM available, reduces SSD wear and speeds up builds
  boot.tmp.useTmpfs = true;

  # Faster boot
  systemd.services.NetworkManager-wait-online.enable = false;

  # Faster shutdown than default, but not so aggressive that libvirt/btrbk/containers
  # are likely to be killed mid-cleanup.
  systemd.settings.Manager.DefaultTimeoutStopSec = "30s";

  # Blacklist AMD NPU driver (firmware not yet properly packaged in nixpkgs)
  # NOTE: boot.blacklistedKernelModules also set in services.nix (dvb_usb_rtl28xxu) - NixOS merges lists
  boot.blacklistedKernelModules = [ "amdxdna" ];

  # NOTE: boot.initrd.systemd NOT enabled - keeps default QWERTY keyboard for LUKS
  # This is intentional: LUKS password was created with QWERTY layout
  # If you want French (AZERTY) keyboard for LUKS, enable boot.initrd.systemd.enable
  # and recreate LUKS with a new password
}
