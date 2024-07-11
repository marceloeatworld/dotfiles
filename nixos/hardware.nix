{ pkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  hardware.enableAllFirmware = true;
  hardware.graphics.enable = true;
  hardware.enableRedistributableFirmware = true;

   # USB Automounting
  services.gvfs.enable = true;
  # services.udisks2.enable = true;
  # services.devmon.enable = true;

  # Enable USB Guard
  services.usbguard = {
    enable = true;
    dbus.enable = true;
    implicitPolicyTarget = "block";
    rules = builtins.readFile ./rules.conf;
  };

  # Enable USB-specific packages
  environment.systemPackages = with pkgs; [
    usbutils
  ];

services.udev.extraRules = ''
    SUBSYSTEM=="usb", SYMLINK+="bitbox02_%n", GROUP="plugdev", MODE="0664", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", SYMLINK+="bitbox02_%n", GROUP="plugdev", MODE="0664", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403"
    SUBSYSTEM=="usb", SYMLINK+="dbb%n", GROUP="plugdev", MODE="0664", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", SYMLINK+="dbbf%n", GROUP="plugdev", MODE="0664", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402"

SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"

'';

}
