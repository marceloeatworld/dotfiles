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

  # Travel mode: forces TLP's battery (eco) settings even while on AC.
  # Toggle: `travel-mode`. State comes from TLP itself (/run/tlp/manual_mode
  # exists only while a mode is forced), so it never goes stale. A reboot
  # returns TLP to auto (AC = max performance, battery = eco).
  travelMode = pkgs.writeShellScriptBin "travel-mode" ''
    set -eu

    if [ -f /run/tlp/manual_mode ] && ${pkgs.gnugrep}/bin/grep -q bat /run/tlp/manual_mode; then
      /run/wrappers/bin/sudo -n /run/current-system/sw/bin/tlp start
      ${pkgs.libnotify}/bin/notify-send -t 3000 "AC mode" "TLP auto: AC = max performance, battery = eco" -i "battery-full-charging" || true
    else
      /run/wrappers/bin/sudo -n /run/current-system/sw/bin/tlp bat
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Travel mode" "Eco settings forced, even on AC (until reboot or re-toggle)" -i "battery-good" || true
    fi
  '';
in
{
  # ===========================================
  # ZRAM - Compressed swap in RAM
  # ===========================================
  # Much faster than disk swap, uses ~50% of original size in RAM
  # MemTotal is ~27GiB (4GB BIOS VRAM carveout); zram adds a 20.3G compressed device on top (~40GB effective)
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Best compression ratio for Zen 4
    memoryPercent = 75; # 75% of MemTotal (~27GiB after the 4GB VRAM carveout) = 20.3G zram
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
  # BRAVE MEMORY SAVER - Discard inactive tabs
  # ===========================================
  # Chromium enterprise policy, read from /etc/brave/policies/managed/ by
  # every Brave launcher (firejail wrapper, brave-hw, webapps).
  environment.etc."brave/policies/managed/memory-saver.json".text = builtins.toJSON {
    HighEfficiencyModeEnabled = true; # Force Memory Saver on
    MemorySaverModeSavings = 1;       # Balanced tab-discard heuristics
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
      # earlyoom matches the kernel comm (15 chars); NixOS wrappers rename
      # Hyprland/waybar/brave to .<name>-wrapped, truncated to .Hyprland-wrapp
      "--avoid"
      "^(\\.?Hyprland(-wrapp.*)?|\\.?waybar(-wrapped)?|pipewire(-pulse)?|wireplumber|qemu.*)$" # Never kill these
      "--prefer"
      "^(\\.?brave(-wrapped)?|chromium|firefox|chrome)$" # Kill browsers first (not generic 'electron' to protect vesktop/joplin)
    ];
  };

  # earlyoom owns the global low-memory policy above. No cgroups are configured
  # for systemd-oomd, so running both only leaves an idle second OOM daemon.
  systemd.oomd.enable = false;

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
        # /run/wrappers/bin/sudo is the setuid wrapper; the store sudo binary
        # cannot elevate ("must be owned by uid 0"), which silently disabled
        # the platform-profile boost until 2026-07-08.
        start = "/run/wrappers/bin/sudo /run/current-system/sw/bin/game-platform-profile performance && ${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations enabled'";
        end = "/run/wrappers/bin/sudo /run/current-system/sw/bin/game-platform-profile auto && ${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations disabled'";
      };
    };
  };

  # Allow GameMode and perf-mode to toggle only the constrained ThinkPad
  # platform profile helper above. The helper validates its argument before
  # touching sysfs. The /run/current-system path stays valid across rebuilds
  # (sudoers matches the literal argv path, not the resolved store path).
  security.sudo.extraRules = [
    {
      users = [ "marcelo" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/game-platform-profile performance";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/game-platform-profile auto";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/game-platform-profile low-power";
          options = [ "NOPASSWD" ];
        }
        # travel-mode: only the two exact TLP invocations it needs
        {
          command = "/run/current-system/sw/bin/tlp bat";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/tlp start";
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

    # Larger socket buffers for high-bandwidth UDP streaming (GeForce NOW,
    # game streaming, video calls). 16 MiB is the headroom kernel autotuning
    # is allowed to use; defaults stay small.
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;

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
    travelMode
  ];
}
