# ThinkPad P14s Gen 5 (AMD) - NixOS Configuration

This directory contains my NixOS configuration for **ThinkPad P14s Gen 5 (AMD)**.

For general documentation, see the main [README.md](../README.md) and [INSTALLATION-GUIDE.md](../INSTALLATION-GUIDE.md) in the parent directory.

## Hardware Specs

- **Model:** Lenovo ThinkPad P14s Gen 5
- **CPU:** AMD Ryzen 7 PRO 8840HS (8C/16T, up to 5.1GHz)
- **GPU:** AMD Radeon 780M (RDNA 3 integrated)
- **RAM:** 32GB LPDDR5X-6400
- **Storage:** 1TB NVMe SSD
- **Display:** 14" 1920x1200 IPS
- **Battery:** 52.5Wh

## Quick Start

```bash
# Clone this repo
git clone https://github.com/marceloeatworld/dotfiles ~/dotfiles
cd ~/dotfiles/thinkpad-p14s-gen5

# Build and switch
sudo nixos-rebuild switch --flake .#pop
```

## Adapting to Your Hardware

If you want to use this configuration on **different hardware**, follow these steps:

### 1. Generate Hardware Configuration

```bash
# Boot NixOS live USB on your machine
# Generate hardware config
sudo nixpkgs-hardware-generate-config --dir /tmp/nixos

# Copy to your dotfiles
cp /tmp/nixos/hardware-configuration.nix ~/dotfiles/YOUR-MACHINE/hosts/YOUR-HOSTNAME/
```

### 2. Update Hostname

**Edit `flake.nix`:**
```nix
nixosConfigurations.YOUR-HOSTNAME = nixpkgs.lib.nixosSystem {
  # Change "pop" to your hostname
```

**Edit `hosts/YOUR-HOSTNAME/configuration.nix`:**
```nix
networking.hostName = "YOUR-HOSTNAME";  # Change from "pop"
```

### 3. Adjust Hardware-Specific Settings

**CPU Optimizations** (`modules/system/amd-optimizations.nix`):
- If you have **Intel CPU**, remove or adapt this file
- For AMD CPUs, verify governor and EPP settings match your model

**GPU Settings**:
- **AMD GPU**: Keep current ROCm/RADV settings
- **NVIDIA GPU**: Replace with NVIDIA drivers (see NixOS wiki)
- **Intel GPU**: Remove AMD-specific settings, add Intel VA-API

**TLP Battery Thresholds** (`modules/system/services.nix`):
```nix
# Adjust for your battery model
START_CHARGE_THRESH_BAT0 = 75;  # Change if needed
STOP_CHARGE_THRESH_BAT0 = 80;   # Change if needed
```

### 4. Disk Configuration (IMPORTANT!)

**Edit `hosts/YOUR-HOSTNAME/disko-config.nix`:**

```nix
# Change disk name if different
disko.devices.disk.main = {
  device = "/dev/nvme0n1";  # Verify with 'lsblk'
  # ...
```

**Different disk layout?**
- Run `lsblk` to find your disk name
- Adjust partition sizes in `disko-config.nix`
- Update Btrfs subvolumes if needed

### 5. Remove Hardware-Specific Modules

**Not needed for your hardware?** Remove from `hosts/YOUR-HOSTNAME/configuration.nix`:

```nix
# Remove if you don't have this hardware
nixos-hardware.nixosModules.lenovo-thinkpad-p14s-amd-gen5  # ThinkPad specific
modules/system/amd-optimizations.nix                       # AMD specific
```

### 6. Test Before Installing

```bash
# Build without installing
sudo nixos-rebuild build --flake .#YOUR-HOSTNAME

# Test configuration (temporary, not permanent)
sudo nixos-rebuild test --flake .#YOUR-HOSTNAME

# Install permanently
sudo nixos-rebuild switch --flake .#YOUR-HOSTNAME
```

## Directory Structure

```
.
├── flake.nix                    # Main configuration (CHANGE HOSTNAME HERE)
├── hosts/
│   └── thinkpad/
│       ├── configuration.nix    # System config (CHANGE HOSTNAME)
│       ├── hardware-configuration.nix  # Generated (REGENERATE FOR YOUR PC)
│       └── disko-config.nix     # Disk layout (VERIFY DISK NAME)
├── modules/
│   ├── system/                  # System-level (check hardware compatibility)
│   │   ├── amd-optimizations.nix   # AMD ONLY - remove for Intel
│   │   ├── boot.nix
│   │   ├── networking.nix
│   │   └── ...
│   └── home/                    # User-level (mostly portable)
│       ├── programs/
│       ├── services/
│       └── config/
└── assets/icons/                # Portable (works on any system)
```

## What's Portable vs Hardware-Specific

### ✅ Portable (Works on Any System)
- All `modules/home/` configs (Hyprland, Waybar, Kitty, etc.)
- Web apps and desktop entries
- Shell configuration (Zsh, Starship)
- Neovim configuration
- Icons and themes
- DNS configuration
- Docker and virtualization (if supported)

### ⚠️ Hardware-Specific (Needs Adjustment)
- `hosts/thinkpad/hardware-configuration.nix` - **MUST regenerate**
- `hosts/thinkpad/disko-config.nix` - **Verify disk name**
- `modules/system/amd-optimizations.nix` - **AMD CPUs only**
- `modules/system/services.nix` - **Check TLP battery settings**
- `flake.nix` nixos-hardware module - **ThinkPad P14s Gen 5 only**

### 🔧 Needs Verification
- `modules/system/boot.nix` - Bootloader settings (usually OK)
- `modules/system/hyprland.nix` - Monitor configuration
- `modules/system/services.nix` - Ollama ROCm (AMD GPU only)

## Common Adaptations

### Different Display Resolution/Scaling

**Edit `modules/home/programs/hyprland.nix`:**
```nix
monitor = DP-1,1920x1080@60,0x0,1  # Change resolution/refresh rate
# or
monitor = ,preferred,auto,1.5      # Auto with 1.5x scaling
```

### Different WiFi/Ethernet

NetworkManager auto-detects. No changes needed.

### Different GPU

**NVIDIA:**
```nix
# In configuration.nix
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia.modesetting.enable = true;
```

**Intel:**
```nix
# Remove modules/system/amd-optimizations.nix
# Intel drivers work out of the box
```

### No Virtualization Support

**Remove/disable in `modules/system/virtualisation.nix`:**
```nix
virtualisation.docker.enable = false;
virtualisation.libvirtd.enable = false;
```

## Getting Help

1. **NixOS Manual:** https://nixos.org/manual/nixos/stable/
2. **NixOS Hardware:** https://github.com/NixOS/nixos-hardware
3. **My Full Docs:** See parent [README.md](../README.md)

## License

Personal configuration - use at your own risk. Adapt as needed.
