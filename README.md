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
├── assets/icons/             # Local webapp icons (no internet download)
├── hosts/thinkpad/
│   ├── configuration.nix     # System configuration
│   ├── hardware-configuration.nix
│   └── disko-config.nix      # Disk partitioning (LUKS + Btrfs)
└── modules/
    ├── system/               # System-level configs
    │   ├── boot.nix
    │   ├── networking.nix    # DNS: AdGuard + Mullvad + Quad9
    │   ├── hyprland.nix
    │   ├── services.nix      # TLP, Ollama, CUPS, etc.
    │   ├── amd-optimizations.nix
    │   ├── vpn-dns-switch.nix # Automatic VPN DNS switching
    │   └── ...
    └── home/                 # Home Manager configs
        ├── home.nix
        ├── programs/         # App configs (Kitty, Walker, Windows VM, etc.)
        ├── services/         # Waybar, Mako, SwayOSD
        └── config/           # GTK, Qt, fonts, icons
```

## Features

- **Hyprland** - Tiling Wayland compositor with Ristretto theme
- **Walker** - Modern application launcher
- **Kitty** - GPU-accelerated terminal
- **DNS Privacy** - AdGuard + Mullvad + Quad9 (ad-blocking, malware blocking, encrypted)
- **VPN Integration** - Automatic DNS switching (Quad9 ↔ Proton VPN)
- **Windows 11 VM** - Docker-based with RDP integration
- **Ollama** - Local LLM with AMD GPU acceleration (ROCm)
- **TLP** - Advanced power management (75-80% battery threshold)
- **Btrfs** - Compression, snapshots, monthly scrub
- **Docker + VMware** - Containerization and virtualization
- **Local Icons** - All webapp icons stored in repo (offline install)

## Keybindings

### Hyprland (Window Manager)

**Applications**
| Key | Action |
|-----|--------|
| `SUPER + D` | Walker launcher (Ristretto themed) |
| `SUPER + Return` | Kitty terminal |
| `SUPER + B` | Brave browser |
| `SUPER + E` | Nemo file manager |
| `SUPER + V` | Clipboard history (cliphist) |

**Window Management**
| Key | Action |
|-----|--------|
| `SUPER + Q` | Kill active window |
| `SUPER + F` | Fullscreen toggle |
| `SUPER + Space` | Toggle floating |
| `SUPER + Left/Right/Up/Down` | Move focus |
| `SUPER + Shift + Left/Right/Up/Down` | Move window |
| `SUPER + 1-9, 0` | Switch to workspace |
| `SUPER + Shift + 1-9, 0` | Move window to workspace |

**System Utilities**
| Key | Action |
|-----|--------|
| `SUPER + Escape` | Lock screen (Swaylock) |
| `SUPER + C` | Color picker (Hyprpicker) |
| `SUPER + N` | Blue light filter toggle (8 levels: Off → 5500K → 4500K → 3500K → 2500K → 2000K → 1500K → 1200K) |
| `SUPER + M` | Battery charge mode (Conservation 55-60% → Balanced 75-80% → Full 95-100%) |
| `SUPER + Shift + V` | Clear clipboard history |

**Screenshots**
| Key | Action |
|-----|--------|
| `Print` | Screenshot selection → clipboard |
| `SUPER + Print` | Screenshot selection → file (~/Pictures/Screenshots/) |
| `Shift + Print` | Screenshot full screen → clipboard |
| `SUPER + Shift + Print` | Screenshot full screen → file |

**Media Keys**
| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume up (+5%, notification) |
| `XF86AudioLowerVolume` | Volume down (-5%, notification) |
| `XF86AudioMute` | Mute/Unmute toggle |
| `XF86AudioMicMute` | Microphone mute toggle |
| `XF86MonBrightnessUp` | Brightness up (+5%, notification) |
| `XF86MonBrightnessDown` | Brightness down (-5%, notification) |

**Additional Window Controls**
| Key | Action |
|-----|--------|
| `SUPER + H/J/K/L` | Vim-style focus (left/down/up/right) |
| `SUPER + Shift + H/J/K/L` | Vim-style move window |
| `SUPER + Ctrl + H/J/K/L` | Vim-style resize (-40/+40) |
| `SUPER + Ctrl + Left/Right/Up/Down` | Resize window (-40/+40) |
| `SUPER + P` | Pseudo-tile (dwindle) |
| `SUPER + T` | Toggle split direction |

**Advanced Window Management**
| Key | Action |
|-----|--------|
| `SUPER + S` | Toggle special workspace "magic" |
| `SUPER + Shift + S` | Move to special workspace |
| `SUPER + Shift + F` | Fullscreen (keep bars visible) |

**Mouse Bindings**
| Key | Action |
|-----|--------|
| `SUPER + Left Click Drag` | Move window |
| `SUPER + Right Click Drag` | Resize window |
| `Left Click (URL)` | Open URL in browser |
| `Middle Click` | Paste from selection |
| `Right Click` | Extend selection |

**Power Management**
| Key | Action |
|-----|--------|
| `SUPER + Shift + Escape` | **Power off** system |
| `SUPER + Ctrl + Escape` | **Reboot** system |
| `SUPER + Shift + R` | **Restart Waybar** |

---

### Kitty Terminal

**Copy/Paste**
| Key | Action |
|-----|--------|
| `Ctrl + Shift + C` | Copy to clipboard |
| `Ctrl + Shift + V` | Paste from clipboard |
| `Ctrl + Insert` | Copy to clipboard (alternative) |
| `Shift + Insert` | Paste from clipboard (alternative) |
| `Ctrl + Shift + S` | Copy to selection buffer |
| `Ctrl + Shift + A` | Select all |
| `Escape` | Clear selection |
| **Mouse Selection** | **Auto-copy** to clipboard (enabled) |

**Scrollback Navigation**
| Key | Action |
|-----|--------|
| `Ctrl + Shift + Up/Down` | Scroll line up/down |
| `Ctrl + Shift + Page Up/Down` | Scroll page up/down |
| `Ctrl + Shift + Home/End` | Scroll to top/bottom |
| `Ctrl + Shift + H` | Show scrollback in pager (less) |

**Window Management**
| Key | Action |
|-----|--------|
| `Ctrl + Shift + Enter` | New window |
| `Ctrl + Shift + W` | Close window |
| `Ctrl + Shift + ]` | Next window |
| `Ctrl + Shift + [` | Previous window |

**Tab Management**
| Key | Action |
|-----|--------|
| `Ctrl + Shift + T` | New tab |
| `Ctrl + Shift + Q` | Close tab |
| `Ctrl + Shift + Right` | Next tab |
| `Ctrl + Shift + Left` | Previous tab |

**Font Size**
| Key | Action |
|-----|--------|
| `Ctrl + Shift + =` | Increase font size |
| `Ctrl + Shift + -` | Decrease font size |
| `Ctrl + Shift + 0` | Restore default font size |

**Mouse Actions**
- **Left Click (URL)**: Open URL in browser
- **Middle Click**: Paste from selection
- **Right Click**: Extend selection to command output
- **Ctrl + Alt + Drag**: Rectangle select mode
- **Shift + Click**: Select from cursor to click

---

### Shell (Zsh) - Command Aliases

**NixOS System**
| Alias | Command | Description |
|-------|---------|-------------|
| `rebuild` | `sudo nixos-rebuild switch --flake ...` | Rebuild and switch system |
| `update` | `nix flake update && rebuild` | Update flake inputs and rebuild |
| `clean` | `sudo nix-collect-garbage -d` | Clean old generations |

**File Listing (Modern Tools)**
| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza --icons` | List files with icons |
| `ll` | `eza -l --icons` | Long list with icons |
| `la` | `eza -la --icons` | All files, long list |
| `tree` | `eza --tree --icons` | Tree view with icons |
| `cat` | `bat` | Syntax-highlighted cat |

**Git Shortcuts**
| Alias | Command |
|-------|---------|
| `g` | `git` |
| `gs` | `git status` |
| `ga` | `git add` |
| `gc` | `git commit` |
| `gp` | `git push` |
| `gl` | `git pull` |
| `gd` | `git diff` |

**Editor & Navigation**
| Alias | Command |
|-------|---------|
| `v` | `nvim` |
| `vim` | `nvim` |
| `..` | `cd ..` |
| `...` | `cd ../..` |

---

### Neovim (LazyVim-style Configuration)

**Leader Key:** `Space`
**Local Leader:** `\`

#### File Navigation (Telescope)
| Key | Action |
|-----|--------|
| `Space f f` | **Find files** (fuzzy search) |
| `Space f g` | **Live grep** (search in files) |
| `Space f b` | **Buffers** list |
| `Space f r` | **Recent files** |
| `Space e` | **File explorer** (Neo-tree) |
| `-` | **Parent directory** (Oil.nvim) |

#### Search Operations
| Key | Action |
|-----|--------|
| `Space s g` | **Global grep** |
| `Space s r` | **Search & replace** (Spectre) |
| `Space s h` | **Help tags** |
| `/text` | Search "text" in file |
| `n` / `N` | Next/previous match |
| `Esc` | Clear search highlight |

#### Buffer Management
| Key | Action |
|-----|--------|
| `Space b d` | **Delete buffer** |
| `Space b n` | **Next buffer** |
| `Space b p` | **Previous buffer** |
| `Space f b` | **List buffers** (Telescope) |

#### Git Operations
| Key | Action |
|-----|--------|
| `Space g g` | **LazyGit** (TUI interface) |
| `Space g n` | **Neogit** (Magit-like interface) |
| `Space g d` | **Diff view** |
| `Space g h` | **File history** |
| `Space g b` | **Git branches** (Telescope) |
| `Space g c` | **Git commits** (Telescope) |

#### LSP (Code Intelligence)
| Key | Action |
|-----|--------|
| `Space c a` | **Code actions** |
| `Space c r` | **Rename symbol** |
| `Space c f` | **Format code** |
| `gd` | **Go to definition** |
| `gr` | **References** |
| `gi` | **Go to implementation** |
| `K` | **Hover documentation** |
| `Ctrl k` | **Signature help** |

#### Diagnostics
| Key | Action |
|-----|--------|
| `Space x x` | **Diagnostics list** (Trouble) |
| `Space x d` | **Line diagnostics** |
| `[d` / `]d` | Previous/next diagnostic |

#### Flash (Quick Navigation)
| Key | Action |
|-----|--------|
| `s` | **Flash jump** - jump anywhere in 2-3 keystrokes |
| `S` | **Flash Treesitter** - jump to code structure |

#### Harpoon (Favorite Files)
| Key | Action |
|-----|--------|
| `Space h a` | **Add file** to Harpoon |
| `Space h h` | **Toggle Harpoon menu** |
| `Space h 1-4` | Jump to favorite file 1-4 |

#### Window Management
| Key | Action |
|-----|--------|
| `Ctrl h/j/k/l` | Navigate windows (left/down/up/right) |
| `Ctrl Up/Down` | Resize window height |
| `Ctrl Left/Right` | Resize window width |

#### Code Folding (UFO)
| Key | Action |
|-----|--------|
| `zR` | **Open all folds** |
| `zM` | **Close all folds** |
| `za` | Toggle fold |
| `zo` | Open fold |
| `zc` | Close fold |

#### Editing Basics
| Key | Mode | Action |
|-----|------|--------|
| `i` | Normal | Enter **Insert mode** |
| `v` | Normal | Enter **Visual mode** |
| `V` | Normal | Enter **Visual Line mode** |
| `Esc` | Any | Return to **Normal mode** |
| `Space w` | Normal | **Save file** |
| `Space q` | Normal | **Quit** |
| `:w` | Normal | Save |
| `:q` | Normal | Quit |
| `:wq` | Normal | Save and quit |
| `:q!` | Normal | Quit without saving |

#### Auto-Completion (nvim-cmp + Copilot)
| Key | Mode | Action |
|-----|------|--------|
| `Ctrl Space` | Insert | **Trigger completion** |
| `Tab` | Insert | **Next item** / Accept Copilot suggestion |
| `Shift Tab` | Insert | **Previous item** |
| `Enter` | Insert | **Confirm selection** |
| `Ctrl e` | Insert | **Abort completion** |
| `Ctrl b/f` | Insert | Scroll docs up/down |

#### Visual Mode
| Key | Action |
|-----|--------|
| `p` | **Paste** without yanking (replaced text doesn't go to clipboard) |
| `gc` | **Comment** selection |
| `>` / `<` | Indent/unindent |

#### Commenting (Comment.nvim)
| Key | Mode | Action |
|-----|------|--------|
| `gc` | Normal/Visual | **Toggle comment** |
| `gcc` | Normal | Toggle line comment |
| `gbc` | Normal | Toggle block comment |

#### Mini.nvim Extras
| Feature | Usage |
|---------|-------|
| **mini.ai** | Better text objects (e.g., `diq` delete in quotes) |
| **mini.surround** | Surround operations (`sa`, `sd`, `sr`) |
| **mini.bufremove** | Smart buffer deletion |

#### Which-Key Help
- Press `Space` and **wait 300ms** → popup shows all available commands
- Press `Space f` and wait → shows all file commands
- Press `Space g` and wait → shows all git commands

#### Installed LSP Servers
- **Nix** - `nil_ls`
- **Lua** - `lua_ls`
- **Python** - `pyright`
- **Rust** - `rust_analyzer`
- **TypeScript/JavaScript** - `tsserver`
- **Go** - `gopls`
- **C/C++** - `clangd`
- **Bash** - `bash-language-server`
- **HTML/CSS/JSON** - `vscode-langservers-extracted`

#### AI Assistant
- **GitHub Copilot** enabled with auto-trigger
- Suggestions appear automatically while typing
- `Tab` to accept, `Ctrl e` to dismiss

---

### DNS Configuration

**European DNS servers with ad-blocking, malware blocking, and privacy**

| Provider | Location | Features |
|----------|----------|----------|
| **AdGuard** | 🇨🇾 Cyprus | Ads + trackers + malware blocking |
| **Mullvad** | 🇸🇪 Sweden | Aggressive ad-blocking |
| **Quad9** | 🇪🇺 Europe | Malware + phishing blocking (fallback) |

**Protection:**
- 🔒 **Encrypted DNS** - DNSCrypt + DoH protocols
- 🛡️ **Ad-blocking** - AdGuard + Mullvad
- 🛡️ **Malware blocking** - All servers
- 🛡️ **Tracker blocking** - AdGuard
- ✅ **DNSSEC** - Authentication enabled
- 🇪🇺 **EU-based** - All servers in Europe

**Automatic VPN DNS Switching:**
| Status | DNS Provider | dnscrypt-proxy2 |
|--------|-------------|-----------------|
| **VPN OFF** | AdGuard/Mullvad/Quad9 | ✅ Active |
| **VPN ON** | Proton VPN (10.2.0.1) | ❌ Stopped |

**Test DNS:**
```bash
# Check which DNS is active
resolvectl status

# Check ad-blocking (should be blocked)
dig ads.example.com

# View DNS switch logs
journalctl | grep VPN-DNS-SWITCH
```

---

### Web Applications & Desktop Apps

**Web Apps (PWAs via Brave)** - Launch from Walker

| App | URL | Icon | Category |
|-----|-----|------|----------|
| **WhatsApp** | web.whatsapp.com | whatsapp.png | Messaging |
| **YouTube** | youtube.com | youtube.png | Video |
| **ChatGPT** | chatgpt.com | chatgpt.png | AI Assistant |
| **Claude** | claude.ai | claude.png | AI Assistant |
| **GitHub** | github.com | github.png | Development |
| **Discord** | discord.com | discord.png | Chat & Voice |
| **Proton Mail** | mail.proton.me | protonmail | Email |
| **Proton Drive** | drive.proton.me | drive-harddisk | Cloud Storage |
| **Proton Pass** | pass.proton.me | dialog-password | Password Manager |

**Desktop Applications**

| App | Command | Description |
|-----|---------|-------------|
| **Windows 11 VM** | `windows-vm` | Docker-based Windows with RDP |
| **IMV Image Viewer** | `imv` | Fast Wayland image viewer |
| **Neovim** | `nvim-launcher` | Opens in new Kitty terminal |

---

## Windows 11 Virtual Machine

Docker-based Windows 11 VM with full RDP integration and shared folders.

### Quick Start

```bash
# First-time setup (interactive)
windows-vm install
```

**You'll be asked:**
- **RAM**: e.g., 8GB (system has 32GB)
- **CPU cores**: e.g., 4 cores (system has 16 threads)
- **Disk size**: e.g., 64GB (recommended)
- **Username**: e.g., your name (default: docker)
- **Password**: e.g., your password (default: admin)

**Installation process:**
1. Downloads Windows 11 image (~10-15 minutes)
2. Starts Docker container
3. Opens browser at http://127.0.0.1:8006 to monitor installation
4. Wait 10-20 minutes for Windows to install

### Daily Usage

```bash
# Launch and connect via RDP (auto-stops after disconnect)
windows-vm launch

# Keep VM running after disconnect
windows-vm launch -k

# Check status
windows-vm status

# Stop VM
windows-vm stop
```

**From Walker:** Press `SUPER + D`, search for "Windows 11", click to launch.

### Features

✅ **Auto-login** - Credentials saved, no manual login
✅ **Clipboard sync** - Copy/paste between Linux and Windows
✅ **Shared folder** - `~/Windows/` accessible from both systems
✅ **Audio & microphone** - Full sound support
✅ **Dynamic resolution** - Auto-resize when window changes
✅ **Hyprland scaling** - Detects monitor DPI automatically
✅ **Graphics acceleration** - AVC444 codec for smooth experience

### File Sharing

**Shared folder:** `~/Windows/`

```bash
# On Linux
cp ~/Documents/file.pdf ~/Windows/

# In Windows
# Open "This PC" → "Shared" → see your file
```

### Configuration

**Files:**
- Config: `~/.config/windows-vm/docker-compose.yml`
- Storage: `~/.windows-vm/` (Windows disk)
- Shared: `~/Windows/` (accessible from both systems)

**Change resources after install:**
```bash
# Edit config
nano ~/.config/windows-vm/docker-compose.yml

# Restart VM
windows-vm stop
windows-vm launch
```

**Web monitoring:** http://127.0.0.1:8006 (during installation)

All icons stored locally in `assets/icons/` (no internet download needed)

---

### Installed Tools & Services

**System Services**
- **TLP** - Advanced power management (battery thresholds: 75-80%)
- **Ollama** - Local LLM with AMD GPU acceleration (ROCm)
- **CUPS** - Printing support
- **Avahi** - mDNS/DNS-SD service discovery
- **Thermald** - CPU thermal management
- **Docker** - Container runtime
- **VMware Workstation Pro** - Virtualization
- **libvirtd/QEMU** - Virtualization

**Desktop Tools**
- **Walker** - Application launcher (Ristretto themed)
- **Waybar** - Status bar with custom modules (Bitcoin, Removable Disks)
- **Mako** - Notification daemon
- **SwayOSD** - On-screen display for volume/brightness
- **Hyprpaper** - Wallpaper manager
- **Hyprlock** - Screen locker
- **Hypridle** - Idle daemon
- **Hyprsunset** - Blue light filter (8 temperature levels)

**CLI Tools**
- **eza** - Modern `ls` replacement with icons
- **bat** - Syntax-highlighted `cat`
- **ripgrep** - Fast grep alternative
- **fd** - Fast find alternative
- **delta** - Git diff with syntax highlighting
- **lazygit** - Terminal UI for git
- **btop** - System monitor (Ristretto theme)
- **fastfetch** - System information display

**Development**
- **Neovim** - LazyVim-style config with 40+ plugins
- **VS Code** - Alternative editor
- **GitHub Copilot** - AI pair programming (in Neovim)
- **LSP Servers** - Nix, Lua, Python, Rust, TypeScript, Go, C/C++, Bash, HTML/CSS/JSON

**AI & LLM**
- **Ollama** - Local LLM server (`http://localhost:11434`)
- **aichat** - CLI chat interface
- **ROCm** - AMD GPU acceleration for AI workloads

---

## Installation

See [INSTALLATION-GUIDE.md](INSTALLATION-GUIDE.md) for detailed installation instructions.

## License

Personal configuration - use at your own risk.
