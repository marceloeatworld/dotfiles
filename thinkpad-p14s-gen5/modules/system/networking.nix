# Networking configuration
{ ... }:

{
  # Enable NetworkManager for easy network management
  networking.networkmanager = {
    enable = true;
    wifi.powersave = true;
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  # Enable WiFi 6E support
  hardware.enableRedistributableFirmware = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true;
      };
    };
  };

  # Bluetooth manager
  services.blueman.enable = true;
}
