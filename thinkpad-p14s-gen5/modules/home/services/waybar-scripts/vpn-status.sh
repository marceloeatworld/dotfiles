#!/usr/bin/env bash
# VPN Status Monitor: Detects any VPN connection (WireGuard, OpenVPN, etc.)
# Optimized: Public IP fetched in background, cached for 60s

PUBLIC_IP_CACHE="$HOME/.cache/vpn-public-ip"
PUBLIC_IP_CACHE_DURATION=60  # seconds

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
    # Fetch in background and return cached/placeholder
    (curl -s --max-time 3 https://icanhazip.com 2>/dev/null | tr -d '[:space:]' > "$PUBLIC_IP_CACHE" &)
    if [ -f "$PUBLIC_IP_CACHE" ]; then
      cat "$PUBLIC_IP_CACHE"
    else
      echo "..."
    fi
  fi
}

# Method 1: Check for VPN/WireGuard/tun interfaces directly (most reliable)
vpn_interface=""
vpn_name=""

# Check for common VPN interface patterns using ip link
for iface in $(ip link show 2>/dev/null | grep -oE "^[0-9]+: (wg|tun|proton|vpn|nordlynx)[^:@]*" | awk '{print $2}' || true); do
  # Verify interface has an IP
  if ip addr show "$iface" 2>/dev/null | grep -q "inet "; then
    vpn_interface="$iface"
    break
  fi
done

# Method 2: Check NetworkManager for WireGuard devices
if [ -z "$vpn_interface" ]; then
  wg_device=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | grep ":wireguard$" | cut -d: -f1 | head -1 || true)
  if [ -n "$wg_device" ] && ip addr show "$wg_device" 2>/dev/null | grep -q "inet "; then
    vpn_interface="$wg_device"
  fi
fi

# Method 3: Check NetworkManager for VPN connections
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

# Method 4: Check for any non-standard interface with a private IP
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
  # VPN is connected
  local_ip=$(ip addr show "$device" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

  # Get connection name
  if [ -z "$vpn_name" ]; then
    vpn_name=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep ":$device$" | cut -d: -f1 || echo "$device")
  fi
  [ -z "$vpn_name" ] && vpn_name="$device"

  # Extract country from interface/connection name
  country=$(echo "$vpn_name $device" | grep -oE '[^a-zA-Z]([A-Z]{2})[^a-zA-Z]' | grep -oE '[A-Z]{2}' | head -1 || true)
  [ -z "$country" ] && country="VPN"

  # Determine VPN type
  if [[ "$device" == wg* ]] || [[ "$device" == proton* ]]; then
    vpn_type="WireGuard"
  elif [[ "$device" == tun* ]]; then
    vpn_type="OpenVPN"
  else
    vpn_type="VPN"
  fi

  # Get uptime
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

  # Get public IP (cached, non-blocking)
  public_ip=$(get_public_ip)

  # Build tooltip
  tooltip="┌─ 󰖂 VPN CONNECTED ─────"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ 🌍 Location: $country"
  tooltip="$tooltip\n│ 📡 Server:   $vpn_name"
  tooltip="$tooltip\n│ 🔒 Protocol: $vpn_type"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ 🖧  Device:   $device"
  tooltip="$tooltip\n│ 🏠 Local IP: $local_ip"
  tooltip="$tooltip\n│ 🌐 Public:   $public_ip"
  tooltip="$tooltip\n│ 🕐 Uptime:   $uptime"
  tooltip="$tooltip\n└────────────────────────"
  tooltip="$tooltip\n\nClick to open Proton VPN"

  echo "{\"text\": \"󰖂 $country\", \"tooltip\": \"$tooltip\", \"class\": \"connected\"}"
else
  # VPN is disconnected
  active_conn=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | grep -E "wireless|ethernet" | head -1 || true)

  tooltip="┌─ 󰿆 VPN DISCONNECTED ──"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ ⚠️  Not protected"

  if [ -n "$active_conn" ]; then
    conn_name=$(echo "$active_conn" | cut -d: -f1)
    conn_type=$(echo "$active_conn" | cut -d: -f2)
    conn_device=$(echo "$active_conn" | cut -d: -f3)

    local_ip=$(ip addr show "$conn_device" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

    if [ "$conn_type" = "wireless" ] || [ "$conn_type" = "802-11-wireless" ]; then
      conn_icon="📶 WiFi"
    else
      conn_icon="🔌 Ethernet"
    fi

    public_ip=$(get_public_ip)

    tooltip="$tooltip\n│"
    tooltip="$tooltip\n│ $conn_icon: $conn_name"
    tooltip="$tooltip\n│ 🏠 Local:  $local_ip"
    tooltip="$tooltip\n│ 🌐 Public: $public_ip"
  else
    tooltip="$tooltip\n│ No active connection"
  fi

  tooltip="$tooltip\n└────────────────────────"
  tooltip="$tooltip\n\n⚠️  Connect VPN for privacy"

  echo "{\"text\": \"󰿆\", \"tooltip\": \"$tooltip\", \"class\": \"disconnected\"}"
fi
