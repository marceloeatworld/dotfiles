# Package Comparison: Your NixOS vs Omarchy

## Overview

This document compares your current package selection with Omarchy's (Arch-based Hyprland distribution).

---

## Summary Statistics

| Category | Your Packages | Omarchy Packages | Status |
|----------|---------------|------------------|--------|
| **System Utilities** | 21 | 35 | ✅ Good coverage |
| **Development** | 25 | 28 | ✅ Good coverage |
| **Media** | 9 | 15 | ⚠️ Could add more |
| **Desktop/Wayland** | 12 | 18 | ✅ Good coverage |
| **Productivity** | 3 | 11 | ⚠️ Missing tools |
| **Total Unique** | ~70 | ~110 | 64% coverage |

---

## Category-by-Category Comparison

### 1. System Utilities & CLI Tools

#### ✅ You Already Have:
```nix
htop                 # System monitor
btop                 # Better system monitor
neofetch            # System info
fastfetch           # Faster system info
tree                # Directory tree
ripgrep             # Fast grep
fd                  # Fast find
eza                 # Modern ls (same as exa)
bat                 # Cat with syntax
fzf                 # Fuzzy finder
zoxide              # Smart cd
direnv              # Environment switcher
wget                # Download tool
curl                # HTTP client
speedtest-cli       # Network speed test
```

#### 🆕 Omarchy Has (Useful Additions):
```
dust                # Better du (disk usage)
tldr                # Simplified man pages
plocate             # Fast file locator
whois               # Domain lookup
inxi                # Detailed system info
less                # Pager (standard)
man                 # Manual pages
expac               # Pacman DB query (Arch-specific, skip)
```

#### 💡 Recommended to Add:
```nix
dust                # Visual disk usage (better than du)
tldr                # Quick command examples
plocate             # Fast file search (alternative to fd)
```

---

### 2. Development Tools

#### ✅ You Already Have:
```nix
git                 # Version control
git-lfs             # Large file storage
gh                  # GitHub CLI
python3             # Python
nodejs_22           # Node.js
go                  # Go language
rustup              # Rust toolchain
gcc                 # C compiler
gnumake             # Build tool
cmake               # Build system
docker-compose      # Container orchestration
kubectl             # Kubernetes CLI
kubernetes-helm     # K8s package manager
terraform           # Infrastructure as code
ansible             # Automation
nixpkgs-fmt         # Nix formatter
nil                 # Nix LSP
nix-tree            # Dependency viewer
nix-index           # Package search
vscode              # Code editor
```

#### 🆕 Omarchy Has:
```
cargo               # Rust package manager (included with rustup)
clang               # C compiler (alternative to gcc)
llvm                # Compiler infrastructure
luarocks            # Lua package manager
mise                # Runtime version manager
python-poetry-core  # Python dependency manager
lazydocker          # Docker TUI
lazygit             # Git TUI
gum                 # Glamorous shell scripts
jq                  # JSON processor
xmlstarlet          # XML processor
```

#### 💡 Recommended to Add:
```nix
lazydocker          # Better Docker management UI
lazygit             # Better Git UI
jq                  # JSON processing (essential!)
gum                 # Beautiful shell scripts
clang               # Alternative C/C++ compiler
```

---

### 3. Media & Graphics

#### ✅ You Already Have:
```nix
mpv                 # Video player
imv                 # Image viewer
spotify             # Music streaming
vlc                 # Media player
gimp                # Image editor (with PhotoGIMP)
inkscape            # Vector graphics
```

#### 🆕 Omarchy Has:
```
ffmpegthumbnailer   # Video thumbnails
gpu-screen-recorder # Screen recording (GPU accelerated)
imagemagick         # Image processing CLI
kdenlive            # Video editor
obs-studio          # Streaming/recording
satty               # Screenshot annotation
sushi               # File previewer (GNOME)
```

#### 💡 Recommended to Add:
```nix
imagemagick         # Powerful image manipulation
obs-studio          # Essential for streaming/recording
satty               # Annotate screenshots easily
```

---

### 4. Desktop Environment (Hyprland/Wayland)

