# Performance optimizations for ThinkPad P14s Gen 5 (AMD)
# Zram, ananicy-cpp, earlyoom, and other system-wide improvements
{ pkgs, ... }:

{
  # ===========================================
  # ZRAM - Compressed swap in RAM
  # ===========================================
  # Much faster than disk swap, uses ~50% of original size in RAM
  # With 32GB RAM, this gives effective 48GB+ memory
  zramSwap = {
    enable = true;
    algorithm = "zstd";  # Best compression ratio for Zen 4
    memoryPercent = 50;  # Use up to 50% of RAM for compressed swap
    priority = 100;      # Higher priority than disk swap
  };

  # ===========================================
  # ANANICY-CPP - Process priority daemon
  # ===========================================
  # Automatically sets nice/ionice values for better responsiveness
  # Prioritizes interactive apps over background tasks
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;  # C++ rewrite, faster and more efficient
    rulesProvider = pkgs.ananicy-rules-cachyos;  # CachyOS community rules
  };

  # ===========================================
  # EARLYOOM - Early OOM killer
  # ===========================================
  # Kills processes before the system becomes unresponsive
  # Much better than Linux default OOM killer
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;   # Trigger at 5% free RAM
    freeSwapThreshold = 10; # Trigger at 10% free swap
    enableNotifications = true;  # Desktop notifications when killing
    extraArgs = [
      "--avoid" "^(Hyprland|waybar|pipewire|wireplumber)$"  # Never kill these
      "--prefer" "^(brave|chromium|firefox|electron)$"      # Kill browsers first
    ];
  };

  # ===========================================
  # GAMEMODE - Gaming performance
  # ===========================================
  # Auto-optimizes system when games are running
  programs.gamemode = {
    enable = true;
    enableRenice = true;  # Renice game processes
    settings = {
      general = {
        renice = 10;  # Priority boost for games
        softrealtime = "auto";
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;  # AMD GPU
        amd_performance_level = "high";
      };
      custom = {
        start = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations enabled'";
        end = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Optimizations disabled'";
      };
    };
  };

  # ===========================================
  # Additional kernel tweaks
  # ===========================================
  boot.kernel.sysctl = {
    # Network performance
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;  # Enable TCP Fast Open

    # Memory management
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.page-cluster" = 0;  # Better for SSDs with zram

    # File system
    "fs.inotify.max_user_watches" = 524288;  # For IDEs and file watchers
  };

  # ===========================================
  # System packages for monitoring
  # ===========================================
  environment.systemPackages = with pkgs; [
    gamescope  # Micro-compositor for games (fixes Wayland issues)
  ];
}
