# NixOS Dotfiles

Personal NixOS configurations with flakes and home-manager.

## Current Machines

### ThinkPad P14s Gen 5 (AMD) - `pop`

**Primary configuration** - Hyprland (Wayland) with themeable UI (5 themes)

- **Hardware:** AMD Ryzen 7 PRO 8840HS + Radeon 780M (RDNA 3)
- **Kernel:** `linuxPackages_latest` (currently 7.0.1)
- **Storage:** 1TB NVMe (LUKS + Btrfs, 7 subvolumes)
- **RAM:** 32GB + zram (zstd, 75% / ~24GB)
- **NixOS:** `nixos-unstable` (currently 26.05.20260422)
- **State versions:** NixOS/Home Manager 25.05

**Features:**
- Hyprland tiling WM with UWSM session management
- 5 switchable themes (Ristretto, Neobrutalist, Nord, Tokyo Night, Catppuccin)
- Bitcoin wallet monitoring (privacy-focused zpub derivation)
- Automatic VPN DNS switching (dnscrypt-proxy / Proton VPN)
- Local LLM inference (llama.cpp + ROCm, Qwen3.5 9B + GLM-OCR vision)
- AI coding agents (Claude Code, ForgeCode, OpenCode, Codex, Hermes Agent)
- Kali red-team container with Hermes AI profiles
- Malware analysis VM (libvirt + network killswitch)
- SDR radio tools (SDR++, GQRX, GNURadio)
- Extensive security toolkit (aircrack-ng, hashcat, nmap, Wireshark, Ghidra, angr, etc.)
- Performance tuning (zram 75%, ananicy-cpp, earlyoom, GameMode, app memory slices)
- Firejail sandboxing for 18 wrapped apps plus dedicated Brave/Brave-HW profiles + AppArmor

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
nh os switch .

# Traditional method
sudo nixos-rebuild switch --flake .#pop

# Update all flake inputs
nix flake update
```

## Repository Structure

```
dotfiles/
├── thinkpad-p14s-gen5/           # ThinkPad P14s Gen 5 AMD configuration
│   ├── flake.nix                 # Main flake (nixos-unstable + 8 overlays)
│   ├── flake.lock                # Locked inputs (current system: 26.05.20260422)
│   ├── overlays/                 # 8 custom package overlays
│   ├── hosts/thinkpad/           # Hardware configs, disko (LUKS + Btrfs)
│   ├── sops/                     # Encrypted secrets (age/sops-nix)
│   ├── modules/
│   │   ├── system/               # 20 system modules (boot, networking, security, etc.)
│   │   └── home/                 # 42 home-manager imports
│   │       ├── programs/         # 30 program modules
│   │       ├── services/         # 4 service modules (waybar, mako, hyprlock, swayosd)
│   │       └── config/           # 8 config modules (theme, gtk, qt, fonts, secrets, etc.)
│   ├── assets/icons/             # Local webapp icons
│   └── README.md                 # Complete user documentation
├── vpn/                          # WireGuard configs (gitignored)
├── INSTALLATION-GUIDE.md         # Fresh installation process
└── README.md                     # This file
```

## Key Technologies

- **NixOS unstable / 26.05 generation** - Declarative Linux distribution
- **Flakes** - Reproducible builds with locked dependencies
- **Home Manager** - Declarative user environment (42 imports)
- **Disko** - Declarative disk partitioning (LUKS + Btrfs)
- **Hyprland** - Modern Wayland compositor (from official flake)
- **UWSM** - Universal Wayland Session Manager
- **NH (Nix Helper)** - Modern rebuild tool with visual diffs
- **Ghostty** - GPU-accelerated terminal
- **Hyprlauncher** - Official Hyprland app launcher
- **sops-nix** - Encrypted API keys via age

## Common Commands

```bash
cd ~/dotfiles/thinkpad-p14s-gen5/

nh os switch .                    # Rebuild system (recommended)
nh os test .                      # Test without setting boot default
nh os build .                     # Build and show diff
nix flake update                  # Update dependencies
nix flake check                   # Validate configuration
nh clean all --keep 5             # Clean old generations
```

## Shell Aliases And Functions

| Alias | Command | Description |
|-------|---------|-------------|
| `rebuild` | `cd "$(dotfiles-flake-dir)" && nh os switch .` | Rebuild system |
| `update` | `nix flake update && update-overlays && nh os switch .` | Full update |
| `update-apps` | `update-overlays`, then `nh os switch .` when something changed | Update overlays + agent skills |
| `clean` | `nh clean all --keep 5` | Clean old generations |
| `secrets` | `sops "$(dotfiles-flake-dir)/sops/api-keys.yaml"` | Edit encrypted API keys |

**Auto-update functions:**
| Function | Description |
|----------|-------------|
| `update-vscode` | Check/update VS Code from Microsoft API |
| `update-claude-code` | Check/update Claude Code from npm registry |
| `update-opencode` | Check/update OpenCode from GitHub releases |
| `update-forgecode` | Check/update ForgeCode from GitHub releases |
| `update-codex` | Check/update Codex from GitHub releases |
| `update-runpodctl` | Check/update RunPod CLI from GitHub (Go) |
| `update-pnpm` | Check/update pnpm static binary from GitHub releases |
| `update-skills` | Update all agent skill repos |
| `update-llama` | Check/update llama.cpp from GitHub releases (separate, long build) |
| `update-overlays` | Update all overlays + agent skills (`update-llama` is separate) |

## Adding New Machines

1. Create new directory: `mkdir <machine-name>/`
2. Copy structure from `thinkpad-p14s-gen5/`
3. Generate hardware config: `nixos-generate-config`
4. Customize modules for your hardware
5. Update documentation

## License

Personal configuration - use at your own risk.
