#!/usr/bin/env bash
# Audio output switcher: toggle between internal speakers and headphones (jack)
# Volume is shared - switching keeps the same volume level

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

# Get current volume for notification
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -oP 'Volume: \K[\d.]+')
VOL_PCT=$(awk "BEGIN{printf \"%.0f\", $VOL * 100}")

# Read current state (0 = headphones/jack, 1 = internal speakers)
CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

if [ "$CURRENT_STATE" = "0" ]; then
  echo "1" > "$STATE_FILE"

  # Disable Auto-Mute Mode (critical for forcing speakers when jack is plugged)
  amixer -c "$CARD" sset "Auto-Mute Mode" "Disabled" 2>/dev/null

  # Unmute speakers (don't touch volume - let PipeWire control it)
  amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
  amixer -c "$CARD" sset "Internal Speaker" unmute 2>/dev/null
  amixer -c "$CARD" sset "Master" unmute 2>/dev/null

  notify-send "Audio Output" "Speakers (${VOL_PCT}%)" -i audio-speakers
else
  echo "0" > "$STATE_FILE"

  # Re-enable auto-mute (normal behavior)
  amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null

  # Mute speakers
  amixer -c "$CARD" sset "Speaker" mute 2>/dev/null
  amixer -c "$CARD" sset "Internal Speaker" mute 2>/dev/null

  notify-send "Audio Output" "Headphones (${VOL_PCT}%)" -i audio-headphones
fi