#### ✅ You Already Have:
```nix
hyprland            # Window manager
hyprpaper           # Wallpaper daemon
hypridle            # Idle daemon
hyprlock            # Lock screen
hyprpicker          # Color picker
brightnessctl       # Brightness control
waybar              # Status bar
mako                # Notification daemon
swaylock            # Alternative lock
wl-clipboard        # Clipboard manager
grim                # Screenshot
slurp               # Area selector
wf-recorder         # Screen recorder
wofi                # App launcher
```

#### 🆕 Omarchy Has:
```
hyprland-qtutils    # Qt integration
hyprsunset          # Blue light filter
swaybg              # Background manager
swayosd             # On-screen display (volume/brightness)
wayfreeze           # Freeze screen for screenshots
uwsm                # Session manager (you have this system-wide)
walker              # App launcher (alternative to wofi)
xdg-desktop-portal-hyprland  # Desktop integration
xdg-desktop-portal-gtk       # GTK integration
plymouth            # Boot splash
```

#### 💡 Recommended to Add:
```nix
swayosd             # Beautiful OSD for volume/brightness
hyprsunset          # Blue light filter (like redshift)
wayfreeze           # Freeze screen for annotations
xdg-desktop-portal-hyprland  # Better file pickers
xdg-desktop-portal-gtk       # GTK app integration
```

---

### 5. Productivity & Office

#### ✅ You Already Have:
```nix
libreoffice-fresh   # Office suite
zathura             # PDF viewer
keepassxc           # Password manager
```

#### 🆕 Omarchy Has:
```
obsidian            # Note-taking (Markdown)
typora              # Markdown editor
signal-desktop      # Encrypted messaging
1password-beta      # Password manager (alternative)
1password-cli       # CLI for 1Password
gnome-calculator    # Calculator
gnome-disk-utility  # Disk management
gnome-keyring       # Credential storage
pinta               # Simple image editor
xournalpp           # PDF annotation
elephant-*          # Omarchy-specific suite
```

#### 💡 Recommended to Add:
```nix
obsidian            # Powerful note-taking
signal-desktop      # Secure messaging
gnome-calculator    # Quick calculations
xournalpp           # PDF annotation (great for documents)
```

---

### 6. File Management

#### ✅ You Already Have:
```nix
yazi                # Terminal file manager
nnn                 # Terminal file manager
ranger              # Terminal file manager
nemo                # GUI file manager (Cinnamon)
```

#### 🆕 Omarchy Has:
```
nautilus            # GNOME file manager
gvfs-mtp            # Android device support
gvfs-nfs            # Network file systems
gvfs-smb            # Windows shares
```

#### 💡 Recommended to Add:
```nix
gvfs                # Virtual file systems (includes mtp, nfs, smb)
```

**Why:** Android file transfer and network shares support

---

### 7. Network & Connectivity

#### ✅ You Already Have (System-level):
```
networkmanager      # Network management
bluez               # Bluetooth stack
```

#### 🆕 Omarchy Has:
```
avahi               # Local network discovery (mDNS)
nss-mdns            # Name resolution
iwd                 # Alternative WiFi daemon
wireplumber         # PipeWire session manager
localsend           # Local file sharing
```

#### 💡 Recommended to Add:
```nix
avahi               # Discover printers, devices on LAN
localsend           # Easy local file sharing
```

---

### 8. System Services & Printing

#### ✅ You Already Have (System-level):
```
cups                # Printing
brlaser             # Brother printer driver
```

#### 🆕 Omarchy Has:
```
cups (full suite)       # Printing
system-config-printer   # Printer GUI
power-profiles-daemon   # Power management
polkit-gnome            # Permission dialogs
```

#### 💡 Already Covered:
Your system-level configuration handles these.

---

### 9. Fonts

#### ✅ You Already Have:
```nix
jetbrains-mono      # JetBrains Mono Nerd Font
nerd-fonts          # Multiple Nerd Fonts
```

#### 🆕 Omarchy Has:
```
noto-fonts (multiple variants)
ttf-cascadia-mono-nerd
ttf-ia-writer
ttf-jetbrains-mono-nerd
woff2-font-awesome
```

