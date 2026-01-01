#!/usr/bin/env bash
# VPN Status Monitor: Detects any VPN connection (WireGuard, OpenVPN, etc.)

# Method 1: Check for VPN/WireGuard/tun interfaces directly (most reliable)
vpn_interface=""
vpn_name=""

# Check for common VPN interface patterns using ip link (includes WireGuard interfaces)
for iface in $(ip link show 2>/dev/null | grep -E "^[0-9]+: (wg|tun|proton|vpn|nordlynx)" | awk -F': ' '{print $2}' || true); do
  # Verify interface has an IP
  if ip addr show "$iface" 2>/dev/null | grep -q "inet "; then
    vpn_interface="$iface"
    break
  fi
done

# Method 2: Check NetworkManager for WireGuard devices (nmcli device shows wireguard type)
if [ -z "$vpn_interface" ]; then
  wg_device=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | grep ":wireguard$" | cut -d: -f1 | head -1 || true)
  if [ -n "$wg_device" ]; then
    # Verify interface has an IP
    if ip addr show "$wg_device" 2>/dev/null | grep -q "inet "; then
      vpn_interface="$wg_device"
    fi
  fi
fi

# Method 3: Check NetworkManager for VPN connections (wireguard, vpn, tun types)
if [ -z "$vpn_interface" ]; then
  vpn_line=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active | grep -iE "(wireguard|vpn|tun|proton)" | head -1 || true)
  if [ -n "$vpn_line" ]; then
    vpn_name=$(echo "$vpn_line" | cut -d: -f1)
    vpn_interface=$(echo "$vpn_line" | cut -d: -f3)
    # Verify interface has an IP
    if ! ip addr show "$vpn_interface" 2>/dev/null | grep -q "inet "; then
      vpn_interface=""
    fi
  fi
fi

# Method 4: Check for any non-standard interface with a private IP (10.x, 172.16-31.x, or Proton's ranges)
if [ -z "$vpn_interface" ]; then
  for iface in $(ip -o addr show | grep -E "inet (10\.|172\.(1[6-9]|2[0-9]|3[01])\.|100\.)" | awk '{print $2}' | grep -vE "^(docker|br-|veth|lo)" || true); do
    # Skip known non-VPN interfaces
    if [[ ! "$iface" =~ ^(wlp|enp|eth|wlan) ]]; then
      vpn_interface="$iface"
      break
    fi
  done
fi

# Set device variable for compatibility with rest of script
device="$vpn_interface"
vpn_line="$vpn_interface"

