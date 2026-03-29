# NixOS Configuration - ThinkPad P14s Gen 5 (AMD)

Personal NixOS configuration with Hyprland and themeable UI.

## System Info

- **Hostname:** pop
- **Hardware:** Lenovo ThinkPad P14s Gen 5
- **CPU:** AMD Ryzen 7 PRO 8840HS (Zen 4)
- **GPU:** Radeon 780M (RDNA 3)
- **RAM:** 32GB + zram (zstd, 50%)
- **Storage:** 1TB NVMe (LUKS + Btrfs, 7 subvolumes)
- **Kernel:** Zen kernel (linuxPackages_zen)
- **WM:** Hyprland (Wayland)
- **Terminal:** Ghostty (nightly) + Alacritty (backup)
- **Launcher:** Hyprlauncher
- **Theme:** 5 themes (Ristretto default, Neobrutalist, Nord, Tokyo Night, Catppuccin)

## Quick Start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles/thinkpad-p14s-gen5

# Build and switch (using NH)
nh os switch

# Traditional method
sudo nixos-rebuild switch --flake .#pop

# Update flake inputs
nix flake update
```

## Structure

```
.
├── flake.nix                 # Main flake (nixpkgs-unstable default)
├── overlays/                 # Custom package overlays
│   ├── vscode-latest.nix     # VS Code from Microsoft CDN
│   ├── claude-code-latest.nix # Claude Code from npm
│   └── llama-cpp-latest.nix  # llama.cpp with ROCm + native CPU opts
├── assets/icons/             # Local webapp icons
├── hosts/thinkpad/
│   ├── configuration.nix     # System config (hostname, packages, nix settings)
│   ├── hardware-configuration.nix
│   └── disko-config.nix      # LUKS + Btrfs (7 subvolumes)
└── modules/
    ├── system/               # 18 system modules
    │   ├── boot.nix          # systemd-boot, Zen kernel, fast shutdown (5s)
    │   ├── networking.nix    # NetworkManager, dnscrypt-proxy2, Bluetooth
    │   ├── hyprland.nix      # Hyprland system config, XDG portal, suspend/resume fix
    │   ├── sound.nix         # PipeWire (low-latency), WirePlumber rules
    │   ├── locale.nix        # en_US.UTF-8, Europe/Lisbon, French keyboard
    │   ├── users.nix         # User marcelo, groups, zsh
    │   ├── security.nix      # Firejail (18 apps), AppArmor, GnuPG, sudo rules
    │   ├── security-tools.nix # nmap, aircrack-ng, hashcat, wireshark, etc.
    │   ├── services.nix      # TLP, llama-cpp, CUPS, BitBox Bridge, llm-switch
    │   ├── virtualisation.nix # Docker, libvirtd/QEMU, AppImage, KVM nested
    │   ├── btrfs.nix         # btrbk snapshots (15min), monthly scrub
    │   ├── amd-optimizations.nix # AMD P-State, RADV, ROCm, NVMe scheduler
    │   ├── steam.nix         # Steam + Proton GE + GameMode
    │   ├── fonts.nix         # System fonts (Inter, Liberation, Nerd Fonts)
    │   ├── vpn-dns-switch.nix # Auto DNS switching (dnscrypt ↔ VPN DNS)
    │   ├── ddcutil.nix       # DDC/CI for external monitor brightness
    │   ├── performance.nix   # zram, ananicy-cpp, earlyoom, GameMode
    │   └── nh.nix            # NH (Nix Helper) config
    └── home/                 # Home Manager modules
        ├── home.nix          # Root config, imports 35 modules
        ├── programs/         # 24 program modules
        │   ├── hyprland.nix  # WM config, keybindings, scripts, window rules
        │   ├── terminal.nix  # Ghostty + Alacritty
        │   ├── shell.nix     # Zsh, Starship, aliases, auto-update functions
        │   ├── git.nix       # Git + delta + lazygit
        │   ├── nvim.nix      # Neovim (50+ plugins, LSP, Copilot)
        │   ├── development.nix # VS Code, C++, Node, Python, Go, Rust, .NET
        │   ├── claude-code.nix # Claude Code AI assistant config
        │   ├── vpn.nix       # VPN manager (country-code WireGuard switching)
        │   ├── webapps.nix   # PWAs (WhatsApp, YouTube, ChatGPT, etc.)
        │   ├── desktop-apps.nix # Desktop entries
        │   ├── media.nix     # PhotoGIMP, Kdenlive, Flowblade, Spotify, VLC
        │   ├── nemo.nix      # Nemo file manager + 18 custom actions
        │   ├── hyprlauncher.nix # App launcher config
        │   ├── btop.nix      # System monitor
        │   ├── fastfetch.nix # System info
        │   ├── malware-vm.nix # Malware analysis VM (libvirt + killswitch)
        │   ├── security-packages.nix # Security tool aliases
        │   ├── radio-sdr.nix # SDR tools (SDR++, GQRX, GNURadio)
        │   ├── mangohud.nix  # In-game overlay
        │   ├── teamspeak.nix # TeamSpeak 6
        │   ├── xournalpp.nix # PDF annotation
        │   ├── zathura.nix   # PDF viewer
        │   ├── yt-dlp.nix    # YouTube downloader
        │   └── uwsm.nix      # Wayland session manager
        ├── services/
        │   ├── waybar.nix    # Status bar + 13 custom scripts
        │   ├── mako.nix      # Notifications
        │   ├── hyprlock.nix  # Screen locker + hypridle
        │   └── swayosd.nix   # Volume/brightness OSD
        └── config/
            ├── theme.nix     # 5 themes (colors + fonts, read from current-theme)
            ├── gtk.nix       # Adwaita-dark, Yaru-yellow icons, Bibata cursor
            ├── qt.nix        # Kvantum (KvArcDark)
            ├── fontconfig.nix # Font fallbacks
            ├── webapp-icons.nix # Custom webapp icons
            ├── hyprpaper.nix # Wallpaper
            └── mimeapps.nix  # File associations
