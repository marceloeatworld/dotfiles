# Performance optimizations for ThinkPad P14s Gen 5 (AMD)
# Zram, ananicy-cpp, earlyoom, and other system-wide improvements
{ lib, pkgs, ... }:

let
  gamePlatformProfile = pkgs.writeShellScriptBin "game-platform-profile" ''
    set -eu

    PROFILE_FILE="/sys/firmware/acpi/platform_profile"
    CHOICES_FILE="/sys/firmware/acpi/platform_profile_choices"
    AC_FILE="/sys/class/power_supply/AC/online"
    MODE="''${1:-auto}"

    [ -w "$PROFILE_FILE" ] || exit 0

    has_profile() {
      ${pkgs.gnugrep}/bin/grep -qw "$1" "$CHOICES_FILE" 2>/dev/null
    }

    case "$MODE" in
      performance|balanced|low-power)
        TARGET="$MODE"
        ;;
      auto)
        if [ -r "$AC_FILE" ] && [ "$(${pkgs.coreutils}/bin/cat "$AC_FILE")" = "1" ]; then
          TARGET="balanced"
        else
          TARGET="low-power"
        fi
        ;;
      *)
        echo "Usage: game-platform-profile performance|balanced|low-power|auto" >&2
        exit 2
        ;;
    esac

    if has_profile "$TARGET"; then
      printf '%s\n' "$TARGET" > "$PROFILE_FILE"
    fi
  '';
in
{
  # ===========================================
  # ZRAM - Compressed swap in RAM
  # ===========================================
  # Much faster than disk swap, uses ~50% of original size in RAM
  # With 32GB RAM, this gives effective 48GB+ memory
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Best compression ratio for Zen 4
    memoryPercent = 75; # Use up to 75% of RAM for compressed swap (~24GB on 32GB)
    priority = 100; # Higher priority than disk swap
  };

  # ===========================================
  # SYSTEMD USER SLICES - Memory caps for greedy apps
  # ===========================================
  # MemoryHigh = soft throttle (kernel reclaims aggressively past this)
  # MemoryMax  = hard cap (process killed by kernel OOM if exceeded)
  # All processes launched via systemd-run --slice=NAME share these limits.
  systemd.user.slices = {
    "app-brave" = {
      description = "Memory-limited slice for Brave";
      sliceConfig = {
        MemoryHigh = "8G";
        MemoryMax = "12G";
        MemorySwapMax = "8G";
      };
    };
    "app-code" = {
      description = "Memory-limited slice for VSCode";
      sliceConfig = {
        MemoryHigh = "10G";
        MemoryMax = "14G";
        MemorySwapMax = "8G";
      };
    };
  };

  # ===========================================
  # ANANICY-CPP - Process priority daemon
  # ===========================================
  # Automatically sets nice/ionice values for better responsiveness
  # Prioritizes interactive apps over background tasks
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp; # C++ rewrite, faster and more efficient
    rulesProvider = pkgs.ananicy-rules-cachyos; # CachyOS community rules
    settings = {
      # The CachyOS cgroup rules currently try to move tasks into the root
      # cgroup on this system and spam add_pid_to_cgroup errors. Keep the
      # useful nice/ionice/scheduler tuning, disable only the broken cgroup
      # path.
      apply_cgroup = lib.mkForce false;
      cgroup_load = lib.mkForce false;
      cgroup_realtime_workaround = lib.mkForce false;
    };
  };

  # ===========================================
  # EARLYOOM - Early OOM killer
  # ===========================================
  # Kills processes before the system becomes unresponsive
  # Much better than Linux default OOM killer
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5; # Trigger at 5% free RAM
    freeSwapThreshold = 10; # Trigger at 10% free swap
    enableNotifications = true; # Desktop notifications when killing
    extraArgs = [
      "--avoid"
      "^(Hyprland|waybar|pipewire|wireplumber|qemu)$" # Never kill these
      "--prefer"
      "^(brave|chromium|firefox|chrome)$" # Kill browsers first (not generic 'electron' to protect vesktop/joplin)
    ];
  };

  # ===========================================
  # GAMEMODE - Gaming performance
  # ===========================================
  # Auto-optimizes system when games are running
  programs.gamemode = {
    enable = true;
    enableRenice = true; # Renice game processes
    settings = {
      general = {
        renice = 10; # Priority boost for games
        softrealtime = "auto";
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0; # AMD GPU
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.sudo}/bin/sudo ${gamePlatformProfile}/bin/game-platform-profile performance && ${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations enabled'";
        end = "${pkgs.sudo}/bin/sudo ${gamePlatformProfile}/bin/game-platform-profile auto && ${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations disabled'";
      };
    };
  };

  # Allow GameMode to toggle only the constrained ThinkPad platform profile
  # helper above. The helper validates its argument before touching sysfs.
  security.sudo.extraRules = [
    {
      users = [ "marcelo" ];
      commands = [
        {
          command = "${gamePlatformProfile}/bin/game-platform-profile performance";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${gamePlatformProfile}/bin/game-platform-profile auto";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # ===========================================
  # Additional kernel tweaks
  # ===========================================
  boot.kernel.sysctl = {
    # ── AMD-specific (from amd-optimizations.nix) ──
    "vm.swappiness" = 180; # High value optimal for zram (prefer compressed RAM over disk I/O)
    "vm.vfs_cache_pressure" = 50; # Keep more inodes/dentries in cache
    "kernel.nmi_watchdog" = 0; # Disable watchdog (can cause issues with AMD)

    # ── Network performance ──
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3; # Enable TCP Fast Open

    # ── Memory management ──
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.page-cluster" = 0; # Better for SSDs with zram

    # ── File system ──
    "fs.inotify.max_user_watches" = 524288; # For IDEs and file watchers

    # ── Security hardening with low compatibility risk ──
    "kernel.kptr_restrict" = 2; # Hide kernel pointers from unprivileged users
    "kernel.dmesg_restrict" = 1; # Restrict kernel logs to privileged users
    "kernel.yama.ptrace_scope" = 1; # Limit ptrace to parent/child debugging
    "kernel.unprivileged_bpf_disabled" = 1; # Root can still use BPF tooling
    "net.core.bpf_jit_harden" = 2; # Harden BPF JIT for all users
    "dev.tty.ldisc_autoload" = 0; # Do not auto-load line disciplines
    "fs.protected_fifos" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_regular" = 2;
    "fs.protected_symlinks" = 1;
  };

  # ===========================================
  # System packages for monitoring
  # ===========================================
  environment.systemPackages = with pkgs; [
    gamescope # Micro-compositor for games (fixes Wayland issues)
    gamePlatformProfile
  ];
}
