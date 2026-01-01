#!/usr/bin/env bash
# Mako Notifications Counter

# Count notifications in history
notif_count=$(makoctl history | jq '.data[0] | length' 2>/dev/null || echo "0")

if [ "$notif_count" -gt 0 ]; then
  # Get last few notifications
  recent=$(makoctl history | jq -r '.data[0][:3] | .[] | "\(.app_name.data): \(.summary.data)"' 2>/dev/null)

  tooltip="┌─ 󰂚 NOTIFICATIONS ─────┐"
  tooltip="$tooltip\n│ Unread: $notif_count"
  tooltip="$tooltip\n│"

  if [ -n "$recent" ]; then
    while IFS= read -r notif; do
      # Truncate long notifications
      truncated=$(echo "$notif" | cut -c1-35)
      tooltip="$tooltip\n│ • $truncated"
    done <<< "$recent"
  fi

  tooltip="$tooltip\n└───────────────────────┘"
  tooltip="$tooltip\n\nClick: invoke | Right: dismiss all"

  echo "{\"text\": \"󰂚 $notif_count\", \"tooltip\": \"$tooltip\", \"class\": \"notification\"}"
else
  echo "{\"text\": \"\", \"tooltip\": \"No notifications\", \"class\": \"empty\"}"
fi