if [ -n "$vpn_interface" ]; then
  # VPN is connected

  # Get local VPN IP address
  local_ip=$(ip addr show "$device" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

  # Try to get connection name from NetworkManager if not already set
  if [ -z "$vpn_name" ]; then
    vpn_name=$(nmcli -t -f NAME,DEVICE connection show --active | grep ":$device$" | cut -d: -f1 || echo "$device")
  fi
  [ -z "$vpn_name" ] && vpn_name="$device"

  # Try to extract country from interface name or connection name
  # Proton VPN formats: "protonvpn-PT-12", "ProtonVPN CH-123", "wg-nl-123"
  country=$(echo "$vpn_name $device" | grep -oE '[^a-zA-Z]([A-Z]{2})[^a-zA-Z]' | grep -oE '[A-Z]{2}' | head -1 || true)
  [ -z "$country" ] && country="VPN"

  # Determine VPN type from interface name
  if [[ "$device" == wg* ]] || [[ "$device" == proton* ]]; then
    vpn_type="WireGuard"
  elif [[ "$device" == tun* ]]; then
    vpn_type="OpenVPN"
  else
    vpn_type="VPN"
  fi

  # Get VPN gateway from routing table
  gateway=$(ip route | grep "dev $device" | grep -v "src" | awk '{print $1}' | head -1 || echo "N/A")
  [ "$gateway" = "default" ] && gateway=$(ip route | grep "dev $device" | awk '/via/ {print $3}' | head -1 || echo "N/A")

  # Get public IP (with timeout to avoid hanging)
  public_ip=$(curl -s --max-time 3 https://icanhazip.com 2>/dev/null | tr -d '[:space:]' || echo "N/A")

  # Get DNS servers from resolv.conf
  dns_servers=$(grep "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//' || echo "N/A")

  # Get interface uptime from /sys
  uptime="N/A"
  if [ -f "/sys/class/net/$device/statistics/tx_bytes" ]; then
    # Interface exists, try to get creation time
    iface_time=$(stat -c %Y "/sys/class/net/$device" 2>/dev/null || echo "0")
    if [ "$iface_time" != "0" ]; then
      current_time=$(date +%s)
      uptime_sec=$((current_time - iface_time))
      if [ $uptime_sec -lt 60 ]; then
        uptime="${uptime_sec}s"
      elif [ $uptime_sec -lt 3600 ]; then
        uptime="$((uptime_sec / 60))m"
      else
        uptime="$((uptime_sec / 3600))h $((uptime_sec % 3600 / 60))m"
      fi
    fi
  fi

  # Build detailed tooltip
  tooltip="┌─ 󰖂 VPN CONNECTED ─────"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ 🌍 Location: $country"
  tooltip="$tooltip\n│ 📡 Server:   $vpn_name"
  tooltip="$tooltip\n│ 🔒 Protocol: $vpn_type"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ 🖧  Device:   $device"
  tooltip="$tooltip\n│ 🏠 Local IP: $local_ip"
  tooltip="$tooltip\n│ 🌐 Public IP: $public_ip"
  if [ "$gateway" != "N/A" ] && [ -n "$gateway" ]; then
    tooltip="$tooltip\n│ 🚪 Gateway:  $gateway"
  fi
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ 🕐 Uptime:   $uptime"
  if [ "$dns_servers" != "N/A" ] && [ -n "$dns_servers" ]; then
    tooltip="$tooltip\n│ 🔍 DNS:      $dns_servers"
  fi
  tooltip="$tooltip\n└────────────────────────"
  tooltip="$tooltip\n\nClick to open Proton VPN"

  echo "{\"text\": \"󰖂 $country\", \"tooltip\": \"$tooltip\", \"class\": \"connected\"}"
else
  # VPN is disconnected - show local network info
  tooltip="┌─ 󰿆 VPN DISCONNECTED ──"
  tooltip="$tooltip\n│"
  tooltip="$tooltip\n│ ⚠️  Not protected by VPN"
  tooltip="$tooltip\n│"

  # Get active network interface (WiFi or Ethernet)
  active_conn=$(nmcli -t -f NAME,TYPE,DEVICE connection show --active | grep -E "wireless|ethernet" | head -1 || true)

  if [ -n "$active_conn" ]; then
    conn_name=$(echo "$active_conn" | cut -d: -f1)
    conn_type=$(echo "$active_conn" | cut -d: -f2)
    conn_device=$(echo "$active_conn" | cut -d: -f3)

    # Get local IP
    local_ip=$(ip addr show "$conn_device" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

    # Get gateway
    gateway=$(ip route | grep default | awk '{print $3}' | head -1 || echo "N/A")

    # Get DNS servers (read from /etc/resolv.conf since systemd-resolved is disabled)
    dns_servers=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//' || echo "N/A")

    # Connection type icon
    if [ "$conn_type" = "wireless" ] || [ "$conn_type" = "802-11-wireless" ]; then
      conn_icon="📶 WiFi"
    else
      conn_icon="🔌 Ethernet"
    fi

    # Get public IP (with timeout) - Using Cloudflare for privacy
    public_ip=$(curl -s --max-time 3 https://icanhazip.com 2>/dev/null || echo "N/A")

    tooltip="$tooltip\n│ $conn_icon: $conn_name"
    tooltip="$tooltip\n│ 🖧  Device:   $conn_device"
    tooltip="$tooltip\n│ 🏠 Local IP: $local_ip"
    tooltip="$tooltip\n│ 🚪 Gateway:  $gateway"
    tooltip="$tooltip\n│ 🔍 DNS:      $dns_servers"
    tooltip="$tooltip\n│"
    tooltip="$tooltip\n│ 🌐 Public IP: $public_ip"
  else
    tooltip="$tooltip\n│ No active connection"
  fi

  tooltip="$tooltip\n└────────────────────────"
  tooltip="$tooltip\n\n⚠️  Connect VPN for privacy"
  tooltip="$tooltip\n\nClick to open Proton VPN"
  echo "{\"text\": \"󰿆\", \"tooltip\": \"$tooltip\", \"class\": \"disconnected\"}"
fi
