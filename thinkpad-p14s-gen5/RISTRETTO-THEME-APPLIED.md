# 🎨 Thème Ristretto - Configuration Complète

**Thème Ristretto appliqué à TOUT le système !**

---

## 🎨 **Palette Couleurs Ristretto**

```
Background:     #2c2525  (Marron foncé)
Foreground:     #e6d9db  (Beige rosé)
Cursor:         #c3b7b8  (Beige clair)
Border:         #e6d9db  (Beige rosé)
Accent:         #f9cc6c  (Jaune doré)
Selection:      #403e41  (Marron moyen)

Couleurs:
- Rouge:        #fd6883 / #ff8297
- Vert:         #adda78 / #c8e292
- Jaune:        #f9cc6c / #fcd675
- Orange:       #f38d70 / #f8a788
- Violet:       #a8a9eb / #bebffd
- Cyan:         #85dacc / #9bf1e1
- Blanc:        #e6d9db / #f1e5e7
- Gris:         #72696a / #948a8b
```

---

## ✅ **Applications Thémées avec Ristretto**

### 1. **Hyprland** ✅
```nix
source = ${inputs.themes}/themes/ristretto/hyprland.conf
```
- Bordures: #e6d9db
- Couleurs fenêtres
- Animations

### 2. **Kitty (Terminal)** ✅
```
Background:     #2c2525
Foreground:     #e6d9db
Cursor:         #c3b7b8
Tab active:     #f9cc6c (jaune)
Tab inactive:   #2c2525
Borders:        #e6d9db
```

**16 couleurs palette complète Ristretto**

### 3. **Walker (Launcher)** ✅
```toml
theme = "ristretto"
```

**Fichier CSS:**
```css
background:     #2c2525
foreground:     #e6d9db
border:         #e6d9db
selected-text:  #fabd2f
```

### 4. **SwayOSD (Volume/Brightness)** ✅
```css
background:     #2c2525
border:         #c3b7b8
progress:       #c3b7b8
label/image:    #c3b7b8
trough:         #403e41
```

### 5. **Mako (Notifications)** ✅
```
Background:     #2c2525
Text:           #e6d9db
Border:         #e6d9db
Progress:       #403e41

Urgence:
- Low:          #85dacc (cyan)
- Normal:       #e6d9db (beige)
- High:         #fd6883 (rouge)
```

---

## 🌙 **Filtre Lumière Bleue - Hyprsunset**

### Keybinding
```
SUPER + N  →  Toggle filtre lumière bleue
```

### Configuration
```bash
# Activer (4500K - chaleureux)
hyprsunset -t 4500

# Désactiver
pkill hyprsunset

# Toggle (SUPER + N fait ça automatiquement)
pkill hyprsunset || hyprsunset -t 4500
```

### Températures Disponibles
```
6500K  →  Lumière du jour (pas de filtre)
5000K  →  Léger filtre
4500K  →  Filtre moyen (défaut) ⭐
4000K  →  Filtre fort
3500K  →  Très chaud (coucher de soleil)
3000K  →  Maximum (nuit)
```

**Pour changer la température:**
Édite `hyprland.nix` ligne 245:
```nix
"$mod, N, exec, pkill hyprsunset || hyprsunset -t 4000"  # Change 4500 → 4000
```

---

## ⌨️ **Keybindings Complets**

### Applications
```
SUPER + Return       → Kitty (terminal)
SUPER + B            → Brave (browser)
SUPER + E            → Nemo (files)
SUPER + D            → Walker (launcher)
```

### Utilitaires
```
SUPER + Escape       → Swaylock (verrouillage)
SUPER + C            → Hyprpicker (color picker)
SUPER + N            → Toggle filtre lumière bleue ⭐ NOUVEAU
Print                → Screenshot clipboard
SUPER + Print        → Screenshot fichier
```

### Média
```
Volume +/-           → SwayOSD (Ristretto)
Brightness +/-       → SwayOSD (Ristretto)
```

---

