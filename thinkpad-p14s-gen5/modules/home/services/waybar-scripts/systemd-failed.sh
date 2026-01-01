#!/usr/bin/env bash
# Systemd Failed Services Monitor (both system and user services)

# Count failed services (system + user)
failed_system=$(systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l)
failed_user=$(systemctl --user --failed --no-legend --no-pager 2>/dev/null | wc -l)
failed_count=$((failed_system + failed_user))

if [ "$failed_count" -gt 0 ]; then
  tooltip="┌─ 󰀨 FAILED SERVICES ───┐"
  tooltip="$tooltip\n│ Total: $failed_count"

  # System services
  if [ "$failed_system" -gt 0 ]; then
    tooltip="$tooltip\n│"
    tooltip="$tooltip\n│ 󰒓 System ($failed_system):"
    while IFS= read -r service; do
      tooltip="$tooltip\n│   • $service"
    done < <(systemctl --failed --no-legend --no-pager | awk '{print $1}')
  fi

  # User services
  if [ "$failed_user" -gt 0 ]; then
    tooltip="$tooltip\n│"
    tooltip="$tooltip\n│ 󰀄 User ($failed_user):"
    while IFS= read -r service; do
      tooltip="$tooltip\n│   • $service"
    done < <(systemctl --user --failed --no-legend --no-pager | awk '{print $1}')
  fi

  tooltip="$tooltip\n└───────────────────────┘"
  tooltip="$tooltip\n\nClick to view details"

  echo "{\"text\": \"󰀨 $failed_count\", \"tooltip\": \"$tooltip\", \"class\": \"warning\"}"
else
  echo "{\"text\": \"\", \"tooltip\": \"󰄬 No failed services\", \"class\": \"ok\"}"
fi
