#!/usr/bin/env bash
# Systemd Failed Services Monitor

# Count failed services
failed_count=$(systemctl --failed --no-legend --no-pager | wc -l)

if [ "$failed_count" -gt 0 ]; then
  # Get list of failed services
  failed_list=$(systemctl --failed --no-legend --no-pager | awk '{print $1}')

  tooltip="┌─ 󰀨 FAILED SERVICES ───┐"
  tooltip="$tooltip\n│ Count: $failed_count"
  tooltip="$tooltip\n│"
  while IFS= read -r service; do
    tooltip="$tooltip\n│ • $service"
  done <<< "$failed_list"
  tooltip="$tooltip\n└───────────────────────┘"
  tooltip="$tooltip\n\nClick to view details"

  echo "{\"text\": \"󰀨 $failed_count\", \"tooltip\": \"$tooltip\", \"class\": \"warning\"}"
else
  echo "{\"text\": \"\", \"tooltip\": \"󰄬 No failed services\", \"class\": \"ok\"}"
fi
