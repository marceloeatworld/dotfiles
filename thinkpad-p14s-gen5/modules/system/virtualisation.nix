# Virtualisation configuration
{ pkgs, ... }:

{
  # VMware Workstation Pro
  virtualisation.vmware.host = {
    enable = true;
    # Package will be vmware-workstation from nixpkgs
    # Your license will work with this
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
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

  # Enable KVM nested virtualization
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
  '';
}
