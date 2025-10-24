# Boot configuration
{ pkgs, ... }:

{
  # Use systemd-boot as the bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;  # Limit number of generations
      editor = false;  # Disable editing boot parameters for security
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    timeout = 3;
  };

  # Latest kernel for best hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters optimized for Ryzen 7 PRO 8840HS
  boot.kernelParams = [
    "quiet"
    "splash"

    # AMD P-State driver (EPP - Energy Performance Preference)
    # Mode "active" for Zen 4 = best performance + power efficiency
    "amd_pstate=active"

    # AMD GPU optimizations for Radeon 780M (RDNA 3)
    "amdgpu.ppfeaturemask=0xffffffff"  # Enable all power features
    "amdgpu.gpu_recovery=1"            # Enable GPU recovery
    "amdgpu.tmz=0"                     # Disable TMZ (not needed for iGPU)

    # Enable AMD SEV (Secure Encrypted Virtualization) if needed
    # "mem_encrypt=on"  # Uncomment for extra VM security

    # IOMMU for virtualization (KVM/QEMU)
    "iommu=pt"
    "amd_iommu=on"
  ];

  # Enable Plymouth for boot splash (optional)
  boot.plymouth.enable = true;

  # Faster boot
  systemd.services.NetworkManager-wait-online.enable = false;
}
