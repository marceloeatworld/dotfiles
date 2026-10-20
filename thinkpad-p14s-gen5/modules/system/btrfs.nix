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

  # Continuous discard=async kept the btrfs-discard kworkers permanently in
  # D-state (IO PSI >90%, ~9GB discard backlog fed by hourly btrbk snapshot
  # rotation). Subvolumes are mounted nodiscard instead, with TRIM done as a
  # weekly batch here.
  # NOTE: IO PSI is not a reliable symptom on this machine anymore. io_uring
  # accounts its completion waits as iowait, so Ghostty, Node and Ferdium
  # alone keep the Hyprland session cgroup at 60-85% "full" IO pressure
  # with the NVMe idle (verified 2026-09-06 on 7.2.3, no D-state tasks).
  # Check /sys/block/nvme0n1/stat and D-state processes before blaming disk.
  services.fstrim.enable = true;

  # Automated snapshots with btrbk
  services.btrbk = {
    instances = {
      btrbk = {
        # One snapshot per day, kept 3 days. The previous hourly schedule with
        # a 24h window plus 3 daily kept every deleted file alive for days:
        # after the 2026-09-06 cleanup (250 GB) the disk space only came back
        # once the snapshots expired.
        onCalendar = "daily";
        settings = {
          # Global settings
          timestamp_format = "long";
          snapshot_preserve = "3d"; # Keep 3 daily snapshots
          snapshot_preserve_min = "latest";
          target_preserve_min = "no";

          # Midnight retention can delete a full day of hourly snapshots at
          # once. Commit each deletion before queuing the next one so Btrfs
          # does not leave a large asynchronous metadata-cleanup backlog.
          btrfs_commit_delete = "yes";

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
    IOWeight = 10;
    TimeoutStartSec = "30min";
  };

  # Ensure snapshot directory exists
  systemd.tmpfiles.rules = [
    "d /.snapshots 0755 root root -"
    "d /.snapshots/root 0755 root root -"
    "d /.snapshots/home 0755 root root -"
  ];

  # Compression (compress=zstd) and the nodiscard mount option live in
  # disko-config.nix. The swap file sits on the dedicated @swap subvolume
  # (nodatacow/nodatasum). Hibernation is disabled in services.nix until a
  # real resume_offset is measured on the installed machine:
  #
  #   sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  #
  # Once known, enable hibernation with boot.resumeDevice plus
  # boot.kernelParams = [ "resume_offset=<offset>" ]. Do not guess this value.
}
