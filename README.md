# NixOS Dotfiles

Personal NixOS configurations with flakes and home-manager.

## Current Machines

### ThinkPad P14s Gen 5 (AMD) - `pop`

**Primary configuration** - Hyprland (Wayland) with Ristretto theme

- **Hardware:** AMD Ryzen 7 PRO 8840HS + Radeon 780M
- **Storage:** 1TB NVMe (LUKS + Btrfs)
- **RAM:** 32GB
- **NixOS:** 25.11

**Features:**
- Hyprland tiling window manager
- Bitcoin wallet monitoring (privacy-focused)
- Automatic VPN DNS switching
- Windows 11 VM (Docker + RDP)
- Local LLM with AMD GPU acceleration (Ollama + ROCm)
- Advanced power management (TLP)

**Documentation:**
- **[ThinkPad Configuration](thinkpad-p14s-gen5/)** - Full system details
- **[User Guide](thinkpad-p14s-gen5/README.md)** - Complete documentation with keybindings and features
- **[Installation Guide](INSTALLATION-GUIDE.md)** - Fresh installation steps

## Quick Start

```bash
# Clone repository
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles/thinkpad-p14s-gen5/

# Rebuild system (using NH - modern nixos-rebuild)
nh os switch

# Traditional method
sudo nixos-rebuild switch --flake .#pop

# Update all flake inputs
nix flake update

# Test configuration without applying
nh os test
```

## Repository Structure

```
dotfiles/
├── thinkpad-p14s-gen5/           # ThinkPad P14s Gen 5 AMD configuration
│   ├── flake.nix                 # Main flake configuration
│   ├── hosts/thinkpad/           # Hardware configs, disko
│   ├── modules/                  # System & home-manager modules
│   │   ├── system/              # Boot, networking, services, etc.
│   │   └── home/                # User environment (Hyprland, apps, etc.)
│   ├── assets/icons/            # Local webapp icons
│   └── README.md                # Complete user documentation
├── INSTALLATION-GUIDE.md        # Fresh installation process
└── README.md                    # This file
```

## Key Technologies

- **NixOS 25.11** - Declarative Linux distribution
- **Flakes** - Reproducible builds with locked dependencies
- **Home Manager** - Declarative user environment
- **Disko** - Declarative disk partitioning
- **Hyprland** - Modern Wayland compositor
- **NH (Nix Helper)** - Modern rebuild tool with better UX

## Common Commands

```bash
# Navigate to configuration
cd ~/dotfiles/thinkpad-p14s-gen5/

# Rebuild system
nh os switch                      # Modern method (recommended)
sudo nixos-rebuild switch --flake .#pop  # Traditional method

# Update dependencies
nix flake update

# Test changes
nh os test

# Validate configuration
nix flake check

# Clean old generations
nh clean all --keep 5

# Search packages
nix search nixpkgs <package-name>
```

## Shell Aliases (configured)

- `rebuild` → `nh os switch`
- `update` → `nix flake update && nh os switch`
- `clean` → `nh clean all --keep 5`

## Adding New Machines

To add another machine to this repository:

1. Create new directory: `mkdir <machine-name>/`
2. Copy structure from `thinkpad-p14s-gen5/`
3. Generate hardware config: `nixos-generate-config`
4. Customize modules for your hardware
5. Update documentation

## License

Personal configuration - use at your own risk.
