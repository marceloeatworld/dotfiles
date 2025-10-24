# ✅ Configuration Finale - NixOS ThinkPad P14s Gen 5

**Date:** 2025-10-24
**Système:** NixOS 25.05 + Hyprland
**Hostname:** pop
**User:** marcelo

---

## 🎯 **LANCEUR UNIQUE: WALKER**

```nix
✅ SUPER + D  →  Walker (UNIQUEMENT)
❌ Wofi retiré complètement
```

**Aucun lanceur de secours** - Walker uniquement ! 🎯

---

## 📦 **Configuration Modules**

### Modules Home Manager (18 modules)

```nix
1.  ✅ hyprland.nix        # Hyprland + Walker keybinding
2.  ✅ terminal.nix        # Kitty amélioré
3.  ✅ shell.nix           # Zsh + Starship
4.  ✅ git.nix             # Git
5.  ✅ nvim.nix            # Neovim
6.  ✅ browsers.nix        # Brave
7.  ✅ brave-flags.nix     # Brave Wayland
8.  ✅ webapps.nix         # 7 web apps
9.  ✅ media.nix           # MPV, OBS
10. ✅ development.nix     # VSCode, langages
11. ✅ walker.nix          # Walker (SEUL LANCEUR) ⭐
12. ✅ fastfetch.nix       # System info ⭐
13. ✅ xournalpp.nix       # PDF annotation ⭐
14. ✅ uwsm.nix            # UWSM env ⭐
15. ✅ waybar.nix          # Barre de statut
16. ✅ mako.nix            # Notifications
17. ✅ swaylock.nix        # Écran verrouillage
18. ✅ swayosd.nix         # Volume/Brightness OSD ⭐
19. ✅ gtk.nix             # Thème GTK
20. ✅ qt.nix              # Thème Qt
21. ✅ fontconfig.nix      # Fonts ⭐
```

**⭐ = Nouveaux modules**
**❌ wofi.nix = RETIRÉ**

---

## 🎨 **Walker - Lanceur Unique**

### Fonctionnalités

```bash
# Lancer Walker
SUPER + D

# Chercher une application
→ Taper "brave"

# Chercher un fichier
→ Taper ".bashrc"

# Calculatrice
→ Taper "=2+2"

# Recherche web
→ Taper "@nixos hyprland"

# Clipboard
→ Taper "$"

# Liste des providers
→ Taper "/"
```

### Configuration

```toml
theme = "catppuccin"
force_keyboard_focus = true
selection_wrap = true
click_to_close = true

# Providers par défaut
default = ["desktopapplications", "websearch"]
empty = ["desktopapplications"]

# Préfixes
"/" → providerlist
"." → files
":" → symbols
"=" → calc
"@" → websearch
"$" → clipboard
```

---

## ⌨️ **Keybindings Hyprland**

### Applications
```
SUPER + Return       → Kitty (terminal)
SUPER + B            → Brave (browser)
SUPER + E            → Nemo (file manager)
SUPER + D            → Walker (SEUL LANCEUR) ⭐
```

### Système
```
SUPER + Q            → Fermer fenêtre
SUPER + F            → Fullscreen
SUPER + SPACE        → Floating toggle
SUPER + Escape       → Swaylock (verrouillage)
```

### Screenshots
```
Print                → Screenshot clipboard
SUPER + Print        → Screenshot fichier
```

### Média (avec SwayOSD)
```
XF86AudioRaiseVolume → Volume +
XF86AudioLowerVolume → Volume -
XF86AudioMute        → Mute
XF86MonBrightnessUp  → Brightness +
XF86MonBrightnessDown → Brightness -
```

---

## 🔧 **Optimisations Système**

### Boot (boot.nix)
```nix
✅ Fast shutdown: 5s (au lieu de 90s)
✅ Plymouth désactivé (boot rapide)
```

### Network (networking.nix)
```nix
✅ TCP MTU probing = 1 (fix SSH/VPN)
```

### Terminal (terminal.nix)
```nix
✅ Padding: 14px (amélioré)
✅ Cursor: block sans clignotement
✅ Decorations: cachées
✅ Tab bar: en bas
✅ Remote control: activé
✅ Single instance: activé
✅ Clipboard: Ctrl+Insert / Shift+Insert
```

---

## 🎨 **Thèmes**

