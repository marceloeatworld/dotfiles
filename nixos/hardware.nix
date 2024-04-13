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

  rules = ''
	allow id 18a5:0237 # Verbatim HDD
        allow id 0951:1666 # USB kingstone
        allow id 1d6b:0002 # Linux Foundation 2.0 root hub
        allow id 045e:028e # Microsoft Corp. Xbox360 Controller
        allow id 2f24:0135 # Mouse for Windows
        allow id 1d6b:0003 # Linux Foundation 3.0 root hub
        allow id 05e3:0610 # Genesys Logic, Inc. Hub
        allow id 8087:0032 # Intel Corp. AX210 Bluetooth
        allow id 05e3:0625 # Genesys Logic, Inc. USB3.2 Hub
        allow id 058e:3864 # Tripath Technology, Inc. USB Camera
        allow id 2c7c:0125 # Quectel Wireless Solutions Co., Ltd. EC25 LTE modem
        allow id 2541:9711 # Chipsailing CS9711Fingprint
        allow id 2109:2817 # VIA Labs, Inc. USB2.0 Hub
        allow id 1a40:0101 # Terminus Technology Inc. Hub
        allow id 1e7d:31ce # ROCCAT Ryos MK Glow Keyboard
        allow id 2109:0102 # VIA Labs, Inc. USB 2.0 BILLBOARD
        allow id 0d22:d300 # MSi Interceptor DS300 GAMING Mouse
        allow id 05e3:0751 # Genesys Logic, Inc. microSD Card Reader
        allow id 050d:008a # Belkin Components USB-C 6-in-1 Multiport Adapter
        allow id 2109:0817 # VIA Labs, Inc. USB3.0 Hub
        allow id 0bda:8153 # Realtek Semiconductor Corp. RTL8153 Gigabit Ethernet Adapter
      '';    
  };

  # Enable USB-specific packages
  environment.systemPackages = with pkgs; [
    usbutils
  ];
}
