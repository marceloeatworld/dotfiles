# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS dotfiles repository using flakes and home-manager for declarative system and user configuration. The system is configured with Hyprland (Wayland compositor), and uses a modular structure where each aspect of the system is split into separate Nix files.

Hostname: `cute`
User: `marcelo`

## Architecture

### Flake Structure (nixos/flake.nix)

The flake defines the system configuration `nixosConfigurations.cute` and pulls in:
- **nixpkgs**: nixos-unstable channel
- **disko**: Declarative disk partitioning (LUKS + Btrfs with two encrypted disks)
- **home-manager**: User environment management
- **hyprland**: Wayland compositor
- **nur**: Nix User Repository
- **hypr-contrib**, **hyprpicker**: Hyprland utilities
- **nix-gaming**: Gaming optimizations
- **catppuccin-bat**, **catppuccin-starship**: Catppuccin themes

### Module Organization

**System-level modules** (imported in flake.nix):
- `configuration.nix` - Base NixOS configuration (includes hardware-configuration.nix and disko-config.nix)
- `user.nix` - User account definition
- `coding.nix` - Development environment setup
- `hardware.nix` - Hardware-specific settings
- `services.nix` - System services (Ollama, TLP power management, printing, etc.)
- `network.nix` - Network configuration
- `bootloader.nix` - Boot configuration
- `sound.nix` - Audio setup
- `xserver.nix` - X11 settings (if used)
- `wayland.nix` - Wayland/Hyprland setup with XDG portals
- `system.nix` - System-wide settings
- `security-services.nix` - Security-related services
- `virtualisation.nix` - Container/VM configuration
- `steam.nix` - Gaming setup

**Home-manager configuration** (nixos/home.nix):
Imports from `nixos/app/` directory:
- `bat.nix`, `btop.nix` - CLI tools
- `discord.nix` - Discord setup
- `floorp/floorp.nix` - Firefox-based browser
- `gaming.nix` - Gaming applications
- `gtk.nix` - GTK theming
- `git.nix` - Git configuration
- `kitty.nix` - Terminal emulator
- `mako.nix` - Notification daemon
- `micro.nix` - Text editor
- `nvim.nix` - Neovim configuration
- `packages.nix` - User packages list
- `starship.nix` - Shell prompt
- `swaylock.nix` - Screen locker
- `scripts/scripts.nix` - Custom shell scripts
- `vscodium.nix` - VSCodium setup
- `waybar/` - Status bar configuration (modular: default.nix, settings.nix, style.nix, waybar.nix)
- `wofi.nix` - Application launcher
- `zsh.nix` - Shell configuration

### Configuration Files

**Hyprland**: Configuration is managed both through:
- Nix files in `nixos/app/hyprland/` (config.nix, hyprland.nix, variables.nix)
- `.config/hypr/hyprland.conf` - Main Hyprland configuration with keybindings and window rules

**Waybar, Wofi, Swaylock**: Config files in `.config/` are typically symlinks to Nix store (managed by home-manager)

### Disk Layout (disko-config.nix)

Two encrypted disks:
1. **nvme0n1** (main): LUKS → Btrfs with subvolumes (@root, @home, @nix, @swap)
2. **nvme1n1** (data): LUKS → Btrfs with @storage mounted at /mnt/storage

## Common Commands

### Building & Switching

```bash
# Rebuild and switch system configuration (from nixos/ directory)
sudo nixos-rebuild switch --flake .#cute

# Build without switching
sudo nixos-rebuild build --flake .#cute

# Test configuration (doesn't set as boot default)
sudo nixos-rebuild test --flake .#cute

# Update flake inputs
nix flake update

# Check flake configuration
nix flake check
```

### Home Manager

Home-manager is integrated into the system flake and applied automatically during `nixos-rebuild`. Changes to files in `nixos/app/` require a full system rebuild.

### Package Management

```bash
# Search for packages
nix search nixpkgs <package-name>

# Install temporary package (not persistent)
nix shell nixpkgs#<package-name>

# Add persistent packages by editing nixos/app/packages.nix
```

### Development

```bash
# Format Nix files with alejandra
nix fmt

# Enter development shell with specific packages
nix develop

# Check for issues
nix flake check
```

## Key System Features

- **Power Management**: TLP configured for Ryzen 6800U with battery charge thresholds (75-80%)
- **GPU**: AMD GPU (amdgpu driver) with ROCm acceleration available for Ollama (currently disabled)
- **Display**: Dual monitor setup (HDMI-A-1 @ 165Hz 1920x1080, eDP-1 @ 60Hz 1920x1200)
- **Window Manager**: Hyprland with custom keybindings using Super (SUPER) key and numpad workspace switching
- **Theme**: Catppuccin Mocha (GTK_THEME: Catppuccin-Mocha-Compact-Lavender-Dark)
- **Shell**: ZSH with Starship prompt
- **Terminal**: Kitty
- **Editor**: Neovim (primary), Micro, VSCodium
- **Keyboard Layouts**: French and US (switch with configured binding)

## Important Paths

- System configuration: `/home/marcelo/dotfiles/nixos/`
- User configs (symlinked): `/home/marcelo/.config/`
- Hyprland config: `/home/marcelo/.config/hypr/hyprland.conf`
- Scripts: `nixos/app/scripts/scripts/`
- Custom rules: `nixos/rules.conf`

## Hyprland Custom Keybindings

Main modifier: `$mainMod = SUPER`

Key bindings of note:
- `SUPER + Return`: Kitty terminal
- `SUPER + D`: Wofi launcher
- `SUPER + B`: Launch Floorp browser
- `SUPER + Q`: Kill active window
- `SUPER + F`: Fullscreen
- `SUPER + Escape`: Lock screen (swaylock)
- `SUPER + SHIFT + Escape`: Shutdown script
- Workspace switching: Numpad keys (1-9, 0)
- `SUPER + W`: Wallpaper picker
- `SUPER + C`: Color picker (hyprpicker)
- `SUPER + G`: Toggle layout script

## Development Notes

- This system uses **flakes** - always use `--flake .#cute` when rebuilding
- Changes to system require `sudo nixos-rebuild switch`
- The hostname `cute` must match the flake configuration name
- Unfree packages are allowed (`nixpkgs.config.allowUnfree = true`)
- System state version: 23.11 (do not change)
- Home state version: 24.11