```

## Features

- **Hyprland** - Tiling Wayland compositor
- **5 Themes** - Switch with `theme-selector` (Ristretto, Neobrutalist, Nord, Tokyo Night, Catppuccin)
- **Firejail** - 18 sandboxed apps (Brave, Wireshark, KeePassXC, LibreOffice, etc.)
- **Hyprlauncher** - Official Hyprland app launcher
- **Ghostty** - GPU-accelerated terminal (nightly from flake)
- **Bitcoin Wallet Monitor** - Privacy-focused zpub derivation, Waybar integration
- **DNS Privacy** - AdGuard + Mullvad + Quad9 via dnscrypt-proxy2
- **VPN Integration** - Auto DNS switching (dnscrypt ↔ Proton VPN WireGuard)
- **Local LLM** - llama.cpp with ROCm (Qwen3.5 4B/9B models)
- **Malware Analysis VM** - libvirt Windows VM with network killswitch
- **SDR Radio** - SDR++, GQRX, GNURadio, RTL-SDR
- **Security Toolkit** - nmap, aircrack-ng, hashcat, Wireshark, sqlmap, etc.
- **Performance** - zram, ananicy-cpp, earlyoom, GameMode, Zen kernel
- **Btrfs Snapshots** - Every 15 minutes (btrbk), 7-day retention
- **TLP Power** - Battery conservation mode (55-60% default)
- **Steam** - Proton GE, GameMode, MangoHud overlay

## Keybindings

### Hyprland (Window Manager)

**Applications**
| Key | Action |
|-----|--------|
| `SUPER + Return` | Ghostty terminal |
| `SUPER + B` | Brave browser |
| `SUPER + E` | Nemo file manager |
| `SUPER + A` | Audio control (hyprpwcenter) |
| `SUPER + D` | Hyprlauncher |
| `SUPER + V` | Clipboard history (cliphist + wofi) |
| `SUPER + Shift + V` | Clear clipboard |
| `SUPER + O` | Quick notes (floating nvim) |
| `SUPER + I` | System info panel |
| `SUPER + F1` | Keybindings cheatsheet |

**Window Management**
| Key | Action |
|-----|--------|
| `SUPER + Q` | Kill window |
| `SUPER + Shift + Q` | Force kill |
| `SUPER + F` | Fullscreen |
| `SUPER + Shift + F` | Fullscreen (keep bar) |
| `SUPER + Space` | Toggle floating |
| `SUPER + P` | Pin window (all workspaces) |
| `SUPER + T` | Toggle split direction |
| `SUPER + W` | Center window |
| `SUPER + H/J/K/L` | Move focus (vim-style) |
| `SUPER + Shift + H/J/K/L` | Move window |
| `SUPER + Ctrl + H/J/K/L` | Resize (40px) |
| `SUPER + 1-9, 0` | Switch workspace |
| `SUPER + Shift + 1-9, 0` | Move to workspace |
| `SUPER + ALT + H/L` | Move window to prev/next workspace |

**Groups**
| Key | Action |
|-----|--------|
| `SUPER + G` | Toggle group |
| `SUPER + [ / ]` | Prev/next tab in group |
| `SUPER + Shift + G` | Lock group |

**Scratchpad & Minimize**
| Key | Action |
|-----|--------|
| `SUPER + S` | Toggle scratchpad |
| `SUPER + Shift + S` | Move to scratchpad |
| `SUPER + minus` | Minimize to special |
| `SUPER + Shift + minus` | Show minimized |

**Screenshots**
| Key | Action |
|-----|--------|
| `Print` | Region screenshot → clipboard |
| `SUPER + Print` | Region screenshot → file |
| `Shift + Print` | Full screenshot → clipboard |
| `SUPER + Shift + Print` | Full screenshot → file |

**System**
| Key | Action |
|-----|--------|
| `SUPER + Escape` | Lock screen (hyprlock) |
| `SUPER + Shift + Escape` | Power off |
| `SUPER + Ctrl + Escape` | Reboot |
| `SUPER + ALT + Escape` | Suspend |
| `SUPER + Ctrl + Shift + Escape` | Monitors off (DPMS) |
| `SUPER + C` | Color picker |
| `SUPER + N` | Blue light filter cycle (8 levels: 5500K → 1000K, then off) |
| `SUPER + Shift + N` | Blue light off |
| `SUPER + M` | Battery charge mode (Conservation → Balanced → Full) |
| `SUPER + Shift + M` | Performance mode cycle |
| `SUPER + F2` | WiFi reconnect |
| `SUPER + Shift + F2` | WiFi scan & connect |
| `SUPER + Ctrl + F2` | Toggle WiFi |
| `SUPER + Shift + R` | Restart Waybar |

**Media Keys**
| Key | Action |
|-----|--------|
| Volume Up/Down | SwayOSD volume |
| Mute | Mute toggle |
| Mic Mute | Mic mute toggle |
| Brightness Up/Down | SwayOSD brightness |
| Play/Next/Prev | playerctl |

**Mouse**
| Key | Action |
|-----|--------|
| `SUPER + Left Drag` | Move window |
| `SUPER + Right Drag` | Resize window |

---

### Ghostty Terminal

| Key | Action |
|-----|--------|
| `Ctrl+Shift+T` | New tab |
| `Ctrl+Shift+W` | Close tab |
| `Ctrl+Shift+Right/Left` | Next/prev tab |
| `Ctrl+Shift+Enter` | Split down |
| `Ctrl+Shift+\` | Split right |
| `Ctrl+Shift+H/J/K/L` | Navigate splits |
| `Ctrl+Alt+H/J/K/L` | Resize splits |
| `Ctrl+Shift+E` | Equalize splits |
| `Ctrl+Shift+C/V` | Copy/Paste |
| `Ctrl+Shift+=/-/0` | Font size +/-/reset |
| Mouse select | Auto-copy to clipboard |

---

### Shell (Zsh) Aliases

**NixOS**
| Alias | Command |
|-------|---------|
| `rebuild` | `nh os switch` |
| `update` | `nix flake update && update-overlays && nh os switch` |
| `update-apps` | `update-overlays && nh os switch` |
| `clean` | `nh clean all --keep 5` |
| `nb` | `nh os boot` |
| `ntest` | `nh os test` |
| `ndiff` | `nh os build` |

**Modern CLI**
| Alias | Command |
|-------|---------|
| `ls` | `eza --icons` |
| `ll` | `eza -l --icons` |
| `la` | `eza -la --icons` |
| `tree` | `eza --tree --icons` |
| `cat` | `bat` |

**Git**
| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs/ga/gc/gp/gl/gd` | git status/add/commit/push/pull/diff |

