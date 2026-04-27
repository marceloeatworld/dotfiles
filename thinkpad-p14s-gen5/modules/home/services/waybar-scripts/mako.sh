#!/usr/bin/env bash
# Mako Notifications Counter with Pango markup tooltip

source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_ACCENT="#d4c080"; }

pango_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

json_output() {
  local tooltip="${2//\\n/$'\n'}"
  jq -cn \
    --arg text "$1" \
    --arg tooltip "$tooltip" \
    --arg class "$3" \
    '{text: $text, tooltip: $tooltip, class: $class}'
}

notif_data=$(makoctl history 2>/dev/null)
notif_count=$(echo "$notif_data" | jq '(.data[0] // []) | length' 2>/dev/null || echo "0")
notif_count=${notif_count:-0}

if [ "$notif_count" -gt 0 ]; then
  tooltip="<span color='$C_ACCENT'><b>󰂚 NOTIFICATIONS ($notif_count)</b></span>\n"

  # Group by app name and show count + last message
  mapfile -t apps < <(
    echo "$notif_data" |
      jq -r '
        (.data[0] // [])[0:10]
        | group_by(.app_name.data // "Unknown")[]
        | [length, (.[0].app_name.data // "Unknown")]
        | @tsv
      ' 2>/dev/null |
      sort -rn
  )

  for entry in "${apps[@]}"; do
    IFS=$'\t' read -r count app <<< "$entry"
    [ -z "$app" ] && continue
    last_msg=$(echo "$notif_data" | jq -r --arg app "$app" '.data[0][] | select(.app_name.data == $app) | .summary.data' 2>/dev/null | head -1)
    last_msg=$(pango_escape "$(echo "$last_msg" | cut -c1-40)")
    app=$(pango_escape "$app")

    if [ "$count" -gt 1 ]; then
      tooltip="$tooltip\n<span color='$C_FG'><b>$app</b></span> <span color='$C_DIM'>($count)</span>"
    else
      tooltip="$tooltip\n<span color='$C_FG'><b>$app</b></span>"
    fi
    [ -n "$last_msg" ] && tooltip="$tooltip\n<span color='$C_DIM'>  $last_msg</span>"
  done

  tooltip="$tooltip\n\n<span color='$C_DIM'>Left: invoke │ Right: dismiss all</span>"

  json_output "󰂚 $notif_count" "$tooltip" "notification"
else
  json_output "" "No notifications" "empty"
fi
