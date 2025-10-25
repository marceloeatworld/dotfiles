# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a NixOS dotfiles repository using flakes and home-manager for declarative system and user configuration. The system is configured for a **ThinkPad P14s Gen 5 (AMD)** with Hyprland (Wayland compositor), using a modular structure where each aspect is split into separate Nix files.

**Key Info:**
- Hostname: `pop`
- User: `marcelo`
- NixOS Version: 25.05
- Processor: AMD Ryzen 7 PRO 8840HS + Radeon 780M (RDNA 3 iGPU)
- RAM: 32GB
- GTK Theme: Gruvbox-Dark-BL
- Hyprland: Custom configuration with modern animations

## Architecture

### Flake Structure (flake.nix)

The flake defines `nixosConfigurations.pop` and imports:
- **nixpkgs**: NixOS 25.05 channel
- **nixpkgs-unstable**: Latest packages when needed
- **disko**: Declarative disk partitioning (LUKS + Btrfs with 7 subvolumes)
- **home-manager**: User environment management (release-25.05)
- **hyprland**: Wayland compositor from upstream
- **nixos-hardware**: Official ThinkPad P14s Gen 5 AMD profile
- **walker**: Application launcher (with elephant dependency)
- **themes**: Hyprland themes from basecamp/omarchy (available but not actively sourced)
- **catppuccin-bat**, **catppuccin-starship**: Catppuccin themes for CLI tools

### Module Organization

**System-level modules** (imported in flake.nix from `modules/system/`):
- `boot.nix` - Bootloader, kernel params, fast shutdown (5s)
- `networking.nix` - Network, firewall, Bluetooth, TCP MTU probing fix
- `hyprland.nix` - Hyprland system-level config
- `sound.nix` - PipeWire audio
- `locale.nix` - Locale (English), timezone (Europe/Lisbon), keyboard (French)
- `users.nix` - User account (marcelo)
- `security.nix` - Security settings
- `services.nix` - System services (TLP, Ollama, CUPS, Avahi, UPower, Thermald)
- `virtualisation.nix` - Docker, VMware, libvirtd/QEMU
- `btrfs.nix` - Btrfs maintenance (scrub, snapshots)
- `amd-optimizations.nix` - AMD-specific optimizations (P-State EPP, GPU settings)
- `steam.nix` - Steam with Proton GE, GameMode performance optimizations

**Home-manager configuration** (`modules/home/home.nix`):

