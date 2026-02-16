#!/usr/bin/env bash
# Microphone input switcher: cycle through available audio sources
# Skips video sources (webcam etc.)

# Get all audio source IDs (skip video sources and filters)
SOURCES=$(wpctl status | sed -n '/^Audio/,/^Video/p' | sed -n '/Sources:/,/Filters:/p' | grep -oP '^\s+\*?\s+\K\d+')

if [ -z "$SOURCES" ]; then
  notify-send -u critical "Mic Switch" "No microphone sources found" -i dialog-error
  exit 1
fi

# Get current default source ID
CURRENT=$(wpctl status | sed -n '/^Audio/,/^Video/p' | sed -n '/Sources:/,/Filters:/p' | grep '^\s\+\*' | grep -oP '^\s+\*\s+\K\d+')

# Build array of source IDs
IDS=()
while read -r id; do
  IDS+=("$id")
done <<< "$SOURCES"

COUNT=${#IDS[@]}
if [ "$COUNT" -lt 1 ]; then
  notify-send "Mic Switch" "Only one microphone available" -i audio-input-microphone
  exit 0
fi

# Find current index and switch to next
NEXT_IDX=0
for i in "${!IDS[@]}"; do
  if [ "${IDS[$i]}" = "$CURRENT" ]; then
    NEXT_IDX=$(( (i + 1) % COUNT ))
    break
  fi
done

NEXT_ID="${IDS[$NEXT_IDX]}"
wpctl set-default "$NEXT_ID"

# Get the name of the new source
NEXT_NAME=$(wpctl inspect "$NEXT_ID" 2>/dev/null | grep 'node.description' | sed 's/.*= "\(.*\)"/\1/')
[ -z "$NEXT_NAME" ] && NEXT_NAME=$(wpctl inspect "$NEXT_ID" 2>/dev/null | grep 'node.nick' | sed 's/.*= "\(.*\)"/\1/')
[ -z "$NEXT_NAME" ] && NEXT_NAME="Source $NEXT_ID"

notify-send "Mic Switch" "Input: $NEXT_NAME" -i audio-input-microphone