**Other**
| Alias | Command |
|-------|---------|
| `v` / `vim` | `nvim` |
| `..` / `...` | `cd ..` / `cd ../..` |
| `captive-on/off` | Captive portal DNS bypass |

**Auto-update functions:** `update-vscode`, `update-claude-code`, `update-llama` (separate), `update-overlays` (VS Code + Claude Code only)

---

### VPN Commands

| Command | Action |
|---------|--------|
| `vpn` | Toggle VPN (default: Portugal) |
| `vpn <code>` | Connect to country (pt, fr, us, lt) |
| `vpn off` | Disconnect |
| `vpn status` | Show current status |
| `vpn list` | List available servers |
| `vpn import` | Import configs from ~/dotfiles/vpn/ |
| `vpn reset` | Remove all and reimport |

---

### LLM Commands

| Command | Action |
|---------|--------|
| `llm "prompt"` | Chat with local LLM |
| `llm-switch` | Show active model |
| `llm-switch 4b` | Switch to Qwen3.5-4B (2.7GB, fast) |
| `llm-switch 9b` | Switch to Qwen3.5-9B Uncensored (5.6GB) |
| `llm-switch stop` | Stop LLM service |

---

### Claude Code (Slash Commands)

**Planning & Workflow**
| Command | Action |
|---------|--------|
| `/plan` | Create implementation plan (waits for confirmation before coding) |
| `/blueprint <project> "objective"` | Multi-session/multi-PR construction plan with cold-start steps |
| `/checkpoint create <name>` | Create named git checkpoint |
| `/checkpoint verify <name>` | Compare current state to checkpoint |
| `/checkpoint list` | Show all checkpoints |

