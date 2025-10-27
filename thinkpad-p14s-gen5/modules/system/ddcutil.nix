# DDC/CI support for external monitor brightness control
{ pkgs, ... }:

{
  # Install ddcutil
  environment.systemPackages = with pkgs; [
    ddcutil
  ];

  # Load i2c-dev kernel module at boot
  boot.kernelModules = [ "i2c-dev" ];

  # Configure i2c permissions for ddcutil
  hardware.i2c.enable = true;

  # Add ddcutil-recommended udev rules for better i2c device access
  services.udev.extraRules = ''
    # Grant access to i2c devices for video cards (ddcutil recommended)
    SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", TAG+="uaccess"
    SUBSYSTEM=="i2c-dev", KERNEL=="i2c-[0-9]*", ATTRS{class}=="0x030000", GROUP="i2c", MODE="0660"
  '';
}
