#!/usr/bin/env bash
# VPN Status Monitor: Detects any VPN connection (WireGuard, OpenVPN, etc.)
# Optimized: Public IP fetched in background, cached for 60s
# Shows country flag emoji + latency in bar

PUBLIC_IP_CACHE="$HOME/.cache/vpn-public-ip"
VPN_STATE_CACHE="$HOME/.cache/vpn-state"
PUBLIC_IP_CACHE_DURATION=60  # seconds
mkdir -p "$(dirname "$PUBLIC_IP_CACHE")" 2>/dev/null || true

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

# Detect current VPN state first (before any caching logic)
current_vpn_state="disconnected"
for iface in $(ip link show 2>/dev/null | grep -oE "^[0-9]+: (wg|tun|proton|vpn|nordlynx)[^:@]*" | awk '{print $2}' || true); do
  if ip addr show "$iface" 2>/dev/null | grep -q "inet "; then
    current_vpn_state="connected"
    break
  fi
done

# Check if VPN state changed - if so, invalidate IP cache
previous_state=$(cat "$VPN_STATE_CACHE" 2>/dev/null || echo "unknown")
if [ "$current_vpn_state" != "$previous_state" ]; then
  rm -f "$PUBLIC_IP_CACHE" 2>/dev/null
  { printf '%s\n' "$current_vpn_state" > "$VPN_STATE_CACHE"; } 2>/dev/null || true
fi

# Function to get cached public IP or fetch in background
get_public_ip() {
  local cache_valid=false
  if [ -f "$PUBLIC_IP_CACHE" ]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$PUBLIC_IP_CACHE" 2>/dev/null || echo 0)))
    if [ "$cache_age" -lt "$PUBLIC_IP_CACHE_DURATION" ]; then
      cache_valid=true
    fi
  fi

  if $cache_valid; then
    cat "$PUBLIC_IP_CACHE"
  else
    if [ -w "$(dirname "$PUBLIC_IP_CACHE")" ]; then
      (
        tmp="${PUBLIC_IP_CACHE}.$$"
        curl -s --max-time 3 https://icanhazip.com 2>/dev/null | tr -d '[:space:]' > "$tmp"
        [ -s "$tmp" ] && mv "$tmp" "$PUBLIC_IP_CACHE" || rm -f "$tmp"
      ) &
    fi
    if [ -f "$PUBLIC_IP_CACHE" ]; then
      cat "$PUBLIC_IP_CACHE"
    else
      echo "..."
    fi
  fi
}

# Country code → flag emoji
country_to_flag() {
  local code=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  if [ ${#code} -eq 2 ]; then
    local c1=$(printf '%d' "'${code:0:1}")
    local c2=$(printf '%d' "'${code:1:1}")
    printf "\U$(printf '%x' $((c1 - 65 + 127462)))\U$(printf '%x' $((c2 - 65 + 127462)))"
  else
    echo "🌐"
  fi
}

# Detect VPN interface
vpn_interface=""
vpn_name=""

for iface in $(ip link show 2>/dev/null | grep -oE "^[0-9]+: (wg|tun|proton|vpn|nordlynx)[^:@]*" | awk '{print $2}' || true); do
  if ip addr show "$iface" 2>/dev/null | grep -q "inet "; then
    vpn_interface="$iface"
    break
  fi
done

if [ -z "$vpn_interface" ]; then
  wg_device=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | grep ":wireguard$" | cut -d: -f1 | head -1 || true)
  if [ -n "$wg_device" ] && ip addr show "$wg_device" 2>/dev/null | grep -q "inet "; then
    vpn_interface="$wg_device"
  fi
fi

if [ -z "$vpn_interface" ]; then
  vpn_line=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -iE "(wireguard|vpn|tun|proton)" | head -1 || true)
  if [ -n "$vpn_line" ]; then
    vpn_name=$(echo "$vpn_line" | cut -d: -f1)
    vpn_interface=$(echo "$vpn_line" | cut -d: -f3)
    if ! ip addr show "$vpn_interface" 2>/dev/null | grep -q "inet "; then
      vpn_interface=""
    fi
  fi
fi

if [ -z "$vpn_interface" ]; then
  for iface in $(ip -o addr show 2>/dev/null | grep -E "inet (10\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.)" | awk '{print $2}' | grep -vE "^(docker|br-|veth|lo)" || true); do
    if [[ ! "$iface" =~ ^(wlp|enp|eth|wlan) ]]; then
      vpn_interface="$iface"
      break
    fi
  done
fi

device="$vpn_interface"

