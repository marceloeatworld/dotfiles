# Monitor Configuration

## Your Setup

### Built-in Display (Lenovo ThinkPad)
- **Name**: eDP-1
- **Resolution**: 1920x1200 @ 60Hz
- **Position**: Below external monitor (when external connected)

### External Monitor
- **Names**: HDMI-A-1 or DP-1 (depends on connection)
- **Resolution**: 1920x1080 @ 60Hz
- **Position**: Top, **PRIMARY**

## Configuration

In `modules/home/programs/hyprland.nix`:

```nix
monitor = [
  # External monitor - PRIMARY (top)
  "HDMI-A-1,1920x1080@60,0x0,1"
  "DP-1,1920x1080@60,0x0,1"

  # Built-in screen (below external)
  "eDP-1,1920x1200@60,0x1080,1"
]
```

## Layout

When external monitor connected (vertical stacking):
```
┌──────────────────┐
│   External       │
│   1920x1080      │
│   PRIMARY        │
│   (HDMI/DP)      │
│   Position: 0x0  │
└──────────────────┘
┌──────────────────┐
│   Lenovo eDP-1   │
│   1920x1200      │
│   Position:      │
│   0x1080         │
└──────────────────┘
```

## After Installation - Verify Monitor Names

Run this command to see your actual monitor names:
```bash
hyprctl monitors
```

Output example:
```
Monitor eDP-1 (ID 0):
  1920x1200@60.00Hz at 1920x0
  
Monitor HDMI-A-1 (ID 1):
  1920x1080@60.00Hz at 0x0
```

If your external monitor has a different name, update the config:
```bash
# Edit config
nano ~/dotfiles/thinkpad-p14s-gen5/modules/home/programs/hyprland.nix

# Rebuild
sudo nixos-rebuild switch --flake .#thinkpad
```

## Hotkey to Switch Monitors

You can add this to your Hyprland config (optional):

```nix
bind = [
  # Toggle external monitor
  "$mod SHIFT, M, exec, hyprctl keyword monitor 'HDMI-A-1,disable'"
  
  # Re-enable all monitors
  "$mod SHIFT, N, exec, hyprctl reload"
];
```

## Common Monitor Names

- **HDMI**: HDMI-A-1, HDMI-A-2
- **DisplayPort**: DP-1, DP-2
- **USB-C/Thunderbolt**: DP-3, DP-4
- **Built-in**: eDP-1

To find yours: `hyprctl monitors` or `wlr-randr`
