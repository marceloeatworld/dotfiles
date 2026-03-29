#!/usr/bin/env bash
# Synchronize brightness between internal (Lenovo) and external (HDMI) monitors
# Uses cached detection to avoid slow ddcutil calls

CACHE_FILE="$HOME/.cache/external-monitor-detected"
CACHE_DURATION=300  # 5 minutes

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

# Check if we have a recent cache of external monitor detection
use_cache=false
if [ -f "$CACHE_FILE" ]; then
  cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [ "$cache_age" -lt "$CACHE_DURATION" ]; then
    use_cache=true
  fi
fi

# Sync external display if connected (HDMI via DDC/CI)
if $use_cache; then
  # Use cached result
  if [ "$(cat "$CACHE_FILE")" = "1" ]; then
    ddcutil setvcp 10 "$PERCENT" 2>/dev/null &
  fi
else
  # Check for external display and cache result
  if ddcutil detect --brief 2>/dev/null | grep -q "Display"; then
    echo "1" > "$CACHE_FILE"
    ddcutil setvcp 10 "$PERCENT" 2>/dev/null &
  else
    echo "0" > "$CACHE_FILE"
  fi
fi
