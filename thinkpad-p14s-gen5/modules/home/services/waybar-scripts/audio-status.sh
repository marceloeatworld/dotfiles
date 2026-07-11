#!/usr/bin/env bash
# Waybar audio status with Pango markup tooltip

source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_ACCENT="#d4c080"; C_GREEN="#90c090"; C_RED="#d08080"; }

pango_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

repeat_char() {
  local char="$1"
  local count="$2"
  local out=""
  while [ "$count" -gt 0 ]; do
    out="${out}${char}"
    count=$((count - 1))
  done
  printf '%s' "$out"
}

STATE_FILE="$HOME/.config/audio-output-state"
MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "auto")

VOL_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
VOL=$(echo "$VOL_INFO" | grep -oP 'Volume: \K[\d.]+')
VOL_PCT=$(awk "BEGIN{printf \"%.0f\", ${VOL:-0} * 100}")
MUTED=$(echo "$VOL_INFO" | grep -c "MUTED")

SINK_NAME=$(wpctl status 2>/dev/null | sed -n '/Sinks:/,/Sources:/p' | grep '\*' | sed 's/.*\*[[:space:]]*//' | sed 's/\[.*//' | sed 's/^[0-9]*\.[[:space:]]*//' | xargs)

# Jack detection
JACK=""
CARD=""
for c in 0 1 2 3; do
  if amixer -c "$c" scontrols 2>/dev/null | grep -q "Speaker\|Internal Speaker"; then
    CARD="$c"
    break
  fi
done
[ -n "$CARD" ] && amixer -c "$CARD" contents 2>/dev/null | grep -A1 "Headphone Jack" | grep -q "values=on" && JACK="plugged"

# Visual volume bar with Pango colors
BAR_PCT=$VOL_PCT
[ "$BAR_PCT" -lt 0 ] && BAR_PCT=0
[ "$BAR_PCT" -gt 100 ] && BAR_PCT=100
filled=$((BAR_PCT / 10))
empty=$((10 - filled))
vol_bar="<span color='$C_ACCENT'>$(repeat_char '█' "$filled")</span><span color='$C_DIM'>$(repeat_char '░' "$empty")</span>"

# Icon and mode
case "$MODE" in
  speakers) ICON="󰓃"; CLASS="speakers"; MODE_DESC="Forced Speakers" ;;
  hdmi) ICON="󰡁"; CLASS="hdmi"; MODE_DESC="HDMI / DisplayPort" ;;
  *)
    CLASS="auto"; MODE_DESC="Auto (jack detection)"
    [ -n "$JACK" ] && { ICON="󰋋"; MODE_DESC="Headphones"; } || ICON="󰕾"
    ;;
esac

[ "$MUTED" -gt 0 ] && { ICON="󰖁"; CLASS="${CLASS} muted"; }

# Tooltip
if [ "$MUTED" -gt 0 ]; then
  TOOLTIP="<span color='$C_RED'><b>MUTED</b></span>"
else
  TOOLTIP="$vol_bar <span color='$C_FG'>${VOL_PCT}%</span>"
fi
TOOLTIP="${TOOLTIP}\n\n<span color='$C_DIM'>Output</span>  <span color='$C_FG'>$MODE_DESC</span>"
[ -n "$SINK_NAME" ] && TOOLTIP="${TOOLTIP}\n<span color='$C_DIM'>Device</span>  <span color='$C_FG'>$(pango_escape "$SINK_NAME")</span>"
[ -n "$JACK" ] && TOOLTIP="${TOOLTIP}\n<span color='$C_GREEN'>🎧 Headphones plugged</span>"
TOOLTIP="${TOOLTIP}\n\n<span color='$C_DIM'>Left: Cycle │ Right: Mute │ Middle: Mixer</span>"
TOOLTIP="${TOOLTIP//\\n/$'\n'}"

jq -cn \
  --arg text "$ICON $VOL_PCT%" \
  --arg tooltip "$TOOLTIP" \
  --arg class "$CLASS" \
  '{text: $text, tooltip: $tooltip, class: $class}'
