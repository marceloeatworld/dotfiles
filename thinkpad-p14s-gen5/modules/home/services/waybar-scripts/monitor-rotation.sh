#!/usr/bin/env bash
# Monitor Rotation Display: Shows current rotation status

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
  # No external monitor - show disabled state
  echo "{\"text\": \"󰹑\", \"tooltip\": \"No external monitor\", \"class\": \"disabled\"}"
  exit 0
fi

# Display current rotation status based on state file
case "$CURRENT_ROTATION" in
  0)
    ICON="󰹑"  # Monitor icon (normal)
    DESC="0° (Normal)"
    ;;
  1)
    ICON="󰹑"  # Monitor icon (90°)
    DESC="90° (Portrait)"
    ;;
  2)
    ICON="󰹑"  # Monitor icon (180°)
    DESC="180° (Inverted)"
    ;;
  3)
    ICON="󰹑"  # Monitor icon (270°)
    DESC="270° (Portrait Flipped)"
    ;;
  *)
    ICON="󰹑"
    DESC="0° (Normal)"
    ;;
esac

# Return current state for Waybar display
tooltip="┌─ 󰹑 MONITOR ───────────┐"
tooltip="$tooltip\n│ Display: $EXTERNAL_MONITOR"
tooltip="$tooltip\n│ Current: $DESC"
tooltip="$tooltip\n└───────────────────────┘"
tooltip="$tooltip\n\nClick to rotate 90°"

echo "{\"text\": \"$ICON\", \"tooltip\": \"$tooltip\", \"class\": \"active\"}"
