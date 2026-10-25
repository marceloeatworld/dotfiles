# NixOS Configuration - ThinkPad P14s Gen 5 (AMD)

Personal NixOS configuration with Hyprland and themeable UI.

## System Info

- **Hostname:** pop
- **Hardware:** Lenovo ThinkPad P14s Gen 5
- **CPU:** AMD Ryzen 7 PRO 8840HS (Zen 4)
- **GPU:** Radeon 780M (RDNA 3)
- **RAM:** 32GB (27GiB usable after the iGPU carveout) + zram (zstd, 75% / 20GB)
- **Storage:** 1TB NVMe (LUKS + Btrfs, 7 subvolumes)
- **Kernel:** `linuxPackages_latest` (currently 7.2.x)
- **NixOS:** `nixos-unstable` (currently 26.11.20260904)
- **State versions:** NixOS/Home Manager 25.05
- **WM:** Hyprland (Wayland) via UWSM
- **Terminal:** Ghostty + Alacritty (backup)
- **Launcher:** Wofi (drun); hyprlauncher installed but its daemon is disabled
- **Theme:** 7 themes (Ristretto default, Neobrutalist, Neobrutalist Light, Nord, Tokyo Night, Catppuccin, Paper)

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
├── flake.nix                 # Main flake (nixos-unstable / 26.11 snapshot + 10 overlays)
├── flake.lock                # Locked inputs (current system: 26.11.20260904)
├── overlays/                 # Custom package overlays (10)
│   ├── vscode-latest.nix     # VS Code from Microsoft CDN
│   ├── claude-code-latest.nix # Claude Code from npm
│   ├── llama-cpp-latest.nix  # llama.cpp with ROCm + native CPU opts
│   ├── opencode-latest.nix   # OpenCode from GitHub releases (Bun SEA)
│   ├── forgecode-latest.nix  # ForgeCode from GitHub (musl static)
│   ├── codex-latest.nix      # Codex from GitHub releases (OpenAI, Rust musl)
│   ├── runpodctl-latest.nix  # RunPod CLI from GitHub (Go)
│   ├── arkcli-latest.nix     # BytePlus Ark CLI from GitHub (Go)
│   ├── pnpm-latest.nix       # pnpm npm tarball wrapped on system Node 22 (v10.x pin)
│   ├── waybar-latest.nix     # Waybar master pin for Hyprland Lua IPC fix
│   └── yaru-theme.nix        # Yaru GTK/icon theme (dropped from nixpkgs 2026-07)
├── assets/icons/             # Local webapp icons
├── hosts/thinkpad/
│   ├── configuration.nix     # System config (hostname, packages, nix settings)
│   ├── hardware-configuration.nix
│   └── disko-config.nix      # LUKS + Btrfs (7 subvolumes)
└── modules/
    ├── system/               # System modules
    │   ├── boot.nix          # systemd-boot, latest kernel, AMD boot params
    │   ├── networking.nix    # NetworkManager, dnscrypt-proxy2, Bluetooth
    │   ├── hyprland.nix      # Hyprland system config, XDG portal, suspend/resume fix
    │   ├── sound.nix         # PipeWire (low-latency), WirePlumber rules
    │   ├── locale.nix        # en_US.UTF-8, Europe/Lisbon, French keyboard
    │   ├── users.nix         # User marcelo, groups, zsh
    │   ├── security.nix      # Firejail (17 apps), AppArmor, GnuPG, sudo rules
    │   ├── security-tools.nix # nmap, aircrack-ng, hashcat, wireshark, etc.
    │   ├── services.nix      # TLP, CUPS, Avahi, BitBox Bridge, desktop services
    │   ├── llama-cpp.nix     # On-demand local LLM/OCR services and llm-switch
    │   ├── virtualisation.nix # Podman (Docker compat), libvirtd/QEMU, AppImage, KVM nested
    │   ├── btrfs.nix         # btrbk snapshots (hourly), monthly scrub
    │   ├── amd-optimizations.nix # AMD P-State, RADV, ROCm, NVMe scheduler, GPU overdrive
    │   ├── fonts.nix         # System fonts (Inter, Liberation, Nerd Fonts)
    │   ├── vpn-dns-switch.nix # Auto DNS switching (dnscrypt ↔ VPN DNS) + captive portal
    │   ├── ddcutil.nix       # DDC/CI for external monitor brightness
    │   ├── sunxi-fel.nix     # Allwinner FEL USB access (PocketCHIP)
    │   ├── smartcard.nix     # pcscd for the Cartao de Cidadao reader
    │   ├── scanner.nix       # SANE + scan-doc/scan-photo (Canon LiDE 400)
    │   ├── performance.nix   # zram, ananicy-cpp, earlyoom, GameMode, sysctl tuning
    │   └── nh.nix            # NH (Nix Helper) config
    └── home/                 # Home Manager modules
        ├── home.nix          # Root config, imports the modules below + sops-nix
        ├── programs/         # Program modules
        │   ├── hyprland/     # Lua WM config split into monitors, keybinds, rules, scripts, etc.
        │   ├── terminal.nix  # Ghostty + Alacritty
        │   ├── shell.nix     # Zsh, Starship, aliases
        │   ├── overlay-updates.nix # update-* overlay helper functions
        │   ├── keys.nix      # Terminal keybindings cheatsheet (`keys`)
        │   ├── wofi.nix      # Wofi launcher / dmenu picker
        │   ├── git.nix       # Git + delta + lazygit
        │   ├── nvim.nix      # Neovim (50+ plugins, LSP, Copilot)
        │   ├── development.nix # C++, Node, Python, Go, Rust, .NET
        │   ├── vscode.nix    # VS Code package, wrapper and UI settings
        │   ├── claude-code.nix # Claude Code AI assistant config
        │   ├── ai-skills.nix  # AI agent skills (synced from upstream) & slash commands
        │   ├── opencode.nix  # OpenCode AI coding agent config
        │   ├── forgecode.nix # ForgeCode AI coding harness (Rust, ZSH)
        │   ├── codex.nix     # Codex AI coding agent (OpenAI, Rust musl static)
        │   ├── kali-redteam.nix # Kali Linux headless container (Podman)
        │   ├── vpn.nix       # VPN manager (country-code WireGuard switching)
        │   ├── webapps.nix   # Brave web apps (YouTube, Twitch, ChatGPT, GitHub, Claude, Proton)
        │   ├── geforce-now.nix # GeForce NOW cloud gaming (dedicated Chromium)
        │   ├── autenticacao-gov.nix # Cartao de Cidadao auth (jailed plugin + Brave window)
        │   ├── xfeed/        # Removable X timeline panel (Super+R)
        │   ├── jailed-agents.nix # Opt-in sandboxed AI agent wrappers (jail.nix)
        │   ├── desktop-apps.nix # Desktop entries
        │   ├── media.nix     # Media tools (swayimg, PhotoGIMP, Flowblade)
        │   ├── nemo.nix      # Nemo file manager + 19 custom actions
        │   ├── hyprlauncher.nix # App launcher config
        │   ├── btop.nix      # System monitor
        │   ├── fastfetch.nix # System info
        │   ├── analysis-vm.nix # Malware analysis lab: FLARE-VM + REMnux + Dev-Win
        │   ├── security-packages.nix # Security tool aliases
        │   ├── radio-sdr.nix # SDR tools (SDR++, rtl-sdr, SoapySDR)
        │   ├── xournalpp.nix # PDF annotation
        │   ├── zathura.nix   # PDF viewer
        │   ├── yt-dlp.nix    # YouTube downloader
        │   └── uwsm.nix      # Wayland session manager
        ├── services/
        │   ├── waybar.nix    # Status bar + scripted custom modules
        │   ├── mako.nix      # Notifications
        │   ├── hyprlock.nix  # Screen locker + hypridle
        │   ├── swayosd.nix   # Volume/brightness OSD
        │   └── mic-jack-autoswitch.nix # Mic auto-switch on jack plug/unplug
        └── config/
            ├── theme.nix     # 7 themes (colors + fonts, read from current-theme)
            ├── runtime-theme.nix # Runtime day/night theme switcher (no rebuild)
            ├── bat.nix       # Bat (cat replacement) + themed tmTheme
            ├── secrets.nix   # sops-nix API keys decryption
            ├── gtk.nix       # Yaru GTK/icon variant per theme, Bibata cursor
            ├── qt.nix        # Kvantum (per-theme generated variant)
            ├── fontconfig.nix # Font fallbacks
            ├── webapp-icons.nix # Custom webapp icons
            ├── hyprpaper.nix # Wallpaper
            └── mimeapps.nix  # File associations
