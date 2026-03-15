#!/usr/bin/env bash
# Monitor Rotation Action: Rotates the external monitor by 90°

STATE_FILE="$HOME/.config/monitor-rotation-state"

# Read current rotation (default: 0 = normal)
CURRENT_ROTATION=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

# Detect external monitor (HDMI-A-1 or DP-1)
EXTERNAL_MONITOR=""
if hyprctl monitors | grep -q "HDMI-A-1"; then
  EXTERNAL_MONITOR="HDMI-A-1"
elif hyprctl monitors | grep -q "DP-1"; then
  EXTERNAL_MONITOR="DP-1"
fi

if [ -z "$EXTERNAL_MONITOR" ]; then
  notify-send "Monitor Rotation" "No external monitor detected" -i video-display
  exit 1
fi

# Determine next rotation (cycle: 0 -> 90 -> 180 -> 270 -> 0)
case "$CURRENT_ROTATION" in
  0)
    NEXT_ROTATION="1"  # 90° clockwise
    TRANSFORM="1"
    DESC="90° (Portrait)"
    ;;
  1)
    NEXT_ROTATION="2"  # 180° upside-down
    TRANSFORM="2"
    DESC="180° (Inverted)"
    ;;
  2)
    NEXT_ROTATION="3"  # 270° counter-clockwise
    TRANSFORM="3"
    DESC="270° (Portrait Flipped)"
    ;;
  3)
    NEXT_ROTATION="0"  # 0° normal
    TRANSFORM="0"
    DESC="0° (Normal)"
    ;;
  *)
    NEXT_ROTATION="0"
    TRANSFORM="0"
    DESC="0° (Normal)"
    ;;
esac

# Apply rotation using Hyprland
hyprctl keyword monitor "$EXTERNAL_MONITOR,transform,$TRANSFORM"

# Fix duplicate cursor bug by reloading cursor theme
sleep 0.3
hyprctl setcursor Bibata-Modern-Classic 24

# Save state
echo "$NEXT_ROTATION" > "$STATE_FILE"

# Send notification
notify-send "Monitor Rotation" "$EXTERNAL_MONITOR: $DESC" -i video-display
