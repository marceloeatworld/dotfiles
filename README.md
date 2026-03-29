# NixOS Dotfiles

Personal NixOS configurations with flakes and home-manager.

## Current Machines

### ThinkPad P14s Gen 5 (AMD) - `pop`

**Primary configuration** - Hyprland (Wayland) with themeable UI (5 themes)

- **Hardware:** AMD Ryzen 7 PRO 8840HS + Radeon 780M (RDNA 3)
- **Kernel:** Zen kernel (optimized for desktop/gaming)
- **Storage:** 1TB NVMe (LUKS + Btrfs, 7 subvolumes)
- **RAM:** 32GB + zram (zstd, 50%)
- **NixOS:** 25.11

**Features:**
- Hyprland tiling WM
- 5 switchable themes (Ristretto, Neobrutalist, Nord, Tokyo Night, Catppuccin)
- Bitcoin wallet monitoring (privacy-focused zpub derivation)
- Automatic VPN DNS switching (dnscrypt-proxy ↔ Proton VPN)
- Local LLM inference (llama.cpp + ROCm, Qwen3.5 models)
- Malware analysis VM (libvirt + network killswitch)
- SDR radio tools (SDR++, GQRX, GNURadio)
- Extensive security toolkit (aircrack-ng, hashcat, nmap, Wireshark, etc.)
- Performance tuning (ananicy-cpp, earlyoom, GameMode)

**Documentation:**
- **[ThinkPad Configuration](thinkpad-p14s-gen5/)** - Full system details
- **[User Guide](thinkpad-p14s-gen5/README.md)** - Complete documentation with keybindings
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
```

## Repository Structure

```
dotfiles/
├── thinkpad-p14s-gen5/           # ThinkPad P14s Gen 5 AMD configuration
│   ├── flake.nix                 # Main flake (nixpkgs-unstable default)
│   ├── overlays/                 # VS Code, Claude Code, llama.cpp overlays
│   ├── hosts/thinkpad/           # Hardware configs, disko (LUKS + Btrfs)
│   ├── modules/
│   │   ├── system/               # 18 system modules (boot, networking, security, etc.)
│   │   └── home/                 # 35 home-manager modules
│   │       ├── programs/         # 24 program modules
│   │       ├── services/         # 4 service modules (waybar, mako, hyprlock, swayosd)
│   │       └── config/           # 7 config modules (theme, gtk, qt, fonts, etc.)
│   ├── assets/icons/             # Local webapp icons
│   └── README.md                 # Complete user documentation
├── vpn/                          # WireGuard configs (gitignored)
├── INSTALLATION-GUIDE.md         # Fresh installation process
└── README.md                     # This file
```

## Key Technologies

- **NixOS 25.11** - Declarative Linux distribution
- **Flakes** - Reproducible builds with locked dependencies
- **Home Manager** - Declarative user environment (35 modules)
- **Disko** - Declarative disk partitioning (LUKS + Btrfs)
- **Hyprland** - Modern Wayland compositor (from official flake)
- **NH (Nix Helper)** - Modern rebuild tool with visual diffs
- **Ghostty** - GPU-accelerated terminal (nightly from flake)

## Common Commands

```bash
cd ~/dotfiles/thinkpad-p14s-gen5/

nh os switch                      # Rebuild system (recommended)
nh os test                        # Test without setting boot default
nh os build                       # Build and show diff
nix flake update                  # Update dependencies
nix flake check                   # Validate configuration
nh clean all --keep 5             # Clean old generations
```

## Shell Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `rebuild` | `nh os switch` | Rebuild system |
| `update` | `nix flake update && update-overlays && nh os switch` | Full update |
| `update-apps` | `update-overlays && nh os switch` | Update VS Code + Claude Code |
| `clean` | `nh clean all --keep 5` | Clean old generations |

**Auto-update functions:**
| Function | Description |
|----------|-------------|
| `update-vscode` | Check/update VS Code from Microsoft API |
| `update-claude-code` | Check/update Claude Code from npm registry |
| `update-llama` | Check/update llama.cpp from GitHub releases |
| `update-overlays` | Update VS Code + Claude Code overlays (`update-llama` is separate) |

## Adding New Machines

1. Create new directory: `mkdir <machine-name>/`
2. Copy structure from `thinkpad-p14s-gen5/`
3. Generate hardware config: `nixos-generate-config`
4. Customize modules for your hardware
5. Update documentation

## License

Personal configuration - use at your own risk.