#### 💡 Recommended to Add:
```nix
noto-fonts          # Google Noto (excellent coverage)
noto-fonts-cjk      # Chinese/Japanese/Korean
noto-fonts-emoji    # Emoji support
font-awesome        # Icon font
```

---

### 10. Input Methods (IME)

#### ⚠️ You Don't Have:
Nothing for non-Latin input

#### 🆕 Omarchy Has:
```
fcitx5              # Input method framework
fcitx5-gtk          # GTK integration
fcitx5-qt           # Qt integration
```

#### 💡 Skip Unless Needed:
Only add if you need Chinese, Japanese, Korean, or other non-Latin input.

---

### 11. Themes & Appearance

#### ✅ You Already Have:
```nix
catppuccin-* themes # GTK, Qt, everything
omarchy themes      # Hyprland themes
```

#### 🆕 Omarchy Has:
```
kvantum-qt5         # Qt theme engine
yaru-icon-theme     # Ubuntu icon theme
```

#### 💡 Optional:
```nix
kvantum             # For advanced Qt theming
papirus-icon-theme  # Popular icon theme
```

---

### 12. Archive Support

#### ✅ You Already Have:
```nix
unzip               # ZIP extraction
zip                 # ZIP creation
p7zip               # 7z support
unrar               # RAR extraction
```

#### ✅ Complete Coverage!

---

### 13. Terminal Emulators

#### ✅ You Already Have:
```nix
kitty               # GPU-accelerated terminal
```

#### 🆕 Omarchy Has:
```
alacritty           # Alternative GPU terminal
ghostty             # New terminal (not in nixpkgs yet)
```

#### 💡 Optional:
```nix
alacritty           # Alternative to kitty (lighter)
```

---

## Recommended Additions

### Priority 1: Essential Tools ⭐⭐⭐

Add to `modules/home/home.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages

  # ESSENTIAL ADDITIONS:
  jq                  # JSON processor (essential for CLI work)
  imagemagick         # Image manipulation
  gvfs                # Virtual file systems (Android, network shares)

  # System utilities
  dust                # Better disk usage
  tldr                # Quick command help

  # Desktop integration
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
];
```

### Priority 2: Enhanced Workflow ⭐⭐

Add to `modules/home/programs/development.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages

  # WORKFLOW ENHANCEMENTS:
  lazydocker          # Docker TUI
  lazygit             # Git TUI
  gum                 # Beautiful shell scripts
];
```

### Priority 3: Productivity Tools ⭐

Add to `modules/home/home.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages

  # PRODUCTIVITY:
  obsidian            # Note-taking
  signal-desktop      # Secure messaging
  gnome-calculator    # Calculator
  obs-studio          # Screen recording/streaming
  xournalpp           # PDF annotation
];
```

### Priority 4: Wayland Enhancements ⭐

Add to `modules/home/programs/hyprland.nix`:

```nix
home.packages = with pkgs; [
  # ... existing packages

  # WAYLAND/HYPRLAND:
  swayosd             # Beautiful OSD
  hyprsunset          # Blue light filter
  wayfreeze           # Screen freeze
  satty               # Screenshot annotation
];
```

### Priority 5: Fonts ⭐

Add to `modules/home/home.nix` or create `modules/home/config/fonts.nix`:

```nix
home.packages = with pkgs; [
  # Better font coverage
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  font-awesome
];
```

---

## What NOT to Add

### ❌ Arch-Specific:
- `yay` - AUR helper (Arch only)
- `expac` - Pacman database query
- `asdcontrol` - Arch-specific daemon

### ❌ Redundant:
- `alacritty` - You have kitty
- `nautilus` - You have nemo
- `walker` - You have wofi
- `swaybg` - You have hyprpaper
- `1password` - You have keepassxc

### ❌ Omarchy-Specific:
- `elephant-*` - Custom Omarchy apps
- `omarchy-nvim` - Custom neovim config
- `omarchy-chromium` - Custom browser

### ❌ Not Available in NixOS (Yet):
- `ghostty` - Too new, not in nixpkgs
- `aether` - Unknown package

---

## Package Installation Guide

