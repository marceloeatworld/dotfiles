#!/usr/bin/env bash
# NixOS Updates Monitor: Checks for available flake updates

FLAKE_DIR="$HOME/dotfiles/thinkpad-p14s-gen5"
CACHE_FILE="$HOME/.cache/waybar-nix-updates"
CACHE_DURATION=3600  # Cache for 1 hour

# Check if cache is fresh
if [ -f "$CACHE_FILE" ]; then
  cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
  if [ $cache_age -lt $CACHE_DURATION ]; then
    cat "$CACHE_FILE"
    exit 0
  fi
fi

# Check if flake directory exists
if [ ! -d "$FLAKE_DIR" ]; then
  echo '{"text": "󰄬", "tooltip": "Flake directory not found", "class": "ok"}' | tee "$CACHE_FILE"
  exit 0
fi

cd "$FLAKE_DIR" || exit 1

# Check for updates (compare current lock with latest)
# This is a simplified check - just see if flake.lock is old
lock_age=$(($(date +%s) - $(stat -c %Y "flake.lock" 2>/dev/null || echo 0)))
days_old=$((lock_age / 86400))

if [ $days_old -gt 7 ]; then
  # Flake is more than 7 days old
  tooltip="┌─ 󰏔 NixOS UPDATES ────┐"
  tooltip="$tooltip\n│ Last update: $days_old days ago"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ Run: nix flake update"
  tooltip="$tooltip\n└──────────────────────┘"
  tooltip="$tooltip\n\nClick to open terminal"

  echo "{\"text\": \"󰏔 $days_old\", \"tooltip\": \"$tooltip\", \"class\": \"updates\"}" | tee "$CACHE_FILE"
else
  tooltip="󰄬 System is up to date\n\nLast update: $days_old days ago"
  echo "{\"text\": \"󰄬\", \"tooltip\": \"$tooltip\", \"class\": \"ok\"}" | tee "$CACHE_FILE"
fi
