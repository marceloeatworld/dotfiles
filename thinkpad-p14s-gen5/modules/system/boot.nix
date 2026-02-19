# Boot configuration
{ pkgs, ... }:

{
  # Use systemd-boot as the bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;  # 5 generations fit in 512MB ESP
      editor = false;  # Disable editing boot parameters for security
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 3;
  };

  # Zen kernel - optimized for desktop/gaming with better interactivity
  # Lower latency, better responsiveness, improved scheduler (BORE)
  # Also potentially more stable with AMD GPU MES issues
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Kernel parameters optimized for Ryzen 7 PRO 8840HS
  boot.kernelParams = [
    "quiet"
    # "splash"  # Disabled (no Plymouth)

    # AMD P-State driver (EPP - Energy Performance Preference)
    # Mode "active" for Zen 4 = best performance + power efficiency
    "amd_pstate=active"

    # AMD GPU optimizations for Radeon 780M (RDNA 3)
    # NOTE: ppfeaturemask=0xfffd7fff instead of 0xffffffff
    # Bit 17 (0x20000) disabled = PP_GFXOFF_MASK - GFXOFF causes resume failures on RDNA 3 iGPU
    # Symptom: black screen after suspend, GPU fails to reinitialize
    "amdgpu.ppfeaturemask=0xfffd7fff"
    "amdgpu.gpu_recovery=1"            # Enable GPU recovery on hang

    # FIX: DMCUB errors and display freezes (common on kernel 6.12+)
    # Disables PSR (Panel Self Refresh), PSR-SU, and Panel Replay
    # Fixes: dc_dmub_srv_log_diagnostic_data errors, flip_done timeouts
    "amdgpu.dcdebugmask=0x410"

    # Additional stability parameters for AMD display
    "amdgpu.sg_display=0"              # Fixes screen flickering
    "amdgpu.noretry=0"                 # Retry on timeout (default)

    # NOTE: MES workarounds (vm_update_mode=3, cwsr_enable=0) removed
    # They prevented proper GPU suspend/resume in s2idle, causing the PC
    # to not wake from sleep. If random GPU freezes return, re-enable selectively.

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
    "iommu=pt"
    "amd_iommu=on"
  ];

  # Plymouth boot splash disabled (faster boot, see boot messages)
  boot.plymouth.enable = false;

  # Faster boot
  systemd.services.NetworkManager-wait-online.enable = false;

  # Faster shutdown (5s timeout instead of default 90s)
  systemd.settings.Manager.DefaultTimeoutStopSec = "5s";

  # NOTE: boot.initrd.systemd NOT enabled - keeps default QWERTY keyboard for LUKS
  # This is intentional: LUKS password was created with QWERTY layout
  # If you want French (AZERTY) keyboard for LUKS, enable boot.initrd.systemd.enable
  # and recreate LUKS with a new password
}
