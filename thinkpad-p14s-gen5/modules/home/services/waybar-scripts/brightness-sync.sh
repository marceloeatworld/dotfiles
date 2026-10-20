#!/usr/bin/env bash
# Brightness for the laptop panel + external monitor (DDC/CI).
#   raise|lower   -> swayosd-client (changes laptop backlight + shows OSD), used by Hyprland keys
#   5%+|5%-|50%   -> brightnessctl direct, used by waybar scroll/right-click
# Every call then mirrors the laptop level to every external screen with ddcutil,
# debounced in the background so a held key produces a single slow i2c write
# per monitor.

ACTION="$1"
if [ -z "$ACTION" ]; then
  echo "Usage: brightness-sync <raise|lower|5%+|5%-|50%>"
  exit 1
fi

case "$ACTION" in
  raise) swayosd-client --brightness raise ;;
  lower) swayosd-client --brightness lower ;;
  *)     brightnessctl set "$ACTION" > /dev/null ;;
esac

# Mirror to the external monitor in the background, one instance at a time.
(
  exec 9>"${XDG_RUNTIME_DIR:-/tmp}/brightness-sync.lock"
  flock -n 9 || exit 0

  # External = any active monitor besides the laptop panel. hyprctl is
  # instant, unlike ddcutil detect (seconds), so no detection cache needed.
  hyprctl monitors -j | jq -e '.[] | select(.name != "eDP-1")' > /dev/null || exit 0

  # I2C bus of every valid DDC display ("Display N" blocks only, the laptop
  # panel shows up as "Invalid display"). Targeting --bus skips re-detection
  # on each write; a bare setvcp would only reach the first display.
  buses=$(ddcutil --syslog NEVER detect --brief 2>/dev/null \
    | awk '/^Display/ {ok=1} /^Invalid/ {ok=0} ok && /I2C bus:/ {sub(".*/dev/i2c-", ""); print}')
  [ -n "$buses" ] || exit 0

  laptop_pct() {
    echo $(( $(brightnessctl get) * 100 / $(brightnessctl max) ))
  }

  while :; do
    # Wait for the value to settle (key repeat / scroll bursts).
    prev=-1
    pct=$(laptop_pct)
    while [ "$pct" != "$prev" ]; do
      prev=$pct
      sleep 0.3
      pct=$(laptop_pct)
    done

    for bus in $buses; do
      ddcutil --syslog NEVER --bus "$bus" setvcp 10 "$pct" > /dev/null 2>&1
    done

    # Value changed again while ddcutil was writing? Settle and write again.
    [ "$(laptop_pct)" = "$pct" ] && break
  done
) &
