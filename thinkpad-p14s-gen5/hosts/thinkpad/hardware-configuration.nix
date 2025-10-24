# Hardware configuration for ThinkPad P14s Gen 5 (AMD)
# Basic hardware detection - AMD-specific optimizations in amd-optimizations.nix

{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules for hardware support
  boot.initrd.availableKernelModules = [
    "nvme"           # NVMe SSD
    "xhci_pci"       # USB 3.0
    "thunderbolt"    # Thunderbolt/USB4
    "usb_storage"    # USB storage
    "sd_mod"         # SD card reader
    "rtsx_pci_sdmmc" # Realtek card reader
  ];

  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Graphics (32-bit support for gaming/Wine)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # AMD GPU driver
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Firmware updates
  services.fwupd.enable = true;

  # Networking
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
