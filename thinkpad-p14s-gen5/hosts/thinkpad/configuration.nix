# Main system configuration for ThinkPad P14s Gen 5 (AMD)
{ config, pkgs, ... }:

{
  # System hostname
  networking.hostName = "pop";

  # Enable flakes and nix command
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;

    # Build optimizations
    max-jobs = "auto";
    cores = 16;
    builders-use-substitutes = true;
    keep-going = true;              # Continue building when one derivation fails
    fallback = true;                # Build from source if cache is down
    always-allow-substitutes = true; # Don't skip cache even when derivation says no

    # Download optimizations
    http-connections = 50;            # More parallel downloads (default 25)
    download-buffer-size = 134217728; # 128MB buffer (default 64MB)
    connect-timeout = 5;              # Fail fast on unreachable caches
    max-substitution-jobs = 32;       # More parallel substitutions (default 16)
    narinfo-cache-negative-ttl = 600; # Retry missing packages after 10min (default 1h)

    # Eval optimizations
    warn-dirty = false;
    eval-cache = true;

    # Binary caches
    substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };

  # Garbage collection (now managed by NH)
  # NH handles garbage collection with smarter logic
  # See modules/system/nh.nix for configuration
  nix.gc = {
    automatic = false;  # Disabled - NH manages this
  };

  # NOTE: allowUnfree is set in flake.nix (single source of truth)

  # System packages (minimal - user tools are in home-manager)
  environment.systemPackages = with pkgs; [
    git        # Required for flakes and system scripts
    usbutils   # lsusb - hardware debugging
    pciutils   # lspci - hardware debugging
    llama-cpp  # llama-server, llama-cli, etc. (used by llm script)
    # NOTE: vim/htop/neofetch removed - use nvim/btop/fastfetch via home-manager
    # NOTE: wget/curl removed - installed via home-manager (home.nix)

    # XDG/MIME infrastructure (required for file associations)
    desktop-file-utils  # update-desktop-database command
    shared-mime-info    # MIME type database
    xdg-utils           # xdg-open, xdg-mime, etc.

    # Flipper Zero - Official GUI for firmware updates, backups, file management
    qFlipper
  ];

  # Enable nix-ld for running unpatched dynamic binaries
  programs.nix-ld.enable = true;

  # Create /bin/bash symlink for scripts expecting it (common on NixOS)
  # Required for plugins like claude-code ralph-wiggum hooks
  system.activationScripts.binbash = ''
    mkdir -p /bin
    ln -sf ${pkgs.bash}/bin/bash /bin/bash
  '';

  # Documentation (keep man pages, skip expensive builds)
  documentation.enable = true;
  documentation.man.enable = true;
  documentation.nixos.enable = false;  # Skip NixOS manual build (use online docs)
  documentation.doc.enable = false;    # Skip /share/doc
  documentation.info.enable = false;   # Skip info pages

  # This value determines the NixOS release with which your system is compatible
  # DON'T CHANGE THIS unless you know what you're doing
  system.stateVersion = "25.05";
}
