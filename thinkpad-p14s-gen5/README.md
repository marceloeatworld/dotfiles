# NixOS Configuration - ThinkPad P14s Gen 5 (AMD)

Personal NixOS configuration with Hyprland and Ristretto theme.

## System Info

- **Hostname:** pop
- **Hardware:** Lenovo ThinkPad P14s Gen 5
- **CPU:** AMD Ryzen 7 PRO 8840HS
- **GPU:** Radeon 780M (RDNA 3)
- **RAM:** 32GB
- **Storage:** 1TB NVMe (LUKS + Btrfs)
- **WM:** Hyprland (Wayland)
- **Theme:** Ristretto

## Quick Start

```bash
# Clone repository
git clone <your-repo-url> ~/dotfiles/thinkpad-p14s-gen5
cd ~/dotfiles/thinkpad-p14s-gen5

# Build and switch
sudo nixos-rebuild switch --flake .#pop

# Update flake inputs
nix flake update
```

## Structure

```
.
├── flake.nix                 # Main flake configuration
├── hosts/thinkpad/
│   ├── configuration.nix     # System configuration
│   ├── hardware-configuration.nix
│   └── disko-config.nix      # Disk partitioning (LUKS + Btrfs)
└── modules/
    ├── system/               # System-level configs
    │   ├── boot.nix
    │   ├── networking.nix
    │   ├── hyprland.nix
    │   ├── services.nix      # TLP, Ollama, CUPS, etc.
    │   ├── amd-optimizations.nix
    │   └── ...
    └── home/                 # Home Manager configs
        ├── home.nix
        ├── programs/         # App configs (Kitty, Walker, etc.)
        ├── services/         # Waybar, Mako, SwayOSD
        └── config/           # GTK, Qt, fonts
```

## Features

- **Hyprland** - Tiling Wayland compositor with Ristretto theme
- **Walker** - Modern application launcher
- **Kitty** - GPU-accelerated terminal
- **Ollama** - Local LLM with AMD GPU acceleration (ROCm)
- **TLP** - Advanced power management (75-80% battery threshold)
- **Btrfs** - Compression, snapshots, monthly scrub
- **Docker + VMware** - Containerization and virtualization

## Keybindings

| Key | Action |
|-----|--------|
| `SUPER + D` | Walker launcher |
| `SUPER + Return` | Kitty terminal |
| `SUPER + B` | Brave browser |
| `SUPER + N` | Blue light filter toggle |
| `SUPER + Escape` | Lock screen |
| `Print` | Screenshot |

See [CLAUDE.md](CLAUDE.md) for complete documentation.

## Installation

See [INSTALLATION-GUIDE.md](INSTALLATION-GUIDE.md) for detailed installation instructions.

## License

Personal configuration - use at your own risk.
