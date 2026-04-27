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
      "audio"          # audio devices
      "podman"         # podman (rootless containers)
      "libvirtd"       # libvirt/KVM (if enabled)
      "i2c"            # i2c devices for DDC/CI monitor control
      "plugdev"        # USB devices (rtl-sdr dongles)
    ];
    shell = pkgs.zsh;

    # Password will be set during installation with: nixos-enter && passwd marcelo
    # initialPassword = "changeme";  # REMOVED for security
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;

  # Allow users in wheel group to use sudo without password
  # Change this to require password for better security if desired
  security.sudo.wheelNeedsPassword = true;
}
