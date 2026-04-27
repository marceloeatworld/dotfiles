# NixOS Configuration - ThinkPad P14s Gen 5 (AMD)

Personal NixOS configuration with Hyprland and themeable UI.

## System Info

- **Hostname:** pop
- **Hardware:** Lenovo ThinkPad P14s Gen 5
- **CPU:** AMD Ryzen 7 PRO 8840HS (Zen 4)
- **GPU:** Radeon 780M (RDNA 3)
- **RAM:** 32GB + zram (zstd, 75% / ~24GB)
- **Storage:** 1TB NVMe (LUKS + Btrfs, 7 subvolumes)
- **Kernel:** `linuxPackages_latest` (currently 7.0.1)
- **NixOS:** `nixos-unstable` (currently 26.05.20260422)
- **State versions:** NixOS/Home Manager 25.05
- **WM:** Hyprland (Wayland) via UWSM
- **Terminal:** Ghostty + Alacritty (backup)
- **Launcher:** Hyprlauncher (daemon mode)
- **Theme:** 5 themes (Ristretto default, Neobrutalist, Nord, Tokyo Night, Catppuccin)

## Quick Start

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles/thinkpad-p14s-gen5

# Build and switch (using NH)
nh os switch .

# Traditional method
sudo nixos-rebuild switch --flake .#pop

# Update flake inputs
nix flake update
```

## Structure

```
.
├── flake.nix                 # Main flake (nixos-unstable / 26.05 snapshot + 8 overlays)
├── flake.lock                # Locked inputs (current system: 26.05.20260422)
├── overlays/                 # Custom package overlays (8)
│   ├── vscode-latest.nix     # VS Code from Microsoft CDN
│   ├── claude-code-latest.nix # Claude Code from npm
│   ├── llama-cpp-latest.nix  # llama.cpp with ROCm + native CPU opts
│   ├── opencode-latest.nix   # OpenCode from GitHub releases (Bun SEA)
│   ├── forgecode-latest.nix  # ForgeCode from GitHub (musl static)
│   ├── codex-latest.nix      # Codex from GitHub releases (OpenAI, Rust musl)
│   ├── runpodctl-latest.nix  # RunPod CLI from GitHub (Go)
│   └── pnpm-latest.nix       # pnpm static binary from GitHub releases
├── assets/icons/             # Local webapp icons
├── hosts/thinkpad/
│   ├── configuration.nix     # System config (hostname, packages, nix settings)
│   ├── hardware-configuration.nix
│   └── disko-config.nix      # LUKS + Btrfs (7 subvolumes)
└── modules/
    ├── system/               # 20 system modules
    │   ├── boot.nix          # systemd-boot, latest kernel, AMD boot params
    │   ├── networking.nix    # NetworkManager, dnscrypt-proxy2, Bluetooth
    │   ├── hyprland.nix      # Hyprland system config, XDG portal, suspend/resume fix
    │   ├── sound.nix         # PipeWire (low-latency), WirePlumber rules
    │   ├── locale.nix        # en_US.UTF-8, Europe/Lisbon, French keyboard
    │   ├── users.nix         # User marcelo, groups, zsh
    │   ├── security.nix      # Firejail (19 apps), AppArmor, GnuPG, sudo rules
    │   ├── security-tools.nix # nmap, aircrack-ng, hashcat, wireshark, etc.
    │   ├── services.nix      # TLP, CUPS, Avahi, BitBox Bridge, desktop services
    │   ├── llama-cpp.nix     # On-demand local LLM/OCR services and llm-switch
    │   ├── virtualisation.nix # Podman (Docker compat), libvirtd/QEMU, AppImage, KVM nested
    │   ├── btrfs.nix         # btrbk snapshots (15min), monthly scrub
    │   ├── amd-optimizations.nix # AMD P-State, RADV, ROCm, NVMe scheduler, GPU overdrive
    │   ├── steam.nix         # Steam + Proton GE + GameMode
    │   ├── fonts.nix         # System fonts (Inter, Liberation, Nerd Fonts)
    │   ├── vpn-dns-switch.nix # Auto DNS switching (dnscrypt ↔ VPN DNS) + captive portal
    │   ├── ddcutil.nix       # DDC/CI for external monitor brightness
    │   ├── performance.nix   # zram, ananicy-cpp, earlyoom, GameMode, sysctl tuning
    │   ├── nh.nix            # NH (Nix Helper) config
    │   └── hermes-agent.nix  # Hermes Agent - AI agent with profiles
    └── home/                 # Home Manager modules
        ├── home.nix          # Root config, imports 42 local modules + sops-nix
        ├── programs/         # 30 program modules
        │   ├── hyprland.nix  # WM config, keybindings, scripts, window rules
        │   ├── terminal.nix  # Ghostty + Alacritty
        │   ├── shell.nix     # Zsh, Starship, aliases, auto-update functions
        │   ├── git.nix       # Git + delta + lazygit
        │   ├── nvim.nix      # Neovim (50+ plugins, LSP, Copilot)
        │   ├── development.nix # VS Code, C++, Node, Python, Go, Rust, .NET
        │   ├── claude-code.nix # Claude Code AI assistant config
        │   ├── ai-skills.nix  # AI agent skills & commands (plan, verify, blueprint)
        │   ├── opencode.nix  # OpenCode AI coding agent config
        │   ├── forgecode.nix # ForgeCode AI coding harness (Rust, ZSH)
        │   ├── codex.nix     # Codex AI coding agent (OpenAI, Rust musl static)
        │   ├── kali-redteam.nix # Kali Linux headless container
        │   ├── vpn.nix       # VPN manager (country-code WireGuard switching)
        │   ├── webapps.nix   # PWAs (WhatsApp, YouTube, ChatGPT, etc.)
        │   ├── desktop-apps.nix # Desktop entries
        │   ├── media.nix     # PhotoGIMP, Kdenlive, Flowblade, Spotify, VLC
        │   ├── nemo.nix      # Nemo file manager + 18 custom actions
        │   ├── hyprlauncher.nix # App launcher config
        │   ├── btop.nix      # System monitor
        │   ├── fastfetch.nix # System info
        │   ├── analysis-vm.nix # Malware analysis lab: FLARE-VM + REMnux + Dev-Win
        │   ├── security-packages.nix # Security tool aliases
        │   ├── radio-sdr.nix # SDR tools (SDR++, rtl-sdr, SoapySDR)
        │   ├── mangohud.nix  # In-game overlay
        │   ├── xournalpp.nix # PDF annotation
        │   ├── zathura.nix   # PDF viewer
        │   ├── yt-dlp.nix    # YouTube downloader
        │   └── uwsm.nix      # Wayland session manager
        ├── services/
        │   ├── waybar.nix    # Status bar + scripted custom modules
        │   ├── mako.nix      # Notifications
        │   ├── hyprlock.nix  # Screen locker + hypridle
        │   └── swayosd.nix   # Volume/brightness OSD
        └── config/
            ├── theme.nix     # 5 themes (colors + fonts, read from current-theme)
            ├── secrets.nix   # sops-nix API keys decryption
            ├── gtk.nix       # Adwaita-dark, Yaru-yellow icons, Bibata cursor
            ├── qt.nix        # Kvantum (KvArcDark)
            ├── fontconfig.nix # Font fallbacks
            ├── webapp-icons.nix # Custom webapp icons
            ├── hyprpaper.nix # Wallpaper
            └── mimeapps.nix  # File associations
