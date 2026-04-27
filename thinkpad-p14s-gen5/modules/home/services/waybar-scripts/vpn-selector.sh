#!/usr/bin/env bash
# VPN Country Selector — wofi menu for quick country switching
# Left-click on VPN waybar module opens this

VPN_DIR="$HOME/dotfiles/vpn"

# Get current VPN state
ACTIVE=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep ":wireguard$" | cut -d: -f1 | head -1)

# Build menu entries from available configs
ENTRIES=""
for conf in "$VPN_DIR"/*.conf; do
  [ -f "$conf" ] || continue
  code=$(basename "$conf" .conf | sed -n 's/.*-\([A-Z]\{2\}\)-.*/\1/p' | tr '[:upper:]' '[:lower:]')
  [ -z "$code" ] && continue
  country=$(basename "$conf" .conf | cut -d- -f1)
  name="proton-$code"

  # Flag emoji from country code (A=🇦 regional indicators)
  upper=$(echo "$code" | tr '[:lower:]' '[:upper:]')
  c1=$(printf '%d' "'${upper:0:1}")
  c2=$(printf '%d' "'${upper:1:1}")
  flag=$(printf "\U$(printf '%x' $((c1 - 65 + 127462)))\U$(printf '%x' $((c2 - 65 + 127462)))")

  if [ "$name" = "$ACTIVE" ]; then
    ENTRIES="$ENTRIES$flag  $country ($code) [connected]\n"
  else
    ENTRIES="$ENTRIES$flag  $country ($code)\n"
  fi
done

# Add disconnect option if connected
if [ -n "$ACTIVE" ]; then
  ENTRIES="󰿆  Disconnect VPN\n$ENTRIES"
fi

# Show wofi menu
CHOSEN=$(echo -e "$ENTRIES" | sed '/^$/d' | wofi --dmenu --prompt "VPN Country" --width 300 --height 250 --cache-file /dev/null) || exit 0

# Parse selection
if echo "$CHOSEN" | grep -q "Disconnect"; then
  vpn off
  notify-send "VPN" "󰿆 Disconnected" -i network-vpn-disconnected
elif echo "$CHOSEN" | grep -q "\[connected\]"; then
  # Already connected to this one, disconnect
  vpn off
  notify-send "VPN" "󰿆 Disconnected" -i network-vpn-disconnected
else
  # Extract country code from selection
  CODE=$(echo "$CHOSEN" | grep -oP '\((\w+)\)' | tr -d '()')
  if [ -n "$CODE" ]; then
    vpn "$CODE"
  fi
fi

# Refresh waybar VPN module
pkill -RTMIN+8 waybar 2>/dev/null
