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

  # Add user to i2c group (created by hardware.i2c.enable)
  users.users.marcelo.extraGroups = [ "i2c" ];
}