Imports 18 modules from subdirectories:
- **programs/**: hyprland, terminal (Kitty), shell (Zsh), git, nvim, browsers (Brave), brave-flags, webapps, media, development, walker, fastfetch, xournalpp, uwsm
- **services/**: waybar, mako, swaylock, swayosd
- **config/**: gtk, qt, fontconfig

### Disk Layout (disko-config.nix)

Single encrypted disk:
- **nvme0n1**: LUKS → Btrfs with 7 subvolumes:
  - `@root` (/)
  - `@home` (/home)
  - `@nix` (/nix) - with nocoW
  - `@persist` (/persist)
  - `@log` (/var/log)
  - `@snapshots` (/.snapshots)
  - `@swap` (/swap) - 2GB swapfile

All use `compress=zstd`, `noatime`, `space_cache=v2`, `discard=async`

## Common Commands

### Building & Switching

```bash
# Rebuild and switch system (from repo root)
sudo nixos-rebuild switch --flake .#pop

# Build without switching
sudo nixos-rebuild build --flake .#pop

# Test configuration (doesn't set as boot default)
sudo nixos-rebuild test --flake .#pop

# Update flake inputs
nix flake update

# Check flake configuration
nix flake check
```

### Home Manager

Home-manager is integrated into the system flake. Changes to `modules/home/` require a full `nixos-rebuild switch`.

### Package Management

```bash
# Search for packages
nix search nixpkgs <package-name>

# Install temporary package (not persistent)
nix shell nixpkgs#<package-name>

# Add persistent packages: edit modules/home/home.nix
```

## Key System Features

### Hardware & Optimizations
- **CPU**: AMD Ryzen 7 PRO 8840HS with P-State EPP (active mode for Zen 4)
- **GPU**: Radeon 780M (RDNA 3) with RADV Vulkan driver
- **Power Management**: TLP configured for AMD (performance on AC, powersave on battery)
  - Battery charge thresholds: 75-80%
  - CPU boost disabled on battery
- **Display**: Dual monitor vertical setup (external 1920x1080 top, laptop 1920x1200 bottom)
- **Fast Shutdown**: 5 seconds (systemd timeout override)
- **Network Fix**: TCP MTU probing enabled (fixes SSH/VPN issues)

### Desktop Environment
- **Window Manager**: Hyprland with custom animations (fluent bezier curves, blur, shadows)
- **Launcher**: Walker (runs as service, minimal config)
- **Terminal**: Kitty with 14px padding, block cursor
- **Status Bar**: Waybar
- **Notifications**: Mako
- **OSD**: SwayOSD for volume/brightness
- **Shell**: Zsh with Starship prompt
- **Editor**: Neovim (primary), VS Code
- **Browser**: Brave with Wayland flags
- **Fonts**: Liberation Sans/Serif, CaskaydiaMono Nerd Font, JetBrains Mono
- **GTK Theme**: Gruvbox-Dark-BL with Papirus-Dark icons and Bibata-Modern-Classic cursor

### AI & Development
- **Ollama**: Local LLM with ROCm acceleration for AMD GPU
  - `HSA_OVERRIDE_GFX_VERSION=11.0.0` (RDNA 3 iGPU fix)
  - Service runs on `http://127.0.0.1:11434`
- **AI Tools**: aichat (CLI)
- **Containers**: Docker with logging limits, VMware Workstation Pro, libvirtd/QEMU

## Hyprland Keybindings

Main modifier: `$mod = SUPER`

**Applications:**
- `SUPER + Return` → Kitty terminal
- `SUPER + B` → Brave browser
- `SUPER + E` → Nemo file manager
- `SUPER + D` → Walker launcher (primary, Ristretto themed)

**System:**
- `SUPER + Q` → Kill active window
- `SUPER + F` → Fullscreen
- `SUPER + SPACE` → Toggle floating
- `SUPER + Escape` → Swaylock

**Utilities:**
- `SUPER + C` → Hyprpicker (color picker)
- `SUPER + N` → Cycle blue light filter (Off → 5500K → 4500K → 3500K → 2500K → Off)
- `SUPER + V` → Clipboard history (cliphist via walker)
- `SUPER + SHIFT + V` → Clear clipboard history
- `Print` → Screenshot selection to clipboard
- `SUPER + Print` → Screenshot selection to file (~/Pictures/Screenshots/)
- `SHIFT + Print` → Screenshot full screen to clipboard
- `SUPER + SHIFT + Print` → Screenshot full screen to file

**Media Keys:**
- Volume/brightness controls trigger SwayOSD with Ristretto styling

**Workspaces:**
- `SUPER + 1-9, 0` → Switch workspace
- `SUPER + SHIFT + 1-9, 0` → Move window to workspace

## Important Paths

- System config root: `/home/marcelo/dotfiles/thinkpad-p14s-gen5/`
- Flake: `flake.nix`
- Disko config: `hosts/thinkpad/disko-config.nix`
- System modules: `modules/system/*.nix`
- Home modules: `modules/home/{programs,services,config}/*.nix`
- Theme source (available): `${inputs.themes}/themes/` (from basecamp/omarchy, not actively used)

## Theming

**GTK Theme**: Gruvbox-Dark-BL
- Icon Theme: Papirus-Dark
- Cursor Theme: Bibata-Modern-Classic (24px)
- Dark mode preferred globally

**Hyprland Styling**:
- Custom animations with fluent bezier curves
- Blur enabled (size 5, 2 passes, xray mode)
- Rounded corners (10px)
- Active opacity: 1.0, Inactive: 0.96
- Dynamic opacity rules per application
- Shadows enabled (range 15, power 3)

**Window Opacity Rules**:
- Kitty/Nemo/Thunar: 95%
- Brave: 100% active, 97% inactive
- VS Code: 100% active, 95% inactive
- Media (YouTube/Netflix/Twitch/Discord): 100%
- Default windows: 97% active, 92% inactive

## Development Notes

- This system uses **flakes** - always use `--flake .#pop` when rebuilding
- Hostname `pop` must match flake configuration name
- Unfree packages are allowed globally
- System state version: `25.05` (do not change)
- Home state version: `25.05` (do not change)
- Walker is the **only** launcher (runs as a service via `walker --gapplication-service`)
- **NPM packages**: Use `$HOME/.npm-global/bin` for global npm packages (configured in development.nix)

## Special Configurations

### Ollama (AI)
Access at `http://localhost:11434`
Models stored in `/var/lib/ollama`
ROCm acceleration configured for Radeon 780M

### Blue Light Filter
Multi-level temperature cycle via `SUPER + N`:
1. Off (6500K/default)
2. Low (5500K)
3. Medium (4500K)
4. High (3500K)
5. Very High (2500K)

Custom script using hyprsunset with notifications for each level.

### Btrfs
- Monthly scrub via systemd timer
- Snapshots every 15 minutes via btrbk
- Compression: zstd
- TRIM: async discard enabled

### Web Apps
10 web apps configured as Brave PWAs in `modules/home/programs/webapps.nix`:
- WhatsApp, Spotify, YouTube, ChatGPT, Claude, GitHub, Discord, Proton Mail, Proton Drive, Proton Pass

### Screenshots & Recording
- Screenshots: `~/Pictures/Screenshots/`
- Recordings: `~/Videos/Recordings/`
- Auto-created by UWSM module