```

## Features

- **Hyprland 0.55+** - Tiling Wayland compositor via UWSM, Lua config, official Hyprland flake, and Mesa matched to the Hyprland input
- **Hypr Ecosystem** - hyprlock, hypridle, hyprpaper, hyprlauncher, hyprsunset, hyprpicker, hyprpwcenter, hyprsysteminfo, wl-freeze, grimblast, hyprshutdown, hyprprop, hyprmon, hyprcursor
- **7 Themes** - Switch with `theme-selector` (Ristretto, Neobrutalist, Neobrutalist Light, Nord, Tokyo Night, Catppuccin, Paper)
- **Ferdium** - Multi-account messaging workspace for WhatsApp and WhatsApp Business in one window
- **Firejail** - 17 wrapped apps plus dedicated Brave/Brave-HW profiles (Wireshark, KeePassXC, LibreOffice, Ghidra, etc.)
- **jail.nix** - Opt-in `jailed-*` sandbox wrappers for the AI coding agents
- **AppArmor** - Mandatory access control enabled
- **Ghostty** - GPU-accelerated terminal with splits and tabs
- **Bitcoin Wallet Monitor** - Privacy-focused zpub derivation, Waybar integration
- **DNS Privacy** - AdGuard + Mullvad via dnscrypt-proxy (DNSSEC)
- **VPN Integration** - Auto DNS switching (dnscrypt ↔ Proton VPN WireGuard) + captive portal detection
- **Local LLM** - llama.cpp with ROCm (Qwythos 9B, Gemma 4 12B Coder, Qwopus3.6 27B Coder, Devstral Small, plus GLM-OCR vision), started on demand with `llm local`
- **AI Agents** - Claude Code, ForgeCode, OpenCode, Codex
- **Kali Red Team Container** - Podman-managed Kali container (rootless, persistent storage)
- **Malware Analysis Lab** - 3 VMs (FLARE-VM + REMnux + Dev-Win) with killswitch, fake-internet routing, VirtioFS sample sharing
- **SDR Radio** - SDR++, rtl-sdr, SoapySDR
- **Security Toolkit** - nmap, aircrack-ng, hashcat, Wireshark, sqlmap, Ghidra, etc.
- **Performance** - zram 75%, ananicy-cpp (CachyOS rules), earlyoom, GameMode, app memory slices, latest kernel
- **Btrfs Snapshots** - Hourly (btrbk), 24 hourly + 3 daily retained
- **TLP Power** - Battery conservation mode (55-60% default), CPU boost off on battery
- **GameMode** - Game optimizations (renice, platform profile) + Gamescope micro-compositor

## Keybindings

`keys` in a terminal and `SUPER + F1` show the maintained list, generated from
`modules/home/programs/hyprland/keymap.nix`. The tables below are a summary.

### Hyprland (Window Manager)

**Applications**
| Key | Action |
|-----|--------|
| `SUPER + Return` | Ghostty terminal |
| `SUPER + B` | Brave browser |
| `SUPER + E` | Nemo file manager |
| `SUPER + A` | Audio control (hyprpwcenter) |
| `SUPER + D` | Launcher (Vicinae: apps, calculator, emoji, windows, files) |
| `SUPER + V` | Clipboard history (Vicinae, with image thumbnails) |
| `SUPER + Shift + V` | Clear clipboard |
| `SUPER + Y` | YouTube PiP toggle (launch/show/hide) |
| `SUPER + U` | Twitch PiP toggle (launch/show/hide) |
| `SUPER + R` | XFeed panel toggle (show/hide) |
| `SUPER + O` | Quick notes (floating nvim) |
| `SUPER + X` | Malware analysis lab menu |
| `SUPER + F1` | Keybindings cheatsheet |
| `Copilot key` | Voice: press once, speak, it stops on silence. Gemini transcribes (FR/PT/EN auto) and Flash-Lite decides: an instruction runs from a fixed action allowlist (apps, windows, workspaces, media, volume, screenshots, lock, theme, read-only terminal commands), anything else is typed into the focused window |

**Copilot key trick** (between AltGr and right Ctrl): the firmware sends a hardwired
chord (`LShift down, LMeta down, F23 down/up`, then releases), not a single scancode.
Hyprland matches binds against unmodified level-1 keysyms only, so keysym binds
(`XF86Assistant`, `XF86TouchpadOff`) never fire. The only binding that works is by
keycode: `hl.bind("SUPER + SHIFT + code:201", ...)` (keycode 201 = KEY_F23), see
`modules/home/programs/hyprland/keybinds.nix`. Verified 2026-07-14 with temporary
`hyprctl eval` marker binds. To test a bind candidate without risk, register it at
runtime (`hyprctl eval 'hl.bind(...)'` touching a marker file), press the physical
key, then remove it with `hl.unbind` - never simulate the chord with wtype.

**Window Management**
| Key | Action |
|-----|--------|
| `SUPER + Q` | Close window |
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
| `SUPER + Shift + P` | Toggle laptop screen (eDP-1) |
| `SUPER + Scroll` | Cycle existing workspaces |
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
| `SUPER + Print` | Region → annotate in satty → file + clipboard |
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
| `SUPER + Z` | Freeze/unfreeze window (wl-freeze) |
| `SUPER + N` | Blue light filter cycle (8 levels: 5500K → 1000K, then off) |
| `SUPER + Shift + N` | Blue light off |
| `SUPER + M` | Battery charge mode (Conservation ↔ Full) |
| `SUPER + Shift + M` | Performance mode cycle |
| `SUPER + Shift + T` | Toggle touchpad |
| `SUPER + F2` | WiFi reconnect |
| `SUPER + Shift + F2` | WiFi scan & connect |
| `SUPER + Ctrl + F2` | Toggle WiFi |
| `SUPER + F3` | Switch keyboard layout (fr/us) |
| `SUPER + Shift + R` | Restart Waybar |
| `SUPER + Shift + D` | Do Not Disturb toggle (critical alerts still show) |
| `SUPER + Ctrl + D` | Do Not Disturb for 60 minutes |
| `SUPER + ALT + R` | Resize mode: H/J/K/L or arrows, Esc exits |
| `SUPER + ALT + T` | Jump to window by tag: B browser, C code, T terminal, M messaging, V media, A creative, D documents, S security, G gaming |

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
| `Ctrl+Shift+1-9` | Go to tab 1-9 |
| Mouse select | Auto-copy to clipboard |

---

### Shell (Zsh) Aliases

**NixOS**
| Alias | Command |
|-------|---------|
| `rebuild` | `cd "$(dotfiles-flake-dir)" && nh os switch .` |
| `update` | selective `nix flake update` (skips the Hyprland stack + nixpkgs-llama), `update-overlays`, `nix flake check`, then `nh os switch .` |
| `update-hyprland` | update hyprland/hyprshutdown inputs, then `nh os switch .` (run deliberately, e.g. weekly) |
| `update-apps` | `update-overlays`, then `nh os switch .` when something changed |
| `clean` | `nh clean all --keep 3` |
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
| `update-arkcli` | Check/update BytePlus Ark CLI from GitHub (Go) |
| `update-pnpm` | Check/update pnpm (npm tarball, v10.x only) |
| `update-skills` | Update all agent skill repos |
| `update-llama` | Check/update llama.cpp from GitHub releases (separate, long build) |
| `update-overlays` | Update quick overlays + agent skills (`update-llama` and Waybar are manual pins) |

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
| `llm qwythos` | Chat with Qwythos 9B Claude Mythos |
| `llm gemma` | Chat with Gemma 4 12B Coder |
| `llm qwopus` | Chat with Qwopus3.6 27B Coder MTP |
| `llm devstral` | Chat with Devstral Small 2507 |
| `llm ocr <image>` | OCR an image with GLM-OCR |
| `llm ocr <image> "Table Recognition:"` | OCR a table |
| `llm ocr <image> "Formula Recognition:"` | OCR a formula |
| `llm list` | List available models |
| `llm local` | Start the active llama.cpp API service on demand |
| `llm-switch` | Show active model |
| `llm-switch qwythos` | Switch to Qwythos 9B Claude Mythos |
| `llm-switch gemma` | Switch to Gemma 4 12B Coder |
| `llm-switch qwopus` | Switch to Qwopus3.6 27B Coder MTP |
| `llm-switch devstral` | Switch to Devstral Small 2507 |
| `llm-switch ocr` | Switch to GLM-OCR 0.9B (vision, 1.4GB) |
| `llm-switch stop` | Stop LLM service |

---

### Claude Code (Slash Commands)

**Planning & Workflow**
| Command | Action |
|---------|--------|
| `/plan` | Create implementation plan (waits for confirmation before coding) |
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

**Skills (synced from upstream repos by `ai-skills.nix`, refreshed with `update-skills`)**

Each repo is narrowed to a named list so only the skills actually used land in the agent prompt.

| Source | Skills kept |
|--------|-------------|
| `marceloeatworld/hyprland-ai-skill` | `hyprland` |
| `marceloeatworld/nixos-ai-skill` | `nixos` |
| `google-labs-code/design.md` | `design-md` |
| `google/skills` | `gcloud`, `gemini-api` (Vertex / Agent Platform) |
| `google-gemini/gemini-skills` | `gemini-api-dev`, `gemini-live-api-dev` (Gemini Developer API) |
| `cloudflare/skills` | `agents-sdk`, `cloudflare`, `cloudflare-email-service`, `durable-objects`, `sandbox-sdk`, `workers-best-practices`, `wrangler` |
| `cloudflare/security-audit-skill` | `security-audit` |
| `neondatabase/agent-skills` | `neon`, `neon-postgres`, `neon-postgres-branches` |
| `timescale/pg-aiguide` | `postgres` |
| `runpod/skills` | `runpod`, `runpodctl` |
| `byteplus-sdk/ark-cli` | `arkcli-shared`, `arkcli-auth`, `arkcli-config`, `arkcli-doctor`, `arkcli-docs`, `arkcli-models`, `arkcli-pricing`, `arkcli-gen`, `arkcli-api-explorer` |
| `fal-ai-community/skills` | `genmedia`, `genmedia-workflow`, `model-routing`, `fal-models-catalog`, `fal-prompting`, `fal-recipes`, `fal-workflow` |
| `vercel-labs/agent-skills` | `composition-patterns`, `react-best-practices`, `react-native-skills`, `react-view-transitions`, `vercel-cli-with-tokens` |
| `JuliusBrussee/caveman` | `caveman` (always on, imported by the global `CLAUDE.md`) |
| local `modules/home/programs/skills/` | `i-have-adhd` (vendored copy of `nulltea/skills`; always on, imported by the global `CLAUDE.md`) |
| `hoainho/img2threejs` | `img2threejs` |
| `mdpsec/bug-bounty-hunting-prompts` | `bug-bounty-hunting` wrapper with adaptation guide and phase prompts (pinned) |
| `Illyism/seo-skills` | `seo` router with autopilot, title optimization, blog refresher and diff marketing references, plus the local parasite-seo workflow (pinned; vendor skills omitted) |
| `rehan-remade/universal-modder` | `mod-any-game`, `game-recon`, `reverse-engineering`, `fal-assets`, `asset-pipeline`, `game-automation`, `showcase-video`, `mashup-mods`, `publish-mod`, `share-field-notes`, `game-research-websearch`, `port-a-mod` (pinned with `um`) |
| `morluto/rea` | `reverse-engineer-anything` (pinned with `rea`) |

The new pinned sources update through their `rev` and `hash` in Nix, rather than
`update-skills`. Run `rebuild` to install the packages and distribute the skills
to Claude, Codex, ForgeCode and OpenCode; restart the agent to load them.

- **[Universal Modder](https://github.com/rehan-remade/universal-modder):** `um --help`.
  The packaged knowledge snapshot is available offline via `um kb search`/`show`;
  pass `--root` to use another corpus. Write contributions in a writable workspace.
  `um win` requires Windows/WSL; 3D rendering needs Blender, and fal generation
  needs `FAL_KEY`. See each installed skill's `NIXOS.md` for local paths.
- **[SigLens](https://github.com/St0rn/SigLens):** `siglens --help`.
  Linux static analysis is packaged; AMSI, Defender and DbgHelp require Windows.
  Rules and upstream engine examples are under `~/.local/share/siglens/`.
  Reports are written into `./reports`; the Windows engine examples need adapting
  before use with a Linux scanner. Packaging excludes one stale upstream test
  for the unused `fixed_windows` helper (bytes versus KiB); the other tests run.
- **[REA](https://github.com/morluto/rea):** `rea --help` and `rea doctor --json`.
  Claude gets a separate `rea` MCP server. REA 6.8.0 requires exactly Ghidra 12.1.4
  and JDK 21 for its Ghidra provider; the GUI Ghidra stays on nixpkgs. Hopper
  is not installed. Manage installation and agent registration with
  Nix rather than REA's upstream setup scripts.
- **[Bug-bounty prompts](https://github.com/mdpsec/bug-bounty-hunting-prompts):**
  use the `bug-bounty-hunting` skill. These are phase templates; read
  `ADAPTATION.md` and supply the target scope and integrations before using them.

---

### Neovim (LazyVim-style)

**Leader Key:** `Space` | **Local Leader:** `\`

**Essential**
| Key | Action |
|-----|--------|
| `i` | Insert mode |
| `jk` / `Esc` | Back to Normal mode |
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

**LSP Servers:** nil (Nix), lua_ls, pyright, rust_analyzer, gopls, clangd, yamlls, marksman, html/css/json, bashls (ts_ls opt-in via `vts`)

**AI:** GitHub Copilot (auto-trigger, Tab to accept)

---

## DNS Configuration

| Provider | Features |
|----------|----------|
| **AdGuard** | Ads + trackers + malware blocking |
| **Mullvad** | Ads + trackers (public blocklist configuration) |

Both encrypted (DNSCrypt / DoH) with DNSSEC required.

**Automatic VPN DNS switching:**
| Status | DNS | dnscrypt-proxy |
|--------|-----|----------------|
| VPN OFF | AdGuard/Mullvad | Active |
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
| **llama-cpp / llama-cpp-ocr** | Local LLM/OCR API units, available but not started at boot |
| **dnscrypt-proxy** | Encrypted DNS (AdGuard, Mullvad) |
| **TLP** | Power management (conservation: 55-60%) |
| **btrbk** | Btrfs snapshots hourly, 24 hourly + 3 daily retained |
| **ananicy-cpp** | Process priority optimization (CachyOS rules) |
| **earlyoom** | OOM prevention (5% RAM and 50% zram free thresholds) |
| **Podman** | Container runtime (Docker compatible) |
| **libvirtd** | KVM/QEMU virtualization (swtpm for TPM2) |
| **BitBox Bridge** | Hardware wallet bridge |

---

## Overlays (Pinned Versions)

| Overlay | Package | Current Version |
|---------|---------|-----------------|
| vscode-latest.nix | VS Code | 1.136.1 |
| claude-code-latest.nix | Claude Code | 2.1.261 |
| llama-cpp-latest.nix | llama.cpp (ROCm + NATIVE) | b10819 |
| opencode-latest.nix | OpenCode (Bun SEA) | 1.18.29 |
| forgecode-latest.nix | ForgeCode (musl static) | 2.13.21 |
| codex-latest.nix | Codex (OpenAI, Rust musl) | 0.153.4 |
| runpodctl-latest.nix | RunPod CLI (Go) | 2.12.0 |
| arkcli-latest.nix | BytePlus Ark CLI (Go) | 1.0.37 |
| pnpm-latest.nix | pnpm | 10.34.5 |
| waybar-latest.nix | Waybar | 0.15.0-unstable-98b2a56 |
| yaru-theme.nix | Yaru | 25.10.3 |

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
- `modules/home/programs/hyprland/monitors.nix` - Monitor layout

---

## Installation

See [INSTALLATION-GUIDE.md](../INSTALLATION-GUIDE.md) for detailed steps.

## License

Personal configuration - use at your own risk.
