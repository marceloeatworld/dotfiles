# Disko configuration - Declarative disk partitioning
# LUKS encryption + Btrfs with 7 subvolumes
#
# Usage during installation:
# sudo nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode disko hosts/thinkpad/disko-config.nix
#
# This will:
# 1. Wipe the disk (⚠️ ALL DATA LOST)
# 2. Create GPT partition table
# 3. Create EFI partition (512MB)
# 4. Create encrypted LUKS partition (rest of disk)
# 5. Format with Btrfs
# 6. Create 7 subvolumes
# 7. Mount everything under /mnt

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

                    # Nix store
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

                    # Swap subvolume (2GB - minimal for 32GB RAM)
                    # CRITICAL: Btrfs swap REQUIRES nodatacow + nodatasum + NO compression
                    "@swap" = {
                      mountpoint = "/swap";
                      mountOptions = [
                        "noatime"
                        "nodatacow"   # Disable copy-on-write (required for swap)
                        "nodatasum"   # Disable checksums (required for swap)
                      ];
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

  # NOTE: fileSystems are automatically managed by disko
  # Do NOT manually define them here - disko handles everything
}
