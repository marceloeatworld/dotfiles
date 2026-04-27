# WireGuard VPN management (Proton VPN via native WireGuard)
# Configs auto-imported from ~/dotfiles/vpn/*.conf into NetworkManager
# DNS switching handled automatically by vpn-dns-switch.nix dispatcher
#
# Add new countries: drop a .conf file in ~/dotfiles/vpn/ and run "vpn import"
# Naming convention: <country>-<CODE>-<number>.conf → proton-<code>
# Example: japan-JP-42.conf → connection "proton-jp", shortcut "vpn jp"
{ pkgs, ... }:

let
  vpn-script = pkgs.writeShellScriptBin "vpn" ''
    # VPN Manager - Auto-discovers WireGuard configs from ~/dotfiles/vpn/
    # Usage: vpn [<country-code>|off|status|import|list]

    PATH=${pkgs.networkmanager}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:$PATH

    VPN_DIR="$HOME/dotfiles/vpn"
    DEFAULT_COUNTRY="pt"

    # Extract country code from filename: france-FR-529.conf → fr
    get_country_code() {
      local filename
      filename=$(basename "$1" .conf)
      echo "$filename" | ${pkgs.gnused}/bin/sed -n 's/.*-\([A-Z]\{2\}\)-.*/\1/p' | tr '[:upper:]' '[:lower:]'
    }

    # Get connection name for a country code: fr → proton-fr
    conn_name() {
      echo "proton-$1"
    }

    # List available configs from ~/dotfiles/vpn/
    list_configs() {
      for conf in "$VPN_DIR"/*.conf; do
        [ -f "$conf" ] || continue
        local code
        code=$(get_country_code "$conf")
        [ -z "$code" ] && continue
        local name
        name=$(conn_name "$code")
        local country
        country=$(basename "$conf" .conf | cut -d- -f1)
        # Check if imported
        local status="not imported"
        if nmcli -t -f NAME connection show 2>/dev/null | grep -q "^$name$"; then
          status="imported"
        fi
        # Check if active
        local active
        active=$(get_active_vpn)
        if [ "$active" = "$name" ]; then
          status="connected"
        fi
        printf "  %-4s %-12s %s\n" "$code" "$country" "($status)"
      done
    }

    # Get currently active VPN connection
    get_active_vpn() {
      nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep ":wireguard$" | cut -d: -f1 | head -1
    }

    # Import all WireGuard configs from vpn/ directory
    import_configs() {
      echo "Importing VPN configs from $VPN_DIR..."
      local count=0
      for conf in "$VPN_DIR"/*.conf; do
        [ -f "$conf" ] || continue
        local code
        code=$(get_country_code "$conf")
        if [ -z "$code" ]; then
          echo "  $(basename "$conf"): skipped (can't extract country code)"
          continue
        fi
        local name
        name=$(conn_name "$code")

        # Skip if already imported
        if nmcli -t -f NAME connection show 2>/dev/null | grep -q "^$name$"; then
          echo "  $name: already imported"
          continue
        fi

        # Import into NetworkManager
        local filename
        filename=$(basename "$conf" .conf)
        if nmcli connection import type wireguard file "$conf" 2>/dev/null; then
          # Rename to proton-<code>
          nmcli connection modify "$filename" connection.id "$name" 2>/dev/null || true
          # Manual switching only (no autoconnect)
          nmcli connection modify "$name" connection.autoconnect no 2>/dev/null || true
          # Interface name must start with "proton" for vpn-dns-switch dispatcher
          nmcli connection modify "$name" connection.interface-name "$name" 2>/dev/null || true
          echo "  $name: imported"
          count=$((count + 1))
        else
          echo "  $name: import failed"
        fi
      done
      echo "Done ($count new)."
    }

    # Find config file for a country code
    find_config() {
      local code
      code=$(echo "$1" | tr '[:lower:]' '[:upper:]')
      for conf in "$VPN_DIR"/*.conf; do
        [ -f "$conf" ] || continue
        if echo "$conf" | grep -q "\-$code-"; then
          echo "$conf"
          return 0
        fi
      done
      return 1
    }

    # Check if a country code is valid
    is_valid_country() {
      find_config "$1" >/dev/null 2>&1
    }

    # Connect to a server
    connect() {
      local code="$1"
      local name
      name=$(conn_name "$code")

      # Check config exists
      if ! is_valid_country "$code"; then
        echo "No config for '$code'. Available:"
        list_configs
        return 1
      fi

      # Auto-import if not yet imported
      if ! nmcli -t -f NAME connection show 2>/dev/null | grep -q "^$name$"; then
        import_configs
      fi

      # Disconnect any active VPN first
      local active
      active=$(get_active_vpn)
      if [ -n "$active" ]; then
        if [ "$active" = "$name" ]; then
          echo "Already connected to $name"
          return 0
        fi
        nmcli connection down "$active" 2>/dev/null || true
        sleep 1
      fi

      echo "Connecting to $name..."
      if nmcli connection up "$name" 2>/dev/null; then
        echo "Connected to $name"
      else
        echo "Failed to connect to $name"
        return 1
      fi
    }

    # Remove all proton-* connections from NetworkManager and reimport
    reset_configs() {
      echo "Removing all VPN connections from NetworkManager..."
      # Disconnect first
      local active
      active=$(get_active_vpn)
      [ -n "$active" ] && nmcli connection down "$active" 2>/dev/null || true

      # Delete all proton-* connections
      for name in $(nmcli -t -f NAME connection show 2>/dev/null | grep "^proton-"); do
        nmcli connection delete "$name" 2>/dev/null
        echo "  $name: removed"
      done

      echo ""
      import_configs
    }

    # Disconnect VPN
    disconnect() {
      local active
      active=$(get_active_vpn)
      if [ -n "$active" ]; then
        nmcli connection down "$active" 2>/dev/null
        echo "Disconnected from $active"
      else
        echo "No VPN active"
      fi
    }

    # Show status
    show_status() {
      local active
      active=$(get_active_vpn)
      if [ -n "$active" ]; then
        echo "VPN: $active (connected)"
        local device
        device=$(nmcli -t -f NAME,DEVICE connection show --active 2>/dev/null | grep "^$active:" | cut -d: -f2)
        if [ -n "$device" ]; then
          local ip
          ip=$(ip addr show "$device" 2>/dev/null | grep "inet " | ${pkgs.gawk}/bin/awk '{print $2}' | cut -d'/' -f1)
          echo "  IP: $ip"
        fi
      else
        echo "VPN: disconnected"
      fi
    }

    # Main
    case "''${1:-}" in
      off|down|disconnect)
        disconnect
        ;;
      status|s)
        show_status
        ;;
      import)
        import_configs
        ;;
      reset)
        reset_configs
        ;;
      list|ls|l)
        echo "Available VPN servers:"
        list_configs
        ;;
      help|-h|--help)
        echo "VPN Manager - auto-discovers configs from ~/dotfiles/vpn/"
        echo ""
        echo "Usage: vpn [<country>|off|status|import|list]"
        echo ""
        echo "  vpn              Toggle VPN (default: $DEFAULT_COUNTRY)"
        echo "  vpn <code>       Connect to country (e.g. pt, fr, us, lt)"
        echo "  vpn off          Disconnect"
        echo "  vpn status       Show current status"
        echo "  vpn list         List available servers"
        echo "  vpn import       Import new configs from ~/dotfiles/vpn/"
        echo "  vpn reset        Remove all and reimport (after new keys)"
        echo ""
        echo "Add countries: drop a .conf in ~/dotfiles/vpn/"
        echo "  Format: <country>-<CODE>-<number>.conf"
        echo "  Example: japan-JP-42.conf → vpn jp"
        ;;
      "")
        # Toggle: connected → disconnect, disconnected → connect default
        active=$(get_active_vpn)
        if [ -n "$active" ]; then
          disconnect
        else
          connect "$DEFAULT_COUNTRY"
        fi
        ;;
      *)
        # Try as country code
        connect "$1"
        ;;
    esac
  '';
in
{
  home.packages = [ vpn-script ];
}
