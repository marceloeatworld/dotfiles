# Btrfs filesystem management and optimization
{ lib, pkgs, ... }:

{
  # Btrfs tools
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize # Show compression ratio
  ];

  # Auto-scrub for data integrity (monthly)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Btrfs subvolumes are mounted with discard=async, so periodic whole-filesystem
  # fstrim is redundant and can create long I/O bursts on a laptop.
  services.fstrim.enable = false;

  # Automated snapshots with btrbk
  services.btrbk = {
    instances = {
      btrbk = {
        onCalendar = "hourly";
        settings = {
          # Global settings
          timestamp_format = "long";
          snapshot_preserve = "24h 3d"; # Keep: 24h (all), 3 daily
          snapshot_preserve_min = "1d";
          target_preserve_min = "no";

          # Volume configurations
          # Note: @root and @home are already mounted at / and /home
          volume."/" = {
            subvolume = {
              "." = {
                # Current directory = @root
                snapshot_dir = "/.snapshots/root";
              };
            };
          };
          volume."/home" = {
            subvolume = {
              "." = {
                # Current directory = @home
                snapshot_dir = "/.snapshots/home";
              };
            };
          };
        };
      };
    };
  };

  # Snapshotting is useful, but avoid doing it while on battery.
  systemd.services.btrbk-btrbk.unitConfig.ConditionACPower = true;
  systemd.services.btrbk-btrbk.serviceConfig = {
    Nice = 10;
    IOSchedulingClass = lib.mkForce "idle";
  };

  # Ensure snapshot directory exists
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /.snapshots/root 0755 root root -"
    "d /.snapshots/home 0755 root root -"
  ];

  # Optional: Enable Btrfs autodefrag (can help on HDDs, less important on SSDs)
  # Uncomment if needed:
  # fileSystems."/".options = [ "autodefrag" ];

  # Zstd compression configuration (already in disko-config)
  # All subvolumes use compress=zstd for better performance and space savings

  # TRIM support for SSD (handled by discard=async in mount options)
  # This is more efficient than periodic TRIM

  # Swap file configuration
  # Btrfs swap file is configured in disko-config.nix on a dedicated @swap
  # subvolume with nodatacow/nodatasum. Hibernation is intentionally disabled
  # in services.nix until a real resume_offset is measured on the installed
  # machine:
  #
  #   sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  #
  # Once known, enable hibernation with boot.resumeDevice plus
  # boot.kernelParams = [ "resume_offset=<offset>" ]. Do not guess this value.
}