## 📁 **Fichiers Modifiés**

### Thème Ristretto
```
✅ modules/home/programs/hyprland.nix
   - Thème Ristretto + keybinding hyprsunset

✅ modules/home/programs/terminal.nix (Kitty)
   - Couleurs complètes Ristretto
   - 16 couleurs palette

✅ modules/home/programs/walker.nix
   - theme = "ristretto"
   - CSS Ristretto

✅ modules/home/services/swayosd.nix
   - Couleurs Ristretto CSS

✅ modules/home/services/mako.nix
   - Couleurs Ristretto
   - Urgences avec couleurs Ristretto
```

### Configuration
```
✅ modules/home/home.nix
   - wofi.nix retiré
   - Walker seul lanceur
```

---

## 🎯 **Cohérence Thème**

**Toutes les applications utilisent la même palette:**

| App | Background | Foreground | Accent | Statut |
|-----|-----------|-----------|--------|---------|
| **Hyprland** | #2c2525 | #e6d9db | #e6d9db | ✅ |
| **Kitty** | #2c2525 | #e6d9db | #f9cc6c | ✅ |
| **Walker** | #2c2525 | #e6d9db | #fabd2f | ✅ |
| **SwayOSD** | #2c2525 | #c3b7b8 | #c3b7b8 | ✅ |
| **Mako** | #2c2525 | #e6d9db | #e6d9db | ✅ |

**Cohérence totale: 100%** 🎉

---

## 🚀 **Installation**

```bash
cd /home/marcelo/dotfiles/thinkpad-p14s-gen5
sudo nixos-rebuild switch --flake .#pop
```

---

## ✅ **Tests Post-Installation**

### 1. Vérifier Thème Kitty
```bash
SUPER + Return                 # Ouvrir terminal
→ Background doit être marron foncé (#2c2525)
→ Text doit être beige (#e6d9db)
→ Tab active doit être jaune (#f9cc6c)
```

### 2. Vérifier Walker
```bash
SUPER + D                      # Ouvrir Walker
→ Background marron
→ Border beige
```

### 3. Vérifier SwayOSD
```bash
XF86AudioRaiseVolume          # Volume +
→ OSD marron avec border beige
```

### 4. Vérifier Mako
```bash
notify-send "Test" "Notification test"
→ Notification marron avec border beige
```

### 5. Tester Hyprsunset
```bash
SUPER + N                      # Activer filtre
→ Écran devient plus chaud (4500K)

SUPER + N                      # Désactiver
→ Écran redevient normal
```

---

## 🎨 **Captures d'Écran Attendues**

### Hyprland
- Bordures fenêtres: Beige (#e6d9db)
- Background: Marron (#2c2525) sur wallpaper

### Kitty
- Terminal marron foncé
- Text beige
- Tabs avec jaune doré actif

### Walker
- Launcher marron
- Border beige
- Text beige

### SwayOSD
- OSD marron transparent
- Border beige
- Progress beige

### Mako
- Notifications marron
- Border beige/cyan/rouge selon urgence

---

## 📊 **Résumé Configuration**

```
Système:          NixOS 25.05
WM:               Hyprland
Thème:            Ristretto (PARTOUT) ✅
Terminal:         Kitty (Ristretto)
Lanceur:          Walker (Ristretto, SEUL)
OSD:              SwayOSD (Ristretto)
Notifications:    Mako (Ristretto)
Filtre lumière:   Hyprsunset (SUPER + N) ⭐

Apps thémées:     5/5 (100%)
Cohérence:        Parfaite
```

---

## 🎉 **Résultat Final**

✅ **Thème Ristretto unifié** sur tout le système
✅ **Un seul lanceur** (Walker avec Ristretto)
✅ **Filtre lumière bleue** (SUPER + N)
✅ **Cohérence visuelle** parfaite
✅ **Esthétique** élégante et sobre
✅ **Performance** optimale

**Configuration NixOS avec Ristretto = Magnifique ! 🎨**