### Option 1: Add All Recommended (Conservative)

Create `PACKAGES-TO-ADD.nix` with essentials only:

```nix
# Essential additions only
home.packages = with pkgs; [
  # Priority 1: Essential
  jq
  imagemagick
  gvfs
  dust
  tldr
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk

  # Priority 2: Development
  lazydocker
  lazygit
  gum

  # Priority 3: Fonts
  noto-fonts
  noto-fonts-emoji
  font-awesome
];
```

### Option 2: Full Omarchy Experience

Add all useful packages (more comprehensive):

```nix
home.packages = with pkgs; [
  # System utilities
  jq
  imagemagick
  gvfs
  dust
  tldr
  plocate

  # Development
  lazydocker
  lazygit
  gum
  clang

  # Productivity
  obsidian
  signal-desktop
  gnome-calculator
  xournalpp

  # Media
  obs-studio
  satty

  # Wayland
  swayosd
  hyprsunset
  wayfreeze
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk

  # Fonts
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  font-awesome

  # Network
  avahi
  localsend
];
```

### Option 3: Selective (Recommended)

Pick only what you'll actually use. Start with Priority 1, add others as needed.

---

## Detailed Package Descriptions

### Essential Tools (Priority 1)

#### `jq` - JSON processor
```bash
# Example: Parse JSON from API
curl -s api.example.com/data | jq '.results[] | .name'

# Pretty print JSON
cat file.json | jq '.'
```
**Why:** Essential for working with JSON in CLI (APIs, configs, etc.)

#### `imagemagick` - Image manipulation
```bash
# Resize image
convert input.jpg -resize 1920x1080 output.jpg

# Convert format
convert image.png image.jpg

# Create thumbnails
mogrify -resize 200x200 *.jpg
```
**Why:** Swiss army knife for image processing

#### `gvfs` - Virtual file systems
- Android device mounting (MTP)
- Network shares (SMB/NFS)
- Remote filesystems

**Why:** Essential for connecting phones, network drives

#### `dust` - Better du
```bash
# Visual disk usage
dust

# Show top 10 largest
dust -n 10
```
**Why:** More intuitive than `du`, visual tree

#### `tldr` - Simplified man pages
```bash
# Quick examples
tldr tar
tldr rsync
tldr git
```
**Why:** Faster than reading full man pages

---

### Development Tools (Priority 2)

#### `lazydocker` - Docker TUI
```bash
lazydocker
```
**Why:** Visual Docker management, better than `docker ps`

#### `lazygit` - Git TUI
```bash
lazygit
```
**Why:** Interactive git interface, easier than CLI

#### `gum` - Beautiful shell scripts
```bash
# Interactive prompts
NAME=$(gum input --placeholder "Your name")
gum confirm "Install packages?" && install_packages

# Styled text
gum style --foreground 212 "Success!"
```
**Why:** Make beautiful terminal UIs easily

---

### Productivity (Priority 3)

#### `obsidian` - Note-taking
- Markdown-based
- Graph view
- Plugin ecosystem
- Perfect for knowledge management

**Why:** Best note-taking app, integrates well with git

#### `signal-desktop` - Messaging
- End-to-end encrypted
- Open source
- Secure alternative to WhatsApp

**Why:** Privacy-focused messaging

#### `obs-studio` - Recording/Streaming
- Professional screen recording
- Live streaming
- Scene management
- Essential for content creators

**Why:** Industry standard for recording

#### `xournalpp` - PDF annotation
- Handwriting support
- PDF markup
- Note-taking on documents

**Why:** Great for reviewing/annotating documents

---

### Wayland Enhancements (Priority 4)

#### `swayosd` - On-screen display
- Volume indicator
- Brightness indicator
- Beautiful animations

**Why:** Visual feedback for volume/brightness

#### `hyprsunset` - Blue light filter
- Reduce blue light at night
- Better for eyes
- Automatic based on time

**Why:** Eye strain reduction

#### `satty` - Screenshot annotation
- Annotate screenshots
- Arrows, text, highlighting
- Better than GIMP for quick annotations

**Why:** Quick screenshot markup

---

## Current vs Omarchy: Detailed Analysis

