#!/usr/bin/env bash
# List removable USB/external disks and allow ejecting

# Get list of USB disk devices (parent devices)
usb_disks=$(lsblk -nrpo "name,type,tran" | awk '$2=="disk" && $3=="usb" {print $1}')

# Get all partitions from USB disks (both removable and external HDDs)
devices=""
for disk in $usb_disks; do
  partitions=$(lsblk -nrpo "name,type,size,mountpoint,label" "$disk" | awk '$2=="part" {print $0}')
  if [ -n "$partitions" ]; then
    devices="$devices$partitions"$'\n'
  fi
done

# Remove trailing newline
devices=$(echo "$devices" | sed '/^$/d')

if [ -z "$devices" ]; then
  echo '{"text": "", "tooltip": "No USB disks"}'
  exit 0
fi

# Count mounted devices
count=$(echo "$devices" | wc -l)

# Build tooltip with device list
tooltip="USB Disks ($count):\n"
while IFS= read -r line; do
  name=$(echo "$line" | awk '{print $1}')
  size=$(echo "$line" | awk '{print $3}')
  mount=$(echo "$line" | awk '{print $4}')
  label=$(echo "$line" | awk '{print $5}')

  if [ -n "$mount" ] && [ "$mount" != "" ]; then
    tooltip="$tooltip\n● $(basename $name) - $size - $label"
    tooltip="$tooltip\n  Mounted: $mount"
  else
    tooltip="$tooltip\n○ $(basename $name) - $size - $label (not mounted)"
  fi
done <<< "$devices"

tooltip="$tooltip\n\nClick to open file manager"

echo "{\"text\": \"󰋊 $count\", \"tooltip\": \"$tooltip\"}"
