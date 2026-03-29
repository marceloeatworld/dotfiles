# Virtualisation configuration
{ pkgs, ... }:

{
  # Podman (rootless Docker alternative)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;      # Provides 'docker' command alias
    dockerSocket.enable = true;  # Docker-compatible socket for tools like lazydocker
    defaultNetwork.settings.dns_enabled = true;  # DNS resolution between containers
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # KVM/QEMU with virt-manager
  # Note: OVMF submodule removed in NixOS 25.11 - all OVMF images now available by default
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";  # Don't auto-restore VMs on boot (default: "start" resumes saved VMs)
    onShutdown = "shutdown";  # Cleanly shutdown VMs on host poweroff (instead of suspending)
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;  # TPM emulation for Windows 11
      # OVMF (including Secure Boot) is available by default in NixOS 25.11+
      vhostUserPackages = [ pkgs.virtiofsd ];  # VirtioFS for shared folders
    };
  };

  # Spice USB redirection (for USB passthrough to VMs)
  virtualisation.spiceUSBRedirection.enable = true;

  # Virt-manager for GUI VM management
  programs.virt-manager.enable = true;

  # Additional packages for VM management
  environment.systemPackages = with pkgs; [
    spice-gtk        # SPICE client (better clipboard, USB redirection)
    virtio-win       # VirtIO drivers ISO for Windows (better performance)
  ];

  # AppImage support (NixOS 24.11+)
  programs.appimage = {
    enable = true;
    binfmt = true;  # Allows running AppImages directly without appimage-run
  };


  # Enable KVM nested virtualization
  # NOTE: boot.extraModprobeConfig also set in networking.nix (cfg80211 regdom) - NixOS merges strings
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
  '';
}
