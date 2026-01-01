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
    "amdgpu.ppfeaturemask=0xffffffff"  # Enable all power features
    "amdgpu.gpu_recovery=1"            # Enable GPU recovery on hang
    "amdgpu.tmz=0"                     # Disable TMZ (not needed for iGPU)

    # FIX: DMCUB errors and display freezes (common on kernel 6.12+)
    # Disables PSR (Panel Self Refresh), PSR-SU, and Panel Replay
    # Fixes: dc_dmub_srv_log_diagnostic_data errors, flip_done timeouts
    "amdgpu.dcdebugmask=0x410"

    # Additional stability parameters for AMD display
    "amdgpu.sg_display=0"              # Fixes screen flickering
    "amdgpu.noretry=0"                 # Retry on timeout (default)

    # MES (Micro Engine Scheduler) stability workarounds
    # Fixes random freezes on RDNA3 GPUs (Radeon 780M)
    "amdgpu.vm_update_mode=3"          # Force CPU for compute queue updates
    "amdgpu.cwsr_enable=0"             # Reduce GPU context switching

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