**Quality & Review**
| Command | Action |
|---------|--------|
| `/verify` | Full verification (build, types, lint, tests, secrets, git status) |
| `/verify quick` | Build + type check only |
| `/verify pre-commit` | Checks relevant for commits |
| `/verify pre-pr` | Full checks + security scan |
| `/code-review` | Security & quality review of uncommitted changes |
| `/build-fix` | Iteratively fix build errors (one at a time, minimal changes) |
| `/refactor-clean` | Safely detect and remove dead code with test verification |

**Session Management**
| Command | Action |
|---------|--------|
| `/save-session` | Save session state to `~/.claude/sessions/` for later resumption |
| `/resume-session` | Load last session with full context briefing |
| `/resume-session <date>` | Resume specific date's session |

**Learning**
| Command | Action |
|---------|--------|
| `/learn` | Extract reusable patterns from current session to `~/.claude/skills/learned/` |

**Skills (auto-loaded when relevant)**
| Skill | Purpose |
|-------|---------|
| `search-first` | Research nixpkgs/PyPI/GitHub before writing custom code |
| `verification-loop` | Build → types → lint → tests → security → diff review |
| `blueprint` | Multi-session planning with dependency graphs |
| `security-scan` | Audit `.claude/` config for vulnerabilities |

---

### Neovim (LazyVim-style)

