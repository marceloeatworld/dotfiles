{ pkgs, ... }:

{
  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;

  hardware.enableAllFirmware = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.enableRedistributableFirmware = true;
  hardware.opengl.extraPackages = with pkgs; [
      rocm-opencl-icd
      rocm-opencl-runtime
      amdvlk
  ];

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
#  rules =''
#<usbguard>
#	allow id {18a5:0237}
#        allow id {0951:1666}
#        allow id {1d6b:0002}
#        allow id {045e:028e}
#        allow id {2f24:0135}
#        allow id {1d6b:0003}
 #       allow id {05e3:0610}
 #       allow id {8087:0032}
 ##       allow id {05e3:0625}
 #       allow id {058e:3864}
 #       allow id {2c7c:0125}
 #       allow id {2541:9711}
 #       allow id {2109:2817}
 #       allow id {1a40:0101}
  #      allow id {1e7d:31ce}
  ##      allow id {2109:0102}
  #      allow id {0d22:d300}
  #      allow id {05e3:0751}
  #      allow id {050d:008a}
  #      allow id {2109:0817}
  #      allow id {0bda:8153}
#</usbguard>
#'';
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
