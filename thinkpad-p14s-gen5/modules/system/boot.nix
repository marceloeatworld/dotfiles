# Boot configuration
{ pkgs, ... }:

{
  # Use systemd-boot as the bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5; # 5 generations fit in 512MB ESP
      editor = false; # Disable editing boot parameters for security
      consoleMode = "1"; # 80x50 firmware text mode - smaller boot menu text than mode 0
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
  # KNOWN ISSUE on 7.1.3: reboot/poweroff hangs at the final hardware reset
  # when the external HDMI monitor is connected (amdgpu DCN teardown wedge,
  # open upstream: drm/amd #4922, #4838). Unplug HDMI before shutdown, or
  # use: sync && systemctl reboot -ff
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters optimized for Ryzen 7 PRO 8840HS
  # Show kernel info messages while booting (default 4 only shows warnings)
  boot.consoleLogLevel = 6;

  boot.kernelParams = [
    # "quiet" removed - kernel messages visible at boot (console font in locale.nix)
    # "splash"  # Disabled (no Plymouth)

    # NOTE: fbcon=font:TER16x32 removed - 32px kernel font was too big; the
    # first messages use the kernel default (8x16) until the initrd loads
    # the Terminus font configured in locale.nix

    # AMD P-State active mode is provided by nixos-hardware's AMD pstate profile.

    # AMD GPU optimizations for Radeon 780M (RDNA 3 iGPU, gfx1103)
    "amdgpu.gpu_recovery=1" # Enable GPU recovery on hang
    # NOTE: amdgpu.gfx_off removed — invalid param (kernel ignores it). GFXOFF
    #   stays at the kernel default (enabled: ppfeaturemask 0xfff7bfff; overdrive.enable=false applies no override), good for iGPU battery life
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

    # NOTE: amdgpu.cwsr_enable=0 removed — fixed in kernel 6.18.17+

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

  # /tmp in RAM (tmpfs) - reduces SSD wear for user temp files. Nix >=2.29 builds in /nix/var/nix/builds (on-disk @nix), not /tmp, so the 14G tmpfs (50% of ~27GiB MemTotal) does not constrain builds
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
