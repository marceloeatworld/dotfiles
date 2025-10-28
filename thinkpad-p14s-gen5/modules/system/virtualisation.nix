# Virtualisation configuration
{ pkgs, ... }:

{
  # VMware Workstation Pro
  # DISABLED during installation - requires manual bundle download
  # See instructions in VALIDATION-REPORT.md to install after NixOS setup
  # virtualisation.vmware.host = {
  #   enable = true;
  #   # Package will be vmware-workstation from nixpkgs
  #   # Your license will work with this
  # };

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };

    # Logging configuration (prevent disk exhaustion)
    daemon.settings = {
      log-driver = "json-file";
      log-opts = {
        max-size = "10m";
        max-file = "5";
      };
      # Docker bridge network
      bip = "172.17.0.1/16";
    };
  };

  # Podman (alternative to Docker)
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;  # Create 'docker' alias
  #   defaultNetwork.settings.dns_enabled = true;
  # };

  # KVM/QEMU with virt-manager
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  # Virt-manager for GUI VM management
  programs.virt-manager.enable = true;

  # AppImage support (NixOS 24.11+)
  programs.appimage = {
    enable = true;
    binfmt = true;  # Allows running AppImages directly without appimage-run
  };

  # Enable KVM nested virtualization
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
  '';
}
