# Disko configuration - Declarative disk partitioning
# LUKS encryption + Btrfs with subvolumes for 1TB SSD
{ ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";  # Change this to match your disk!
        content = {
          type = "gpt";
          partitions = {
            # EFI boot partition (512MB - standard modern size)
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" "umask=0077" ];
              };
            };

            # Encrypted root partition (rest of disk)
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";

                # Password prompt during boot
                # For keyfile: passwordFile = "/tmp/secret.key";

                settings = {
                  allowDiscards = true;  # Enable TRIM for SSD
                  bypassWorkqueues = true;  # Better performance
                };

                # Btrfs filesystem with subvolumes
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L" "nixos" ];  # Force and label

                  subvolumes = {
                    # Root subvolume
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                        "discard=async"
                      ];
                    };

                    # Home directory
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                        "discard=async"
                      ];
                    };

                    # Nix store (can disable COW for better database performance)
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                        "discard=async"
                      ];
                    };

                    # Persistent data (for impermanence setup)
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                        "discard=async"
                      ];
                    };

                    # System logs
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                        "discard=async"
                      ];
                    };

                    # Snapshots directory
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                        "space_cache=v2"
                        "discard=async"
                      ];
                    };

                    # Swap subvolume (2GB - minimal safety margin for 32GB RAM)
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [ "noatime" ];
                      swap.swapfile = {
                        size = "2G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Optional: Noatime for all mounts (reduces writes)
  fileSystems = {
    "/".options = [ "noatime" ];
    "/home".options = [ "noatime" ];
    "/nix".options = [ "noatime" ];
  };
}
