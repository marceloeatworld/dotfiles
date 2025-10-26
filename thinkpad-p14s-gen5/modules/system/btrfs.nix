# Btrfs filesystem management and optimization
{ pkgs, ... }:

{
  # Btrfs tools
  environment.systemPackages = with pkgs; [
    btrfs-progs
    compsize  # Show compression ratio
  ];

  # Auto-scrub for data integrity (monthly)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Automated snapshots with btrbk
  services.btrbk = {
    instances = {
      btrbk = {
        onCalendar = "*:0/15";  # Every 15 minutes
        settings = {
          # Global settings
          timestamp_format = "long";
          snapshot_preserve = "48h 7d 4w 12m";  # Keep: 48h hourly, 7 daily, 4 weekly, 12 monthly
          snapshot_preserve_min = "2d";
          target_preserve_min = "no";

          # Volume configurations
          volume."/" = {
            subvolume = {
              "@root" = {
                snapshot_dir = "/.snapshots/root";
              };
              "@home" = {
                snapshot_dir = "/.snapshots/home";
              };
            };
          };
        };
      };
    };
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
  # Btrfs swap file is already configured in disko-config.nix
  # Ensure no COW on swap subvolume

  # Hibernation support (INCOMPLETE - requires manual configuration)
  # To enable hibernation to the Btrfs swapfile:
  # 1. After installation, run: sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  # 2. Note the physical_offset value
  # 3. Uncomment and add the offset below:
  # boot.kernelParams = [
  #   "resume=/swap/swapfile"
  #   "resume_offset=YOUR_OFFSET_HERE"  # Replace with actual offset from step 1
  # ];

  # Note: Without resume_offset, hibernation will NOT work
}
