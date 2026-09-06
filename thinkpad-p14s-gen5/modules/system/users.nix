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

    # Password is set during installation with: nixos-enter && passwd marcelo
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;

  # Require a password for sudo from users in the wheel group
  # Set to false to allow passwordless sudo (less secure)
  security.sudo.wheelNeedsPassword = true;
  # security.sudo.execWheelOnly must stay off: the btrbk service runs as the
  # unprivileged "btrbk" user and takes snapshots through "sudo -n btrfs"
  # (NixOS btrbk module sudo rules). With the wrapper restricted to wheel,
  # every hourly snapshot failed with "/run/wrappers/bin/sudo: Permission
  # denied" (2026-09-06 02:00).
}
