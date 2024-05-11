{ pkgs,  ... }:

{
  # Bootloader.
  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 2;
  boot.initrd.enable = true;
  #boot.initrd.systemd.enable = true;
   boot.loader.grub.enable = true;
   boot.loader.grub.efiSupport = true;
   boot.loader.grub.efiInstallAsRemovable = true;

  boot.tmp.cleanOnBoot = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [ 
   # "quiet"
    "fbcon=nodefer"
    "vt.global_cursor_default=0"
    "kernel.modules_disabled=1"
  "lsm=landlock,lockdown,yama,integrity,apparmor,bpf,tomoyo,selinux"
    "usbcore.autosuspend=-1"
    "video4linux"
    "acpi_rev_override=5"
    "security=selinux"
  ];
  # boot.kernelPatches = [ {
  #      name = "selinux-config";
  #      patch = null;
  #      extraConfig = '' 
  #              SECURITY_SELINUX y
  #              SECURITY_SELINUX_BOOTPARAM n
  #              SECURITY_SELINUX_DEVELOP y
  #              SECURITY_SELINUX_AVC_STATS y
  #              DEFAULT_SECURITY_SELINUX n
  #            '';
  # } ];

    
systemd.package = pkgs.systemd.override { withSelinux = true; };

  environment.systemPackages = with pkgs; [
    policycoreutils
  ];


}
