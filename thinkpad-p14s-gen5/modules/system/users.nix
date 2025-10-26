# User configuration
{ pkgs, ... }:

{
  # Define user account
  users.users.marcelo = {
    isNormalUser = true;
    description = "Marcelo";
    extraGroups = [
      "wheel"          # sudo access
      "networkmanager" # network management
      "video"          # video devices
      "audio"          # audio devices
      "input"          # input devices
      "docker"         # docker (if enabled)
      "libvirtd"       # libvirt/KVM (if enabled)
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
