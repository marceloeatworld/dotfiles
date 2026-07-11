# User configuration
{ pkgs, ... }:

{
  # Create netdev group (required by Avahi D-Bus configuration)
  users.groups.netdev = {};

  # Create plugdev group (referenced by rtl-sdr udev rules, absent on NixOS by default)
  users.groups.plugdev = {};

  # Define user account
  users.users.marcelo = {
    isNormalUser = true;
    description = "Marcelo";
    extraGroups = [
      "wheel"          # sudo access
      "networkmanager" # network management
      "video"          # video devices
      "podman"         # podman (rootless containers)
      "libvirtd"       # libvirt/KVM (if enabled)
      "i2c"            # i2c devices for DDC/CI monitor control
      "plugdev"        # USB devices (rtl-sdr dongles)
      "dialout"        # serial ports (Arduino, CH340/CH341 USB-serial)
    ];
    shell = pkgs.zsh;

    # Password will be set during installation with: nixos-enter && passwd marcelo
    # initialPassword = "changeme";  # REMOVED for security
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;

  # Require a password for sudo from users in the wheel group
  # Set to false to allow passwordless sudo (less secure)
  security.sudo.wheelNeedsPassword = true;
}
