#!/usr/bin/env bash
# USB disk monitor with Pango markup tooltip

source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_ACCENT="#d4c080"; C_GREEN="#90c090"; }

pango_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

json_output() {
  local class="${3:-empty}"
  local tooltip="${2//\\n/$'\n'}"
  jq -cn --arg text "$1" --arg tooltip "$tooltip" --arg class "$class" '{text: $text, tooltip: $tooltip, class: $class}'
}

mapfile -t devices < <(
  lsblk -J -p -o NAME,TYPE,TRAN,SIZE,MOUNTPOINT,LABEL,FSTYPE 2>/dev/null |
    jq -r '
      .blockdevices[]
      | select(.type == "disk" and .tran == "usb")
      | (.children // [])[]
      | select(.type == "part")
      | [.name, .size, (.mountpoint // ""), (.label // ""), (.fstype // "")]
      | @tsv
    ' 2>/dev/null
)

if [ "${#devices[@]}" -eq 0 ]; then
  json_output "" "No USB disks" "empty"
  exit 0
fi

count=${#devices[@]}

tooltip="<span color='$C_ACCENT'><b>󰕓 USB DISKS ($count)</b></span>\n"

for line in "${devices[@]}"; do
  IFS=$'\t' read -r name size mount label fstype <<< "$line"
  dev=$(basename -- "$name")
  mount_raw="$mount"

  [ -z "$label" ] && label="$dev"

  label=$(pango_escape "$label")
  mount=$(pango_escape "$mount")
  fstype=$(pango_escape "$fstype")
  size=$(pango_escape "$size")

  if [ -n "$mount_raw" ]; then
    usage=$(df -h -- "$mount_raw" 2>/dev/null | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')
    usage=$(pango_escape "$usage")
    tooltip="$tooltip\n<span color='$C_GREEN'>●</span> <span color='$C_FG'><b>$label</b></span> <span color='$C_DIM'>$size $fstype</span>"
    tooltip="$tooltip\n  <span color='$C_DIM'>$mount</span>"
    [ -n "$usage" ] && tooltip="$tooltip\n  <span color='$C_DIM'>Used:</span> <span color='$C_FG'>$usage</span>"
  else
    tooltip="$tooltip\n<span color='$C_DIM'>○ $label  $size $fstype (not mounted)</span>"
  fi
done

tooltip="$tooltip\n\n<span color='$C_DIM'>Left: Open │ Right: Safe eject</span>"

json_output "󰕓 $count" "$tooltip" "attached"
