# Virtualisation configuration
# Optimized for near-native Windows VM performance on AMD Ryzen 7 PRO 8840HS
{ config, pkgs, ... }:

let
  # Libvirt hook: auto-optimize host when VM starts/stops
  # - Switches CPU governor to performance while a guest is starting/running
  # - Restores TLP afterward so EPP/platform/boost settings return to normal
  # - Intentionally does not manage hugepages; that proved brittle on this host
  qemu-hook = pkgs.writeShellScript "qemu-hook" ''
    VM_NAME="$1"
    ACTION="$2"
    SUBACTION="$3"

    CPUPOWER="${config.boot.kernelPackages.cpupower}/bin/cpupower"
    TLP="${pkgs.tlp}/bin/tlp"

    case "$ACTION" in
      prepare)
        [ "$SUBACTION" = "begin" ] || exit 0

        # Performance governor: ensure VM gets full clock speeds
        $CPUPOWER frequency-set -g performance > /dev/null 2>&1 || true
        ;;
      stopped|release)
        [ "$SUBACTION" = "end" ] || exit 0

        # Restore the active TLP profile (governor, EPP, platform profile, boost).
        $TLP start > /dev/null 2>&1 || $CPUPOWER frequency-set -g powersave > /dev/null 2>&1 || true
        ;;
    esac
  '';
in
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

  systemd.services.podman-prune.serviceConfig = {
    Nice = 10;
    IOSchedulingClass = "idle";
  };

  # KVM/QEMU with virt-manager
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";  # Don't auto-restore VMs on boot
    onShutdown = "shutdown";  # Cleanly shutdown VMs on host poweroff
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      swtpm.enable = true;  # TPM emulation for Windows 11
      # OVMF (UEFI/Secure Boot) available by default in NixOS 25.11+
      vhostUserPackages = [ pkgs.virtiofsd ];  # VirtioFS for shared folders
    };
  };

  # Deploy libvirt hook via NixOS module (scripts go to /var/lib/libvirt/hooks/qemu.d/)
  virtualisation.libvirtd.hooks.qemu."10-vm-optimize" = qemu-hook;

  # Spice USB redirection (for USB passthrough to VMs)
  virtualisation.spiceUSBRedirection.enable = true;

  # Virt-manager for GUI VM management
  programs.virt-manager.enable = true;

  # Additional packages for VM management
  environment.systemPackages = with pkgs; [
    spice-gtk        # SPICE client (better clipboard, USB redirection)
    virtio-win       # VirtIO drivers ISO for Windows (better performance)
    slirp4netns      # User-mode networking for rootless Podman containers
    virt-viewer      # Dedicated SPICE viewer (better perf than virt-manager built-in)
    hwloc            # CPU topology visualization (lstopo)
  ];

  # AppImage support (NixOS 24.11+)
  programs.appimage = {
    enable = true;
    binfmt = false;  # Require explicit appimage-run instead of auto-executing AppImages
  };

  # Allow QEMU to lock guest RAM (required when runAsRoot = false)
  # PAM limits for user sessions, systemd override for the libvirtd service
  security.pam.loginLimits = [
    { domain = "@libvirtd"; type = "soft"; item = "memlock"; value = "unlimited"; }
    { domain = "@libvirtd"; type = "hard"; item = "memlock"; value = "unlimited"; }
  ];
  systemd.services.libvirtd.serviceConfig.LimitMEMLOCK = "infinity";

  # KVM module options
  # NOTE: boot.extraModprobeConfig also set in networking.nix (cfg80211 regdom) - NixOS merges strings
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
    options kvm ignore_msrs=1
    options kvm report_ignored_msrs=0
  '';
}