```

## Features

- **Hyprland 0.54+** - Tiling Wayland compositor via UWSM, official Hyprland flake, and Mesa matched to the Hyprland input
- **Hypr Ecosystem** - hyprlock, hypridle, hyprpaper, hyprlauncher, hyprsunset, hyprpicker, hyprpwcenter, hyprsysteminfo, hyprfreeze, grimblast, hyprshutdown, hyprprop, hyprmagnifier, hyprmon, hyprcursor
- **5 Themes** - Switch with `theme-selector` (Ristretto, Neobrutalist, Nord, Tokyo Night, Catppuccin)
- **Firejail** - 18 wrapped apps plus dedicated Brave/Brave-HW profiles (Wireshark, KeePassXC, LibreOffice, Ghidra, etc.)
- **AppArmor** - Mandatory access control enabled
- **Ghostty** - GPU-accelerated terminal with splits and tabs
- **Bitcoin Wallet Monitor** - Privacy-focused zpub derivation, Waybar integration
- **DNS Privacy** - AdGuard + Mullvad + Quad9 via dnscrypt-proxy2 (DNSSEC)
- **VPN Integration** - Auto DNS switching (dnscrypt ↔ Proton VPN WireGuard) + captive portal detection
- **Local LLM** - llama.cpp with ROCm (Qwen3.5-9B / Qwopus-9B / GLM-OCR vision)
- **AI Agents** - Claude Code, ForgeCode, OpenCode, Codex, Hermes Agent
- **Kali Red Team Container** - Podman-managed Kali container with Hermes AI aliases
- **Malware Analysis Lab** - 3 VMs (FLARE-VM + REMnux + Dev-Win) with killswitch, fake-internet routing, VirtioFS sample sharing
- **SDR Radio** - SDR++, rtl-sdr, SoapySDR
- **Security Toolkit** - nmap, aircrack-ng, hashcat, Wireshark, sqlmap, Ghidra, etc.
- **Performance** - zram 75%, ananicy-cpp (CachyOS rules), earlyoom, GameMode, app memory slices, latest kernel
- **Btrfs Snapshots** - Every 15 minutes (btrbk), 7-day retention
- **TLP Power** - Battery conservation mode (55-60% default), CPU boost off on battery
- **Steam** - Proton GE, GameMode, MangoHud, Gamescope

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
| `SUPER + Shift + D` | Quick actions menu |
| `SUPER + V` | Clipboard history (cliphist + wofi) |
| `SUPER + Shift + V` | Clear clipboard |
| `SUPER + Y` | YouTube PiP toggle (launch/show/hide) |
| `SUPER + U` | Twitch PiP toggle (launch/show/hide) |
| `SUPER + O` | Quick notes (floating nvim) |
| `SUPER + X` | Malware analysis lab menu |
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
| `SUPER + T` | Toggle split (dwindle) |
| `SUPER + Tab` | Toggle current/last focused window |
| `Alt + Tab` / `Alt + Shift + Tab` | Cycle windows forward/backward |
| `SUPER + W` | Center window |
| `SUPER + H/J/K/L` | Move focus (vim-style) |
| `SUPER + Shift + H/J/K/L` | Move window |
| `SUPER + Ctrl + H/J/K/L` | Resize (40px) |
| `SUPER + Ctrl + Shift + H/J/K/L` | Swap tiled window position |
| `SUPER + 1-9, 0` | Switch workspace |
| `SUPER + Shift + 1-9, 0` | Move to workspace |
| `SUPER + ALT + H/L` | Move window to prev/next workspace |
| `SUPER + Ctrl + 1-5` | Focus workspace on current monitor |
| `SUPER + Ctrl + M` | Move current workspace to next monitor |
| `SUPER + Shift + Tab` | Swap active workspaces between laptop and HDMI monitors |

**Groups**
| Key | Action |
|-----|--------|
| `SUPER + G` | Toggle group |
| `SUPER + [ / ]` | Prev/next tab in group |
| `SUPER + Shift + G` | Lock group |
| `SUPER + Ctrl + [ / ]` | Reorder tabs inside group |

**Scratchpad & Minimize**
| Key | Action |
|-----|--------|
| `SUPER + S` | Toggle scratchpad |
| `SUPER + Shift + S` | Move to scratchpad |
| `SUPER + minus` | Minimize to special |
| `SUPER + Shift + minus` | Show minimized |

**Screenshots (grimblast)**
| Key | Action |
|-----|--------|
| `Print` | Region → clipboard |
| `SUPER + Print` | Region → file |
| `Shift + Print` | Full screen → clipboard |
| `SUPER + Shift + Print` | Full screen → file |
| `SUPER + Ctrl + Print` | Window → clipboard |

**System**
| Key | Action |
|-----|--------|
| `SUPER + Escape` | Lock screen (hyprlock) |
| `SUPER + Shift + Escape` | Shutdown (hyprshutdown — graceful) |
| `SUPER + Ctrl + Escape` | Reboot (hyprshutdown — graceful) |
| `SUPER + ALT + Escape` | Suspend |
| `SUPER + Ctrl + Shift + Escape` | Monitors off (DPMS, 1s delay) |
| `SUPER + C` | Color picker (hyprpicker) |
| `SUPER + Shift + C` | Window inspector (hyprprop) |
| `SUPER + I` | System info (hyprsysteminfo) |
| `SUPER + Shift + I` | System info (detailed panel) |
| `SUPER + Z` | Freeze/unfreeze window (hyprfreeze) |
| `SUPER + N` | Blue light filter cycle (8 levels: 5500K → 1000K, then off) |
| `SUPER + Shift + N` | Blue light off |
| `SUPER + M` | Battery charge mode (Conservation → Balanced → Full) |
| `SUPER + Shift + M` | Performance mode cycle |
| `SUPER + Shift + T` | Toggle touchpad |
| `SUPER + F2` | WiFi reconnect |
| `SUPER + Shift + F2` | WiFi scan & connect |
| `SUPER + Ctrl + F2` | Toggle WiFi |
| `SUPER + F3` | Switch keyboard layout (fr/us) |
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
| `Ctrl+Alt+Enter` | Split up |
| `Ctrl+Alt+\` | Split left |
| `Ctrl+Shift+H/J/K/L` | Navigate splits |
| `Ctrl+Alt+H/J/K/L` | Resize splits |
| `Ctrl+Shift+E` | Equalize splits |
| `Ctrl+Shift+C/V` | Copy/Paste |
| `Ctrl+Shift+=/-/0` | Font size +/-/reset |
| `Ctrl+Shift+1-5` | Go to tab 1-5 |
| Mouse select | Auto-copy to clipboard |

---

### Shell (Zsh) Aliases

**NixOS**
| Alias | Command |
|-------|---------|
| `rebuild` | `cd "$(dotfiles-flake-dir)" && nh os switch .` |
| `update` | `nix flake update && update-overlays && nh os switch .` |
| `update-apps` | `update-overlays`, then `nh os switch .` when something changed |
| `clean` | `nh clean all --keep 5` |
| `secrets` | `sops "$(dotfiles-flake-dir)/sops/api-keys.yaml"` |
| `nb` | `cd "$(dotfiles-flake-dir)" && nh os boot .` |
| `ntest` | `cd "$(dotfiles-flake-dir)" && nh os test .` |
| `ndiff` | `cd "$(dotfiles-flake-dir)" && nh os build .` |

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
| `ai`, `ai-coder`, `ai-minimax` | Hermes local/cloud chat profiles |
| `kali-ai`, `kali-ai-coder`, `kali-ai-minimax` | Hermes profiles with Kali red-team system prompt |
| `gcp-me/work/who/list/login` | Google Cloud account helpers |

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
| `llm ocr <image>` | OCR an image with GLM-OCR |
| `llm ocr <image> "Table Recognition:"` | OCR a table |
| `llm ocr <image> "Formula Recognition:"` | OCR a formula |
| `llm list` | List available models |
| `llm-switch` | Show active model |
| `llm-switch opus` | Switch to Qwopus3.5-9B v3 (5.6GB, reasoning) |
| `llm-switch 9b` | Switch to Qwen3.5-9B Uncensored (5.6GB) |
| `llm-switch ocr` | Switch to GLM-OCR 0.9B (vision, 1.4GB) |
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

Captive portal detection (hotel/airport WiFi) is automatic. Manual bypass: `captive-on` / `captive-off`.

---

## Waybar Modules

Status bar with 20+ modules including:
- **Bitcoin price** - Coinbase + CoinGecko + Mempool.space APIs
- **Wallet balance** - Privacy-focused zpub derivation (local, keys never leave machine)
- **Polymarket** - Prediction market data
- **Weather** - Weather widget
- **VPN status** - Current VPN connection
- **Audio switch** - Output device switching
- **Mic switch** - Microphone toggle
- **SystemD failed** - Failed services count
- **Nix updates** - Available update indicator
- **Monitor settings** - Hyprland monitor controls via `hyprmon`
- **Removable disks** - USB drive monitoring
- **Brightness sync** - DDC brightness sync for external monitors
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

## Malware Analysis Lab

3-VM lab with killswitch, nwfilter anti-exfiltration, and fake-internet routing (REMnux as gateway for FLARE-VM).

### VMs

| Profile | Role | Network default |
|---|---|---|
| `flare` | FLARE-VM (Win10 + Mandiant install.ps1) - Windows malware analysis | `lab-isolated` |
| `remnux` | REMnux (Ubuntu) - network/cross-platform analysis, INetSim fake internet | `lab-isolated` |
| `devwin` | Dev-Win (Tiny10/Win10) - legit compile/test | `default` (NAT) |

### Setup

| Command | Action |
|---|---|
| `analysis-vm setup` | Create lab networks + nwfilter (run once) |
| `analysis-vm install-remnux` | Guide + partial automation for REMnux install |
| `analysis-vm install-flare` | Step-by-step guide for FLARE-VM install |
| `analysis-vm install-devwin` | Guide for Dev-Win install |

### Per-VM commands

`analysis-vm <flare|remnux|devwin> <cmd>`:

| Command | Action |
|---|---|
| `start` | Start VM (auto-killswitch for flare/remnux) |
| `stop` | Graceful shutdown |
| `killswitch` | Force isolation (flare/remnux only) |
| `network-on` | Temporary NAT for updates (flare/remnux only) |
| `snapshot [name]` | Create snapshot |
| `restore [name]` | Restore + auto-killswitch if isolated VM |
| `snapshots` | List snapshot tree |
| `status` | VM state + network |
| `verify` | Check isolation (flare/remnux) |

### Paths
- `~/lab/samples/` - malware samples (shared into VMs via VirtioFS)
- `~/lab/isos/` - Windows/Ubuntu ISOs you download

### Networks

| Network | Forward | Purpose |
|---|---|---|
| `lab-isolated` | none + nwfilter `lab-block-all` | FLARE ↔ REMnux only, no LAN/WAN |
| `lab-nat` | NAT | Updates (switched temporarily) |
| `default` | NAT | Dev-Win only |

### Legacy
`malware-vm` is kept as an alias for `analysis-vm flare`.

---

## Security Tools

Installed tools (many Firejailed):

**Network:** nmap, tcpdump, ngrep, Wireshark, bettercap
**Wireless:** aircrack-ng, wifite2, reaver, pixiewps, kismet, mdk4, cowpatty, hcxtools, hcxdumptool
**Password:** hashcat (GPU via ROCm), john, hydra
**Web:** sqlmap, nikto, dirb
**Crypto:** CyberChef
**RE/Binary:** Ghidra, jadx
**Recon:** whois, dnsutils, testssl, sslscan
**Wordlists:** seclists, crunch

Aliases: `nmap-quick`, `nmap-full`, `nmap-vuln`, `wifite-auto`, `hashcat-gpu`, etc.

---

## Installed Services

| Service | Description |
|---------|-------------|
| **llama-cpp** | Local LLM (port 8080, OpenAI API compatible) |
| **dnscrypt-proxy** | Encrypted DNS (AdGuard, Mullvad, Quad9) |
| **TLP** | Power management (conservation: 55-60%) |
| **btrbk** | Btrfs snapshots every 15min, 7-day retention |
| **ananicy-cpp** | Process priority optimization (CachyOS rules) |
| **earlyoom** | OOM prevention (5% RAM threshold) |
| **Podman** | Container runtime (Docker compatible) |
| **libvirtd** | KVM/QEMU virtualization (swtpm for TPM2) |
| **BitBox Bridge** | Hardware wallet bridge |
| **Hermes Agent** | AI agent with profiles (local + cloud APIs) |
| **Steam** | Gaming with Proton GE + Gamescope |

---

## Overlays (Pinned Versions)

| Overlay | Package | Current Version |
|---------|---------|-----------------|
| vscode-latest.nix | VS Code | 1.117.0 |
| claude-code-latest.nix | Claude Code | 2.1.119 |
| llama-cpp-latest.nix | llama.cpp (ROCm + NATIVE) | b8947 |
| opencode-latest.nix | OpenCode (Bun SEA) | 1.14.28 |
| forgecode-latest.nix | ForgeCode (musl static) | 2.12.9 |
| codex-latest.nix | Codex (OpenAI, Rust musl) | 0.125.0 |
| runpodctl-latest.nix | RunPod CLI (Go) | 2.1.9 |
| pnpm-latest.nix | pnpm | 10.33.2 |

---

## Adapting to Different Hardware

### Portable (works anywhere)
- All `modules/home/` configs
- Web apps, themes, icons
- DNS and network settings

### Hardware-specific (needs changes)
- `hosts/thinkpad/hardware-configuration.nix` - Regenerate with `nixos-generate-config --no-filesystems`
- `hosts/thinkpad/disko-config.nix` - Check disk name (`lsblk`)
- `modules/system/amd-optimizations.nix` - AMD only, remove for Intel/NVIDIA
- `modules/system/boot.nix` - AMD GPU kernel params, remove `amdgpu.*` for other GPUs
- `modules/system/sound.nix` - WirePlumber rules use hardcoded PCI addresses
- `flake.nix` - nixos-hardware module is ThinkPad P14s Gen 5 specific
- `modules/home/programs/hyprland.nix` - Monitor layout

---

## Installation

See [INSTALLATION-GUIDE.md](../INSTALLATION-GUIDE.md) for detailed steps.

## License

Personal configuration - use at your own risk.