### What You Do Better:

1. ✅ **More comprehensive development setup**
   - You: Kubernetes, Terraform, Ansible
   - Omarchy: Basic docker only

2. ✅ **Better file manager selection**
   - You: yazi, nnn, ranger, nemo (4 options!)
   - Omarchy: Just nautilus

3. ✅ **NixOS-specific tools**
   - You: nixpkgs-fmt, nil, nix-tree, nix-index
   - Omarchy: None (Arch-based)

4. ✅ **PhotoGIMP integration**
   - You: GIMP with Photoshop UI
   - Omarchy: Just pinta

### What Omarchy Does Better:

1. ⚠️ **Productivity apps**
   - Omarchy: obsidian, typora, signal, calculator
   - You: Basic office suite

2. ⚠️ **Media production**
   - Omarchy: obs-studio, kdenlive, satty
   - You: Just GIMP

3. ⚠️ **Desktop integration**
   - Omarchy: Full xdg-desktop-portal setup
   - You: Missing some portals

4. ⚠️ **Fonts**
   - Omarchy: Noto complete collection
   - You: JetBrains Mono mainly

---

## Recommended Action Plan

### Phase 1: Essential (Do Now)

```bash
# Edit modules/home/home.nix
nano modules/home/home.nix

# Add to home.packages:
jq
imagemagick
gvfs
dust
tldr
xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk
noto-fonts
noto-fonts-emoji

# Rebuild
sudo nixos-rebuild switch --flake .#thinkpad
```

### Phase 2: Development (Week 1)

```bash
# Edit modules/home/programs/development.nix
nano modules/home/programs/development.nix

# Add:
lazydocker
lazygit
gum
clang

# Rebuild
```

### Phase 3: Productivity (As Needed)

```bash
# Add when you need them:
obsidian          # When you start taking notes
signal-desktop    # When you need secure messaging
obs-studio        # When you want to record
xournalpp         # When you need PDF annotation
```

### Phase 4: Wayland Polish (Optional)

```bash
# Add for better UX:
swayosd           # Visual volume/brightness
hyprsunset        # Blue light filter
satty             # Screenshot annotation
```

---

## Package Count Summary

### Your Current Setup:
- **Core packages**: ~42 (home.nix)
- **Development**: ~25 (development.nix)
- **Media**: ~6 (media.nix)
- **Browsers**: 1 (browsers.nix)
- **Hyprland**: ~4 (hyprland.nix)
- **Total**: ~78 packages

### After Adding Recommendations:
- **Essential (P1)**: +9 packages
- **Development (P2)**: +4 packages
- **Productivity (P3)**: +5 packages
- **Wayland (P4)**: +4 packages
- **Fonts (P5)**: +3 packages
- **New Total**: ~103 packages

### Omarchy Total:
- **Base**: ~85 packages
- **Other**: ~25 packages
- **Total**: ~110 packages

**Result: 94% of Omarchy's useful packages** (excluding Arch-specific)

---

## Conclusion

### Your Package Selection: ⭐⭐⭐⭐½ (9/10)

**Strengths:**
- ✅ Excellent development tools
- ✅ Multiple file manager options
- ✅ NixOS-specific tooling
- ✅ Good system utilities
- ✅ PhotoGIMP integration

**Gaps:**
- ⚠️ Missing productivity apps (obsidian, signal)
- ⚠️ Missing media production (obs-studio)
- ⚠️ Missing desktop integration (xdg-portals)
- ⚠️ Missing useful CLI tools (jq, gum)
- ⚠️ Limited font coverage

**Recommendation:**
Add Priority 1 (Essential) packages immediately. Add others as needed based on your workflow.

---

**Next Steps:**
1. Review Priority 1 packages
2. Add essential packages to home.nix
3. Rebuild and test
4. Add Priority 2-5 gradually as needed

**Questions to Ask Yourself:**
- Do I need note-taking? → Add obsidian
- Do I record/stream? → Add obs-studio
- Do I work with JSON? → Add jq (YES!)
- Do I use Android devices? → Add gvfs (YES!)
- Do I annotate PDFs? → Add xournalpp
