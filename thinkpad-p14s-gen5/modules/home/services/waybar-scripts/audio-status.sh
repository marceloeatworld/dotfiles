#!/usr/bin/env bash
# Waybar custom module: shows current audio output mode and volume
# Returns JSON for waybar with text, tooltip, and class

STATE_FILE="$HOME/.config/audio-output-state"
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "auto")

# Get volume and mute state (single call)
VOL_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
VOL=$(echo "$VOL_INFO" | grep -oP 'Volume: \K[\d.]+')
VOL_PCT=$(awk "BEGIN{printf \"%.0f\", ${VOL:-0} * 100}")
MUTED=$(echo "$VOL_INFO" | grep -c "MUTED")

# Get default sink name from wpctl status (faster than wpctl inspect)
SINK_NAME=$(wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep '\*' | sed 's/.*\*[[:space:]]*//' | sed 's/\[.*//' | sed 's/^[0-9]*\.[[:space:]]*//' | xargs)

# Check jack status
JACK=""
CARD=""
for c in 0 1 2 3; do
  if amixer -c "$c" scontrols 2>/dev/null | grep -q "Speaker\|Internal Speaker"; then
    CARD="$c"
    break
  fi
done
if [ -n "$CARD" ]; then
  amixer -c "$CARD" contents 2>/dev/null | grep -A1 "Headphone Jack" | grep -q "values=on" && JACK="plugged"
fi

# Determine icon based on mode
case "$MODE" in
  speakers)
    ICON="󰓃"
    CLASS="speakers"
    MODE_DESC="Forced Speakers (Auto-Mute disabled)"
    ;;
  hdmi)
    ICON="󰡁"
    CLASS="hdmi"
    MODE_DESC="HDMI / DisplayPort"
    ;;
  *)
    CLASS="auto"
    MODE_DESC="Auto (jack detection)"
    if [ -n "$JACK" ]; then
      ICON="󰋋"
      MODE_DESC="Auto → Headphones (jack detected)"
    else
      ICON="󰕾"
    fi
    ;;
esac

# Mute override
if [ "$MUTED" -gt 0 ]; then
  ICON="󰖁"
  CLASS="${CLASS} muted"
fi

# Build tooltip
TOOLTIP="Volume: ${VOL_PCT}%"
[ "$MUTED" -gt 0 ] && TOOLTIP="Volume: MUTED"
TOOLTIP="${TOOLTIP}\\nOutput: ${MODE_DESC}"
[ -n "$SINK_NAME" ] && TOOLTIP="${TOOLTIP}\\nDevice: ${SINK_NAME}"
[ -n "$JACK" ] && TOOLTIP="${TOOLTIP}\\nJack: plugged"
TOOLTIP="${TOOLTIP}\\n\\nLeft: Cycle (Auto → Speakers → HDMI)\\nRight: Mute\\nMiddle: Hyprpwcenter\\nScroll: Volume"

# Output JSON
printf '{"text": "%s %s%%", "tooltip": "%s", "class": "%s"}\n' "$ICON" "$VOL_PCT" "$TOOLTIP" "$CLASS"
