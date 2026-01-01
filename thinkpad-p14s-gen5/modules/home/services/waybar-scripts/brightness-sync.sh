#!/usr/bin/env bash
# Synchronize brightness between internal (Lenovo) and external (HDMI) monitors

# Check if argument is provided
if [ -z "$1" ]; then
  echo "Usage: brightness-sync <+5%|-5%|50%>"
  exit 1
fi

CHANGE="$1"

# Change internal display brightness (Lenovo laptop screen)
brightnessctl set "$CHANGE" > /dev/null

# Get current brightness percentage
CURRENT=$(brightnessctl get)
MAX=$(brightnessctl max)
PERCENT=$((CURRENT * 100 / MAX))

# Sync external display if connected (HDMI via DDC/CI)
# Check if external display is available (suppress errors if not connected)
if ddcutil detect 2>/dev/null | grep -q "Display"; then
  # Set external monitor brightness to match internal
  ddcutil setvcp 10 "$PERCENT" 2>/dev/null || true
fi
