# Omarchy Hyprland Themes

## Available Themes (12 total)

Your configuration includes access to all Omarchy Hyprland themes from the Arch-based distribution.

### Theme List:

1. **catppuccin** ☕ (Currently active)
   - Soothing pastel theme
   - Color: Light purple/pink tones

2. **catppuccin-latte** ☕
   - Light variant of Catppuccin
   - Perfect for daytime use

3. **everforest** 🌲
   - Comfortable green forest theme
   - Easy on the eyes

4. **flexoki-light** ☀️
   - Light, warm tones
   - Great for bright environments

5. **gruvbox** 🎨
   - Retro groove colors
   - Warm, vintage aesthetic

6. **kanagawa** 🌊
   - Inspired by Japanese painting
   - Dark blue/purple theme

7. **matte-black** 🖤
   - Pure dark theme
   - Minimalist aesthetic

8. **nord** ❄️
   - Arctic, north-bluish theme
   - Clean and cold palette

9. **osaka-jade** 🍃
   - Green jade colors
   - Calm and elegant

10. **ristretto** ☕
    - Coffee-inspired browns
    - Warm and cozy

11. **rose-pine** 🌹
    - Soho vibes with rose tones
    - Elegant and subtle

12. **tokyo-night** 🌃
    - Night Tokyo neon colors
    - Popular dark theme

## How to Change Theme

Edit `/home/marcelo/dotfiles/thinkpad-p14s-gen5/modules/home/programs/hyprland.nix`:

```nix
# Find this line (around line 13):
extraConfig = ''
  source = ${inputs.omarchy}/themes/catppuccin/hyprland.conf
'';

# Change to your preferred theme:
extraConfig = ''
  source = ${inputs.omarchy}/themes/tokyo-night/hyprland.conf
'';
```

### Available theme paths:
```nix
${inputs.omarchy}/themes/catppuccin/hyprland.conf
${inputs.omarchy}/themes/catppuccin-latte/hyprland.conf
${inputs.omarchy}/themes/everforest/hyprland.conf
${inputs.omarchy}/themes/flexoki-light/hyprland.conf
${inputs.omarchy}/themes/gruvbox/hyprland.conf
${inputs.omarchy}/themes/kanagawa/hyprland.conf
${inputs.omarchy}/themes/matte-black/hyprland.conf
${inputs.omarchy}/themes/nord/hyprland.conf
${inputs.omarchy}/themes/osaka-jade/hyprland.conf
${inputs.omarchy}/themes/ristretto/hyprland.conf
${inputs.omarchy}/themes/rose-pine/hyprland.conf
${inputs.omarchy}/themes/tokyo-night/hyprland.conf
```

## After Changing Theme

Rebuild your configuration:

```bash
cd ~/dotfiles/thinkpad-p14s-gen5
sudo nixos-rebuild switch --flake .#thinkpad

# Or reload Hyprland without full rebuild:
hyprctl reload
```

## What Themes Customize

Omarchy themes modify:
- ✅ **Border colors** - Active/inactive window borders
- ✅ **Group colors** - Grouped window borders
- ✅ **General colors** - Overall color scheme

They work perfectly with your existing:
- Catppuccin GTK theme
- Catppuccin Qt theme
- Waybar colors
- Kitty terminal colors

## Mix & Match

You can mix Omarchy Hyprland themes with other themes:

```nix
# Hyprland: Tokyo Night
extraConfig = ''
  source = ${inputs.omarchy}/themes/tokyo-night/hyprland.conf
'';

# GTK/Qt: Keep Catppuccin (in gtk.nix and qt.nix)
# Terminal: Keep Catppuccin (in terminal.nix)
```

## Preview Colors

Want to see theme colors before applying?

Visit: https://github.com/basecamp/omarchy/tree/master/themes

Each theme folder shows the color palette.

## Recommended Themes

Based on your current Catppuccin setup:

1. **catppuccin** - Already set, matches everything ✅
2. **tokyo-night** - Popular, vibrant, well-tested
3. **rose-pine** - Elegant, subtle, professional
4. **nord** - Clean, consistent with Catppuccin aesthetic
5. **gruvbox** - If you want warmer tones

## Troubleshooting

### Theme not applying?

```bash
# 1. Check syntax
nix flake check

# 2. Rebuild
sudo nixos-rebuild switch --flake .#thinkpad

# 3. Reload Hyprland
hyprctl reload
```

### Colors look wrong?

Make sure you're using the correct theme path. Check:
```bash
# List available themes
ls ${inputs.omarchy}/themes/
```

### Want to customize further?

Create your own theme file:

```bash
# Copy an existing theme
mkdir -p ~/.config/hypr/themes
cp ${inputs.omarchy}/themes/catppuccin/hyprland.conf ~/.config/hypr/themes/custom.conf

# Edit colors
nano ~/.config/hypr/themes/custom.conf

# Source it
extraConfig = ''
  source = ~/.config/hypr/themes/custom.conf
'';
```

---

**Current theme**: Catppuccin ☕
**Total themes available**: 12
**Source**: Omarchy (Arch-based, works on NixOS) ✅