**Leader Key:** `Space` | **Local Leader:** `\`

**Essential**
| Key | Action |
|-----|--------|
| `i` | Insert mode |
| `Ctrl c` | Back to Normal mode |
| `Space w` | Save file |
| `Space q` | Quit |

**Navigation**
| Key | Action |
|-----|--------|
| `Space f f` | Find files (Telescope) |
| `Space f g` | Live grep |
| `Space f b` | Buffers list |
| `Space f r` | Recent files |
| `Space e` | File explorer (Neo-tree) |
| `-` | Parent directory (Oil.nvim) |
| `s` | Flash jump (2-3 keystrokes to anywhere) |

**Code**
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover docs |
| `Space c a` | Code actions |
| `Space c r` | Rename symbol |
| `Space c f` | Format code |

**Git**
| Key | Action |
|-----|--------|
| `Space g g` | LazyGit |
| `Space g n` | Neogit |
| `Space g d` | Diff view |

**LSP Servers:** nil (Nix), lua_ls, pyright, rust_analyzer, ts_ls, gopls, clangd

**AI:** GitHub Copilot (auto-trigger, Tab to accept)

---

## DNS Configuration

| Provider | Location | Features |
|----------|----------|----------|
| **AdGuard** | Cyprus | Ads + trackers + malware blocking |
| **Mullvad** | Sweden | Aggressive ad-blocking |
| **Quad9** | Europe | Malware + phishing blocking |

All encrypted via DNSCrypt + DoH with DNSSEC enabled.

**Automatic VPN DNS switching:**
| Status | DNS | dnscrypt-proxy2 |
|--------|-----|-----------------|
| VPN OFF | AdGuard/Mullvad/Quad9 | Active |
| VPN ON | Proton VPN DNS | Stopped |

---

## Waybar Modules

Status bar with 20+ modules including:
- **Bitcoin price** - Coinbase + CoinGecko + Mempool.space APIs
- **Wallet balance** - Privacy-focused zpub derivation (local, keys never leave machine)
- **Polymarket** - Prediction market data
- **Weather** - Weather widget
- **VPN status** - Current VPN connection
- **Audio switch** - Output device switching
- **SystemD failed** - Failed services count
- **Nix updates** - Available update indicator
- **Monitor settings** - Monitor settings (nwg-displays)
- **Removable disks** - USB drive monitoring
- CPU, memory, temperature (CPU + GPU), disk, battery, network, bluetooth, clock, tray

---

## Bitcoin Wallet Monitoring

Privacy-focused wallet balance monitor in Waybar.

- Derives addresses from zpub keys **locally** (embit library)
- zpub keys **never leave your machine**
- BIP84 compliant (external + change chains)
- Gap limit scanning (50 consecutive empty = stop)
- Smart caching (only scans new addresses incrementally)

**Setup:**
```bash
cp ~/.config/waybar/.env.example ~/.config/waybar/.env
nano ~/.config/waybar/.env
# Add WALLET_1_NAME, WALLET_1_ZPUB, etc.
```

**Usage:**
```bash
~/.config/waybar/scripts/wallets.py --scan   # Incremental scan
~/.config/waybar/scripts/wallets.py --force  # Full rescan
```

---

## Malware Analysis VM

Windows VM with network isolation for malware analysis.

| Command | Action |
|---------|--------|
| `malware-vm start` | Start VM |
| `malware-vm killswitch` | Isolate network (no internet) |
| `malware-vm network-on` | Enable NAT networking |
| `malware-vm snapshot` | Create snapshot |
| `malware-vm restore` | Restore to last snapshot |
| `malware-vm status` | Show status |

---

## Security Tools

Installed tools (many Firejailed):

**Network:** nmap, tcpdump, ngrep, Wireshark, bettercap
**Wireless:** aircrack-ng, wifite2, reaver, pixiewps, kismet, mdk4, hcxtools
**Password:** hashcat, john, hydra
**Web:** sqlmap, nikto, dirb
**Crypto:** CyberChef
**RE/Binary:** Ghidra, angr
**Recon:** whois, dnsutils, testssl, sslscan

Aliases: `nmap-quick`, `nmap-full`, `nmap-vuln`, `wifite-auto`, `hashcat-gpu`, etc.

---

## Installed Services

| Service | Description |
|---------|-------------|
| **llama-cpp** | Local LLM (port 8080, OpenAI API compatible) |
| **dnscrypt-proxy** | Encrypted DNS (AdGuard, Mullvad, Quad9) |
| **TLP** | Power management (conservation: 55-60%) |
| **btrbk** | Btrfs snapshots every 15min |
| **ananicy-cpp** | Process priority optimization |
| **earlyoom** | OOM prevention (5% RAM threshold) |
| **Docker** | Container runtime (not on boot) |
| **libvirtd** | KVM/QEMU virtualization |
| **BitBox Bridge** | Hardware wallet bridge |
| **Steam** | Gaming with Proton GE |

---

## Adapting to Different Hardware

### Portable (works anywhere)
- All `modules/home/` configs
- Web apps, themes, icons
- DNS and network settings

### Hardware-specific (needs changes)
- `hosts/thinkpad/hardware-configuration.nix` - Regenerate with `nixos-generate-config`
- `hosts/thinkpad/disko-config.nix` - Check disk name (`lsblk`)
- `modules/system/amd-optimizations.nix` - AMD only, remove for Intel
- `flake.nix` - nixos-hardware module is ThinkPad P14s Gen 5 specific
- `modules/home/programs/hyprland.nix` - Monitor layout

---

## Installation

See [INSTALLATION-GUIDE.md](../INSTALLATION-GUIDE.md) for detailed steps.

## License

Personal configuration - use at your own risk.