```
Hyprland:     Ristretto (${inputs.themes}/themes/ristretto/hyprland.conf)
Walker:       Catppuccin
GTK/Qt:       Catppuccin
Kitty:        Catppuccin Mocha
SwayOSD:      Catppuccin Mocha
```

---

## 📁 **Structure Fichiers**

```
dotfiles/thinkpad-p14s-gen5/
├── flake.nix                      # Flake principal
├── hosts/thinkpad/
│   ├── configuration.nix
│   ├── hardware-configuration.nix
│   └── disko-config.nix          # LUKS + Btrfs
├── modules/
│   ├── system/
│   │   ├── boot.nix              ⚡ Fast shutdown
│   │   ├── networking.nix        🔧 TCP MTU probing
│   │   ├── services.nix
│   │   ├── virtualisation.nix
│   │   └── ...
│   └── home/
│       ├── home.nix              📦 18 imports
│       ├── programs/
│       │   ├── hyprland.nix      ⌨️ Walker keybinding
│       │   ├── walker.nix        ⭐ NEW
│       │   ├── fastfetch.nix     ⭐ NEW
│       │   ├── xournalpp.nix     ⭐ NEW
│       │   ├── uwsm.nix          ⭐ NEW
│       │   ├── terminal.nix      🖥️ Kitty amélioré
│       │   └── ...
│       ├── services/
│       │   ├── swayosd.nix       ⭐ NEW
│       │   └── ...
│       └── config/
│           ├── fontconfig.nix    ⭐ NEW
│           └── ...
```

---

## ✅ **Changements Finaux**

### Retirés
```diff
- ./programs/wofi.nix
- "$mod SHIFT, D, exec, wofi --show drun"
```

### Ajoutés
```diff
+ ./programs/walker.nix
+ ./programs/fastfetch.nix
+ ./programs/xournalpp.nix
+ ./programs/uwsm.nix
+ ./services/swayosd.nix
+ ./config/fontconfig.nix
+ "$mod, D, exec, walker"
+ systemd.extraConfig = "DefaultTimeoutStopSec=5s"
+ boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1
```

---

## 🚀 **Installation**

```bash
# Depuis le répertoire dotfiles
cd /home/marcelo/dotfiles/thinkpad-p14s-gen5

# Rebuild et switch
sudo nixos-rebuild switch --flake .#pop
```

---

## ✅ **Tests Post-Installation**

### 1. Walker
```bash
SUPER + D                    # Ouvrir Walker
→ Taper "brave"              # Chercher app
→ Taper "=2+2"               # Calculatrice
→ ESC                        # Fermer
```

### 2. Kitty
```bash
SUPER + Return               # Ouvrir terminal
→ Vérifier padding (14px)
→ Ctrl+Insert (copy)
→ Shift+Insert (paste)
```

### 3. SwayOSD
```bash
XF86AudioRaiseVolume         # Volume +
→ OSD violet doit apparaître
```

### 4. Fastfetch
```bash
fastfetch                    # System info
→ Sections: Hardware, Software, System
```

### 5. Fontconfig
```bash
fc-match monospace           # → CaskaydiaMono Nerd Font
fc-match sans-serif          # → Liberation Sans
```

---

## 📊 **Statistiques**

```
Modules Home Manager:    18 (wofi retiré)
Nouveaux modules:        6
Fichiers modifiés:       4
Lanceur:                 Walker (unique)
Thème:                   Catppuccin + Ristretto
Fast shutdown:           5s (18x plus rapide)
```

---

## 🎯 **Configuration Finale**

✅ **Un seul lanceur:** Walker (pas de Wofi)
✅ **Thème cohérent:** Catppuccin partout
✅ **Optimisations:** Fast shutdown + network fix
✅ **Terminal amélioré:** Kitty avec padding 14px
✅ **OSD:** SwayOSD pour volume/brightness
✅ **Fonts:** Liberation + CaskaydiaMono Nerd
✅ **System info:** Fastfetch
✅ **PDF:** Xournalpp configuré
✅ **Code propre:** Aucune référence "omarchy" dans variables

---

## 🎉 **Résultat**

**Configuration NixOS professionnelle, minimaliste et efficace !**

- Simple: Un seul lanceur (Walker)
- Efficace: Fast shutdown, optimisations réseau
- Beau: Thème Catppuccin cohérent
- Complet: Tous les outils nécessaires
- Propre: Code bien organisé

**Prêt pour production ! 🚀**
