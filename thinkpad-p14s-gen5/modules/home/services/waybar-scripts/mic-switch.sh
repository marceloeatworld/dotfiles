#!/usr/bin/env bash
# Microphone input switcher: cycle through the available audio sources.
# Skips monitors, video sources and sources whose active port is unplugged
# (e.g. the jack mic with nothing connected).

# name<TAB>description for every usable source, in pactl order
mapfile -t ENTRIES < <(
  pactl list sources | awk '
    function flush() {
      if (name != "" && name !~ /\.monitor$/ && name !~ /^v4l2_/ && !(port in down))
        print name "\t" desc
      name = ""
    }
    /^Source #/           { flush(); desc = ""; port = ""; delete down }
    /^\tName: /           { name = $2 }
    /^\tDescription: /    { desc = $0; sub(/^\tDescription: /, "", desc) }
    # Ports are listed before "Active Port"; remember the unplugged ones
    /^\t\t\[.*not available\)$/ { p = $0; sub(/^\t\t/, "", p); sub(/:.*/, "", p); down[p] = 1 }
    /^\tActive Port: /    { port = $0; sub(/^\tActive Port: /, "", port) }
    END                   { flush() }
  '
)

COUNT=${#ENTRIES[@]}
if [ "$COUNT" -eq 0 ]; then
  notify-send -u critical "Mic Switch" "No microphone sources found" -i dialog-error
  exit 1
fi
if [ "$COUNT" -lt 2 ]; then
  notify-send "Mic Switch" "Only one microphone available" -i audio-input-microphone
  exit 0
fi

CURRENT=$(pactl get-default-source)
NEXT_IDX=0
for i in "${!ENTRIES[@]}"; do
  if [ "${ENTRIES[$i]%%$'\t'*}" = "$CURRENT" ]; then
    NEXT_IDX=$(( (i + 1) % COUNT ))
    break
  fi
done

NEXT_NAME="${ENTRIES[$NEXT_IDX]%%$'\t'*}"
NEXT_DESC="${ENTRIES[$NEXT_IDX]#*$'\t'}"
pactl set-default-source "$NEXT_NAME"
notify-send "Mic Switch" "Input: ${NEXT_DESC:-$NEXT_NAME}" -i audio-input-microphone
