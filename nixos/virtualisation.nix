{ pkgs, ... }:

{
  # Enable Containerd
  # virtualisation.containerd.enable = true;

  # Enable Docker
  # virtualisation.docker.enable = true;
  # virtualisation.docker.rootless = {
  #   enable = true;
  #   setSocketVariable = true;
  # };
  # users.extraGroups.docker.members = [ "xnm" ];

  # Enable Podman
  virtualisation = {
    podman = {
      enable = true;
      #remoteSocket.enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
#virtualisation.podman.remoteSocket.enable = true;
  environment.systemPackages = with pkgs; [
    # nerdctl
    # firecracker
    # firectl
    # flintlock
    
    distrobox
    qemu

    podman-compose
    podman-tui
    slirp4netns
    # lazydocker
    # docker-credential-helpers
  ];
}