if [ -n "$vpn_interface" ]; then
  local_ip=$(ip addr show "$device" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

  if [ -z "$vpn_name" ]; then
    vpn_name=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep ":$device$" | cut -d: -f1 || echo "$device")
  fi
  [ -z "$vpn_name" ] && vpn_name="$device"

  # Extract country code
  country=$(echo "$vpn_name $device" | grep -oE '[^a-zA-Z]([A-Z]{2})[^a-zA-Z]' | grep -oE '[A-Z]{2}' | head -1 || true)
  [ -z "$country" ] && country="VPN"
  country_lower=$(echo "$country" | tr '[:upper:]' '[:lower:]')

  # Get flag emoji
  flag=$(country_to_flag "$country")

  # VPN type
  if [[ "$device" == wg* ]] || [[ "$device" == proton* ]]; then
    vpn_type="WireGuard"
  elif [[ "$device" == tun* ]]; then
    vpn_type="OpenVPN"
  else
    vpn_type="VPN"
  fi

  # Uptime
  uptime="N/A"
  if [ -d "/sys/class/net/$device" ]; then
    iface_time=$(stat -c %Y "/sys/class/net/$device" 2>/dev/null || echo "0")
    if [ "$iface_time" != "0" ]; then
      uptime_sec=$(($(date +%s) - iface_time))
      if [ $uptime_sec -lt 60 ]; then
        uptime="${uptime_sec}s"
      elif [ $uptime_sec -lt 3600 ]; then
        uptime="$((uptime_sec / 60))m"
      else
        uptime="$((uptime_sec / 3600))h $((uptime_sec % 3600 / 60))m"
      fi
    fi
  fi

  # Latency (single ping to VPN endpoint)
  latency=$(ping -I "$device" -c1 -W2 1.1.1.1 2>/dev/null | grep -oP 'time=\K[\d.]+' || echo "N/A")
  [ "$latency" != "N/A" ] && latency="${latency}ms"

  public_ip=$(get_public_ip)

  # RX/TX bytes
  rx_bytes=$(cat /sys/class/net/$device/statistics/rx_bytes 2>/dev/null || echo 0)
  tx_bytes=$(cat /sys/class/net/$device/statistics/tx_bytes 2>/dev/null || echo 0)
  rx_mb=$(echo "scale=1; $rx_bytes / 1048576" | bc 2>/dev/null || echo "0")
  tx_mb=$(echo "scale=1; $tx_bytes / 1048576" | bc 2>/dev/null || echo "0")

  # Load theme colors
  source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_ACCENT="#d4c080"; C_GREEN="#90c090"; C_RED="#d08080"; }

  vpn_name_escaped=$(pango_escape "$vpn_name")
  device_escaped=$(pango_escape "$device")
  local_ip_escaped=$(pango_escape "$local_ip")
  public_ip_escaped=$(pango_escape "$public_ip")
  uptime_escaped=$(pango_escape "$uptime")
  latency_escaped=$(pango_escape "$latency")

  tooltip="<span color='$C_GREEN'><b>󰖂 VPN CONNECTED</b></span>\n"
  tooltip="$tooltip\n<span color='$C_DIM'>Location</span>  <span color='$C_FG'>$flag $country</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Server</span>    <span color='$C_FG'>$vpn_name_escaped</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Protocol</span>  <span color='$C_FG'>$vpn_type</span>"
  tooltip="$tooltip\n"
  tooltip="$tooltip\n<span color='$C_DIM'>Device</span>    <span color='$C_FG'>$device_escaped</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Local IP</span>  <span color='$C_FG'>$local_ip_escaped</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Public</span>    <span color='$C_FG'>$public_ip_escaped</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Uptime</span>    <span color='$C_FG'>$uptime_escaped</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Latency</span>   <span color='$C_FG'>$latency_escaped</span>"
  tooltip="$tooltip\n<span color='$C_DIM'>Traffic</span>   <span color='$C_FG'>⇣${rx_mb}MB ⇡${tx_mb}MB</span>"
  tooltip="$tooltip\n\n<span color='$C_DIM'>Left: Select country │ Right: Disconnect</span>"

  json_output "$flag $country" "$tooltip" "connected"
else
  active_conn=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -E "wireless|ethernet" | head -1 || true)

  source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_RED="#d08080"; }

  tooltip="<span color='$C_RED'><b>󰿆 VPN DISCONNECTED</b></span>\n"
  tooltip="$tooltip\n<span color='$C_RED'>Not protected</span>"

  if [ -n "$active_conn" ]; then
    conn_name=$(echo "$active_conn" | cut -d: -f1)
    conn_type=$(echo "$active_conn" | cut -d: -f2)
    conn_device=$(echo "$active_conn" | cut -d: -f3)
    local_ip=$(ip addr show "$conn_device" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

    if [ "$conn_type" = "wireless" ] || [ "$conn_type" = "802-11-wireless" ]; then
      conn_icon="WiFi"
    else
      conn_icon="Ethernet"
    fi

    public_ip=$(get_public_ip)
    conn_name_escaped=$(pango_escape "$conn_name")
    local_ip_escaped=$(pango_escape "$local_ip")
    public_ip_escaped=$(pango_escape "$public_ip")

    tooltip="$tooltip\n"
    tooltip="$tooltip\n<span color='$C_DIM'>$conn_icon</span>  <span color='$C_FG'>$conn_name_escaped</span>"
    tooltip="$tooltip\n<span color='$C_DIM'>Local</span>    <span color='$C_FG'>$local_ip_escaped</span>"
    tooltip="$tooltip\n<span color='$C_DIM'>Public</span>   <span color='$C_FG'>$public_ip_escaped</span>"
  fi

  tooltip="$tooltip\n\n<span color='$C_DIM'>Left: Select country │ Right: Disconnect</span>"

  json_output "󰿆" "$tooltip" "disconnected"
fi
