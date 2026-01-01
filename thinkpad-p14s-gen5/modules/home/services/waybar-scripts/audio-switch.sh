#!/usr/bin/env bash
# Audio output switcher: toggle between internal speakers and headphones (jack)
# Works even when headphones cable is NOT plugged in

STATE_FILE="$HOME/.config/audio-output-state"

# Auto-detect the sound card (find card with Speaker control)
CARD=""
for c in 0 1 2 3; do
  if amixer -c "$c" scontrols 2>/dev/null | grep -q "Speaker\|Internal Speaker"; then
    CARD="$c"
    break
  fi
done

if [ -z "$CARD" ]; then
  notify-send -u critical "Audio Error" "No sound card with speaker control found" -i dialog-error
  exit 1
fi

# Read current state (0 = headphones/jack, 1 = internal speakers)
CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

if [ "$CURRENT_STATE" = "0" ]; then
  # Switch to internal speakers (force unmute even with jack plugged)
  echo "1" > "$STATE_FILE"

  # Disable Auto-Mute Mode FIRST (critical for forcing speakers when jack is plugged)
  amixer -c "$CARD" sset "Auto-Mute Mode" "Disabled" 2>/dev/null

  # Force unmute and set volume for speakers
  amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
  amixer -c "$CARD" sset "Speaker" 100% 2>/dev/null

  # Alternative control names (some systems use these)
  amixer -c "$CARD" sset "Internal Speaker" unmute 2>/dev/null
  amixer -c "$CARD" sset "Internal Speaker" 100% 2>/dev/null

  # Also unmute Master to ensure audio flows
  amixer -c "$CARD" sset "Master" unmute 2>/dev/null

  notify-send "Audio Output" "Switched to Internal Speakers" -i audio-speakers
else
  # Switch back to headphones/jack (default behavior)
  echo "0" > "$STATE_FILE"

  # Re-enable auto-mute (normal behavior - auto-switches based on jack detection)
  amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null

  # Mute speakers (let headphones take over when plugged in)
  amixer -c "$CARD" sset "Speaker" mute 2>/dev/null
  amixer -c "$CARD" sset "Internal Speaker" mute 2>/dev/null

  notify-send "Audio Output" "Switched to Headphones/Auto (Jack)" -i audio-headphones
fi
