#!/usr/bin/env bash
# Cycle audio output: Auto (jack detection) → Forced Speakers → HDMI → Auto
#
# Auto:     Auto-Mute handles routing (jack → headphones, no jack → speakers)
# Speakers: Forces speakers even when jack is plugged (disables Auto-Mute)
# HDMI:     Routes audio to HDMI/DisplayPort (projector, TV, ARC)

STATE_FILE="$HOME/.config/audio-output-state"

# Auto-detect the analog sound card (find card with Speaker control)
CARD=""
for c in 0 1 2 3; do
  if amixer -c "$c" scontrols 2>/dev/null | grep -q "Speaker\|Internal Speaker"; then
    CARD="$c"
    break
  fi
done

# Get current volume for notification
VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oP 'Volume: \K[\d.]+')
VOL_PCT=$(awk "BEGIN{printf \"%.0f\", ${VOL:-0} * 100}")

# Read current state
CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "auto")

# Helper: activate HDMI profile and set as default sink
activate_hdmi() {
  # Find the HDMI/Radeon audio device ID in WirePlumber
  local HDMI_DEVICE
  HDMI_DEVICE=$(wpctl status | grep -oP '\d+(?=\.\s+Radeon High Definition Audio Controller)')

  if [ -z "$HDMI_DEVICE" ]; then
    notify-send -u critical "Audio Error" "No HDMI audio device found" -i dialog-error
    return 1
  fi

  # Activate the HiFi profile on the HDMI device
  wpctl set-profile "$HDMI_DEVICE" 1

  # Wait for the HDMI sink to appear
  local HDMI_SINK=""
  for i in $(seq 1 10); do
    HDMI_SINK=$(wpctl status | grep -oP '\d+(?=\.\s+Radeon High Definition Audio Controller.*)')
    # Filter: we need the sink, not the device — look in the Sinks section
    HDMI_SINK=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -oP '\d+(?=\.\s+Radeon)')
    [ -n "$HDMI_SINK" ] && break
    sleep 0.5
  done

  if [ -z "$HDMI_SINK" ]; then
    notify-send -u warning "HDMI Audio" "HDMI sink not available.\nIs a display connected?" -i dialog-warning
    return 1
  fi

  wpctl set-default "$HDMI_SINK"
  return 0
}

# Helper: deactivate HDMI and switch back to analog
deactivate_hdmi() {
  # Turn off HDMI audio profile
  local HDMI_DEVICE
  HDMI_DEVICE=$(wpctl status | grep -oP '\d+(?=\.\s+Radeon High Definition Audio Controller)')
  [ -n "$HDMI_DEVICE" ] && wpctl set-profile "$HDMI_DEVICE" 0

  # Set Ryzen HD Audio (analog) as default
  local ANALOG_SINK
  ANALOG_SINK=$(wpctl status | sed -n '/Sinks:/,/Sources:/p' | grep -oP '\d+(?=\.\s+Ryzen HD Audio)')
  [ -n "$ANALOG_SINK" ] && wpctl set-default "$ANALOG_SINK"
}

case "$CURRENT_STATE" in
  auto)
    # Switch to forced speakers mode
    echo "speakers" > "$STATE_FILE"

    deactivate_hdmi

    if [ -n "$CARD" ]; then
      amixer -c "$CARD" sset "Auto-Mute Mode" "Disabled" 2>/dev/null
      amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
      amixer -c "$CARD" sset "Internal Speaker" unmute 2>/dev/null
      amixer -c "$CARD" sset "Master" unmute 2>/dev/null
    fi

    notify-send "Audio Output" "󰓃 Forced: Speakers (${VOL_PCT}%)" -i audio-speakers
    ;;

  speakers)
    # Switch to HDMI mode
    if [ -n "$CARD" ]; then
      # Re-enable auto-mute before switching away
      amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null
      amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
      amixer -c "$CARD" sset "Master" unmute 2>/dev/null
    fi

    if activate_hdmi; then
      echo "hdmi" > "$STATE_FILE"
      notify-send "Audio Output" "󰡁 HDMI / DisplayPort (${VOL_PCT}%)" -i audio-card
    else
      # HDMI failed, go back to auto
      echo "auto" > "$STATE_FILE"
      deactivate_hdmi
      notify-send "Audio Output" "󰋋 Auto: Speaker/Headphone (${VOL_PCT}%)" -i audio-speakers
    fi
    ;;

  hdmi)
    # Switch back to auto mode
    echo "auto" > "$STATE_FILE"

    deactivate_hdmi

    if [ -n "$CARD" ]; then
      amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null
      amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
      amixer -c "$CARD" sset "Master" unmute 2>/dev/null
    fi

    notify-send "Audio Output" "󰋋 Auto: Speaker/Headphone (${VOL_PCT}%)" -i audio-speakers
    ;;

  *)
    # Unknown state, reset to auto
    echo "auto" > "$STATE_FILE"
    deactivate_hdmi

    if [ -n "$CARD" ]; then
      amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null
      amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
      amixer -c "$CARD" sset "Master" unmute 2>/dev/null
    fi

    notify-send "Audio Output" "󰋋 Auto: Speaker/Headphone (${VOL_PCT}%)" -i audio-speakers
    ;;
esac

# Signal Waybar to refresh the audio-status widget
pkill -RTMIN+10 waybar 2>/dev/null
