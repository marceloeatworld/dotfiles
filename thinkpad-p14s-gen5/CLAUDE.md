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
- Theme: Ristretto (applied system-wide)

## Architecture

### Flake Structure (flake.nix)

The flake defines `nixosConfigurations.pop` and imports:
- **nixpkgs**: NixOS 25.05 channel
- **nixpkgs-unstable**: Latest packages when needed
- **disko**: Declarative disk partitioning (LUKS + Btrfs with 7 subvolumes)
- **home-manager**: User environment management (release-25.05)
- **hyprland**: Wayland compositor from upstream
- **nixos-hardware**: Official ThinkPad P14s Gen 5 AMD profile
- **themes**: Hyprland themes from basecamp/omarchy (Ristretto theme)
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
- **Window Manager**: Hyprland with Ristretto theme
- **Launcher**: Walker (single launcher, Ristretto theme)
- **Terminal**: Kitty with Ristretto theme, 14px padding, block cursor
- **Status Bar**: Waybar (Ristretto theme)
- **Notifications**: Mako (Ristretto theme)
- **OSD**: SwayOSD for volume/brightness (Ristretto theme)
- **Shell**: Zsh with Starship prompt
- **Editor**: Neovim (primary), VS Code
- **Browser**: Brave with Wayland flags
- **Fonts**: Liberation Sans/Serif, CaskaydiaMono Nerd Font, JetBrains Mono

### AI & Development
- **Ollama**: Local LLM with ROCm acceleration for AMD GPU
  - `HSA_OVERRIDE_GFX_VERSION=11.0.0` (RDNA 3 iGPU fix)
  - Service runs on `http://127.0.0.1:11434`
- **AI Tools**: aichat (CLI), parllama (TUI)
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
- `SUPER + N` → Toggle blue light filter (hyprsunset 4500K)
- `Print` → Screenshot to clipboard
- `SUPER + Print` → Screenshot to file

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
- Theme source: `${inputs.themes}/themes/ristretto/` (from basecamp/omarchy)

## Theme: Ristretto

All applications use the Ristretto color palette from the Omarchy theme collection:
- Background: `#2c2525` (dark brown)
- Foreground: `#e6d9db` (beige/rose)
- Accent: `#f9cc6c` (golden yellow)
- Cursor: `#c3b7b8` (light beige)

**Themed applications:**
1. Hyprland - borders, colors from `${inputs.themes}/themes/ristretto/hyprland.conf`
2. Kitty - full 16-color palette
3. Walker - theme + custom CSS
4. SwayOSD - CSS styling
5. Mako - notification colors
6. Waybar - status bar styling

## Development Notes

- This system uses **flakes** - always use `--flake .#pop` when rebuilding
- Hostname `pop` must match flake configuration name
- Unfree packages are allowed globally
- System state version: `25.05` (do not change)
- Home state version: `25.05` (do not change)
- No variable names reference "omarchy" - only theme path uses it
- Walker is the **only** launcher (wofi was removed)

## Special Configurations

### Ollama (AI)
Access at `http://localhost:11434`
Models stored in `/var/lib/ollama`
ROCm acceleration configured for Radeon 780M

### Btrfs
- Monthly scrub via systemd timer
- Snapshots every 15 minutes via btrbk
- Compression: zstd
- TRIM: async discard enabled

### Web Apps
7 web apps configured as Brave PWAs in `modules/home/programs/webapps.nix`:
- WhatsApp, Spotify, YouTube, ChatGPT, Claude, GitHub, Discord

### Screenshots & Recording
- Screenshots: `~/Pictures/Screenshots/`
- Recordings: `~/Videos/Recordings/`
- Auto-created by UWSM module
