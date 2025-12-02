# Waybar - Simple colors (Ristretto theme)
{ pkgs, config, ... }:

let
  audioSwitchScript = pkgs.writeShellScriptBin "audio-switch-waybar" ''
    #!/usr/bin/env bash
    # Audio output switcher: toggle between internal speakers and headphones (jack)
    # Works even when headphones cable is NOT plugged in

    STATE_FILE="$HOME/.config/audio-output-state"

    # Read current state (0 = headphones/jack, 1 = internal speakers)
    CURRENT_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

    if [ "$CURRENT_STATE" = "0" ]; then
      # Switch to internal speakers (force unmute even with jack plugged)
      echo "1" > "$STATE_FILE"

      # Disable Auto-Mute Mode FIRST (critical for forcing speakers when jack is plugged)
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Auto-Mute Mode" "Disabled" 2>/dev/null

      # Force unmute and set volume for speakers
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Speaker" unmute 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Speaker" 100% 2>/dev/null

      # Alternative control names (some systems use these)
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Internal Speaker" unmute 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Internal Speaker" 100% 2>/dev/null

      # Also unmute Master to ensure audio flows
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Master" unmute 2>/dev/null

      ${pkgs.libnotify}/bin/notify-send "Audio Output" "Switched to Internal Speakers" -i audio-speakers
    else
      # Switch back to headphones/jack (default behavior)
      echo "0" > "$STATE_FILE"

      # Re-enable auto-mute (normal behavior - auto-switches based on jack detection)
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Auto-Mute Mode" "Enabled" 2>/dev/null

      # Mute speakers (let headphones take over when plugged in)
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Speaker" mute 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c 1 sset "Internal Speaker" mute 2>/dev/null

      ${pkgs.libnotify}/bin/notify-send "Audio Output" "Switched to Headphones/Auto (Jack)" -i audio-headphones
    fi
  '';

  removableDisksScript = pkgs.writeShellScriptBin "removable-disks-waybar" ''
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
  '';

  bitcoinScript = pkgs.writeShellScriptBin "bitcoin-waybar" ''
    #!/usr/bin/env bash
    # Bitcoin price monitor: Coinbase (price) + CoinGecko (market data)
    PATH="${pkgs.xxd}/bin:$PATH"

    # Configuration files
    ALERT_FILE="$HOME/.config/waybar/bitcoin-alerts.conf"
    LAST_PRICE_FILE="$HOME/.config/waybar/bitcoin-last-price"

    # Fetch prices from Coinbase API (reliable primary source)
    usd_response=$(${pkgs.curl}/bin/curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot" --max-time 10)
    eur_response=$(${pkgs.curl}/bin/curl -s "https://api.coinbase.com/v2/prices/BTC-EUR/spot" --max-time 10)

    if [ $? -ne 0 ] || [ -z "$usd_response" ]; then
      echo '{"text": "BTC: N/A", "tooltip": "Failed to fetch Bitcoin data"}'
      exit 0
    fi

    # Parse prices from Coinbase
    usd=$(echo "$usd_response" | ${pkgs.jq}/bin/jq -r '.data.amount // "N/A"')
    eur=$(echo "$eur_response" | ${pkgs.jq}/bin/jq -r '.data.amount // "N/A"')

    if [ "$usd" = "N/A" ] || [ "$usd" = "null" ]; then
      echo '{"text": "BTC: N/A", "tooltip": "Failed to parse Bitcoin data"}'
      exit 0
    fi

    # Fetch market data from CoinGecko (optional, with fallback)
    coingecko_data=$(${pkgs.curl}/bin/curl -s --max-time 10 "https://api.coingecko.com/api/v3/coins/bitcoin?localization=false&tickers=false&community_data=false&developer_data=false")

    # Parse CoinGecko data (with fallback to N/A if it fails)
    if [ -n "$coingecko_data" ]; then
      change_24h=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.price_change_percentage_24h // "N/A"')
      change_7d=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.price_change_percentage_7d // "N/A"')
      change_30d=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.price_change_percentage_30d // "N/A"')
      change_1y=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.price_change_percentage_1y // "N/A"')
      market_cap=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.market_cap.usd // "N/A"')
      volume_24h=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.total_volume.usd // "N/A"')
      high_24h_usd=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.high_24h.usd // "N/A"')
      high_24h_eur=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.high_24h.eur // "N/A"')
      low_24h_usd=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.low_24h.usd // "N/A"')
      low_24h_eur=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.low_24h.eur // "N/A"')
    else
      # CoinGecko failed, use N/A for market data
      change_24h="N/A"
      change_7d="N/A"
      change_30d="N/A"
      change_1y="N/A"
      market_cap="N/A"
      volume_24h="N/A"
      high_24h_usd="N/A"
      high_24h_eur="N/A"
      low_24h_usd="N/A"
      low_24h_eur="N/A"
    fi

    # Fetch Bitcoin Dominance from CoinGecko Global API
    global_data=$(${pkgs.curl}/bin/curl -s --max-time 10 "https://api.coingecko.com/api/v3/global")
    if [ -n "$global_data" ]; then
      btc_dominance=$(echo "$global_data" | ${pkgs.jq}/bin/jq -r '.data.market_cap_percentage.btc // "N/A"')
    else
      btc_dominance="N/A"
    fi

    # Check price alerts
    if [ -f "$ALERT_FILE" ]; then
      while IFS='=' read -r threshold_type threshold_value; do
        # Skip comments and empty lines
        [[ "$threshold_type" =~ ^#.*$ ]] && continue
        [[ -z "$threshold_type" ]] && continue

        case "$threshold_type" in
          above)
            if (( $(echo "$usd >= $threshold_value" | ${pkgs.bc}/bin/bc -l) )); then
              # Check if we already notified
              last_price=$(cat "$LAST_PRICE_FILE" 2>/dev/null || echo "0")
              if (( $(echo "$last_price < $threshold_value" | ${pkgs.bc}/bin/bc -l) )); then
                ${pkgs.libnotify}/bin/notify-send -u critical "Bitcoin Alert" "Price crossed above \$$threshold_value\nCurrent: \$$usd"
              fi
            fi
            ;;
          below)
            if (( $(echo "$usd <= $threshold_value" | ${pkgs.bc}/bin/bc -l) )); then
              last_price=$(cat "$LAST_PRICE_FILE" 2>/dev/null || echo "999999")
              if (( $(echo "$last_price > $threshold_value" | ${pkgs.bc}/bin/bc -l) )); then
                ${pkgs.libnotify}/bin/notify-send -u critical "Bitcoin Alert" "Price dropped below \$$threshold_value\nCurrent: \$$usd"
              fi
            fi
            ;;
        esac
      done < "$ALERT_FILE"

      # Save current price for next check
      echo "$usd" > "$LAST_PRICE_FILE"
    fi

    # Format prices
    usd_formatted=$(printf "%.0fk" $(echo "$usd / 1000" | ${pkgs.bc}/bin/bc))
    usd_full=$(printf "%'.0f" "$usd" 2>/dev/null || echo "$usd")
    eur_full=$(printf "%'.0f" "$eur" 2>/dev/null || echo "$eur")

    # Format market data
    if [ "$market_cap" != "N/A" ]; then
      market_cap_t=$(echo "scale=3; $market_cap / 1000000000000" | ${pkgs.bc}/bin/bc)
      if (( $(echo "$market_cap_t >= 1" | ${pkgs.bc}/bin/bc -l) )); then
        market_cap_formatted=$(printf "%.2fT" "$market_cap_t")
      else
        market_cap_b=$(echo "scale=2; $market_cap / 1000000000" | ${pkgs.bc}/bin/bc)
        market_cap_formatted=$(printf "%.2fB" "$market_cap_b")
      fi
    else
      market_cap_formatted="N/A"
    fi

    if [ "$volume_24h" != "N/A" ]; then
      volume_b=$(echo "scale=2; $volume_24h / 1000000000" | ${pkgs.bc}/bin/bc)
      volume_formatted=$(printf "%.2fB" "$volume_b")
    else
      volume_formatted="N/A"
    fi

    # Build tooltip with Coinbase price + CoinGecko market data
    tooltip="┌─ 🏷️ PRICE ──────────"
    tooltip="$tooltip\n│ USD  \$$usd_full"
    tooltip="$tooltip\n│ EUR  €$eur_full"
    tooltip="$tooltip\n└────"

    # Price changes (from CoinGecko)
    if [ "$change_24h" != "N/A" ] || [ "$change_7d" != "N/A" ]; then
      tooltip="$tooltip\n┌─ 📊 PERFORMANCE ─────"

      if [ "$change_24h" != "N/A" ]; then
        change_24h_fmt=$(printf "%.2f" "$change_24h")
        if (( $(echo "$change_24h >= 0" | ${pkgs.bc}/bin/bc -l) )); then
          tooltip="$tooltip\n│ 24h  🟢 +$change_24h_fmt%"
        else
          tooltip="$tooltip\n│ 24h  🔴 $change_24h_fmt%"
        fi
      fi

      if [ "$change_7d" != "N/A" ]; then
        change_7d_fmt=$(printf "%.2f" "$change_7d")
        if (( $(echo "$change_7d >= 0" | ${pkgs.bc}/bin/bc -l) )); then
          tooltip="$tooltip\n│ 7d   🟢 +$change_7d_fmt%"
        else
          tooltip="$tooltip\n│ 7d   🔴 $change_7d_fmt%"
        fi
      fi

      if [ "$change_30d" != "N/A" ]; then
        change_30d_fmt=$(printf "%.2f" "$change_30d")
        if (( $(echo "$change_30d >= 0" | ${pkgs.bc}/bin/bc -l) )); then
          tooltip="$tooltip\n│ 30d  🟢 +$change_30d_fmt%"
        else
          tooltip="$tooltip\n│ 30d  🔴 $change_30d_fmt%"
        fi
      fi

      if [ "$change_1y" != "N/A" ]; then
        change_1y_fmt=$(printf "%.2f" "$change_1y")
        if (( $(echo "$change_1y >= 0" | ${pkgs.bc}/bin/bc -l) )); then
          tooltip="$tooltip\n│ 1yr  🟢 +$change_1y_fmt%"
        else
          tooltip="$tooltip\n│ 1yr  🔴 $change_1y_fmt%"
        fi
      fi

      tooltip="$tooltip\n└────"
    fi

    # 24h range (from CoinGecko)
    if [ "$high_24h_usd" != "N/A" ] && [ "$low_24h_usd" != "N/A" ]; then
      high_24h_usd_formatted=$(printf "%'.0f" "$high_24h_usd")
      high_24h_eur_formatted=$(printf "%'.0f" "$high_24h_eur")
      low_24h_usd_formatted=$(printf "%'.0f" "$low_24h_usd")
      low_24h_eur_formatted=$(printf "%'.0f" "$low_24h_eur")

      tooltip="$tooltip\n┌─ 📈 24H RANGE ───────"
      tooltip="$tooltip\n│ High \$$high_24h_usd_formatted / €$high_24h_eur_formatted"
      tooltip="$tooltip\n│ Low  \$$low_24h_usd_formatted / €$low_24h_eur_formatted"
      tooltip="$tooltip\n└────"
    fi

    # Market data (from CoinGecko)
    if [ "$market_cap" != "N/A" ] || [ "$volume_24h" != "N/A" ]; then
      tooltip="$tooltip\n┌─ 💎 MARKET ──────────"
      tooltip="$tooltip\n│ Cap    \$$market_cap_formatted"
      tooltip="$tooltip\n│ Volume \$$volume_formatted"
      tooltip="$tooltip\n└────"
    fi

    # Bitcoin Dominance
    if [ "$btc_dominance" != "N/A" ]; then
      btc_dom_fmt=$(printf "%.2f" "$btc_dominance")
      tooltip="$tooltip\n┌─ 📊 DOMINANCE ───────"
      tooltip="$tooltip\n│ BTC  $btc_dom_fmt%"
      altcoin_dom=$(echo "100 - $btc_dominance" | ${pkgs.bc}/bin/bc)
      altcoin_dom_fmt=$(printf "%.2f" "$altcoin_dom")
      tooltip="$tooltip\n│ ALT  $altcoin_dom_fmt%"
      tooltip="$tooltip\n└────"
    fi

    # Alert info
    if [ -f "$ALERT_FILE" ]; then
      tooltip="$tooltip\n\n🔔 Price Alerts: Active"
    fi

    # ═══════════════════════════════════════
    # BLOCKCHAIN INFO - Last 3 blocks & Next 3 estimated
    # ═══════════════════════════════════════

    # Fetch last 3 blocks from mempool.space
    blocks_data=$(${pkgs.curl}/bin/curl -s "https://mempool.space/api/v1/blocks")

    # Fetch mempool info for next blocks estimation
    mempool_data=$(${pkgs.curl}/bin/curl -s "https://mempool.space/api/mempool")

    # Fetch difficulty adjustment info
    difficulty_data=$(${pkgs.curl}/bin/curl -s "https://mempool.space/api/v1/difficulty-adjustment")

    if [ $? -eq 0 ] && [ -n "$blocks_data" ]; then
      # Difficulty Adjustment info with progress bar (centered)
      if [ -n "$difficulty_data" ]; then
        progress=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.progressPercent // "N/A"')
        diff_change=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.difficultyChange // "N/A"')
        remaining_blocks=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.remainingBlocks // "N/A"')
        next_height=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.nextRetargetHeight // "N/A"')

        if [ "$progress" != "N/A" ]; then
          progress_fmt=$(printf "%.1f" "$progress")
          diff_change_fmt=$(printf "%+.2f" "$diff_change")

          # Create visual progress bar (17 chars for box width)
          progress_int=$(printf "%.0f" "$progress")
          filled=$((progress_int / 6))  # ~17 blocks = 100%
          [ "$filled" -gt 17 ] && filled=17
          empty=$((17 - filled))

          bar=""
          for ((i=0; i<filled; i++)); do bar="''${bar}█"; done
          for ((i=0; i<empty; i++)); do bar="''${bar}░"; done

          tooltip="$tooltip\n┌─ ⚙️  DIFFICULTY ─────"
          tooltip="$tooltip\n│ $bar"
          tooltip="$tooltip\n│ Progress: $progress_fmt%"
          tooltip="$tooltip\n│ Remain: $remaining_blocks blks"

          if (( $(echo "$diff_change >= 0" | ${pkgs.bc}/bin/bc -l) )); then
            tooltip="$tooltip\n│ Next: 📈 $diff_change_fmt%"
          else
            tooltip="$tooltip\n│ Next: 📉 $diff_change_fmt%"
          fi
          tooltip="$tooltip\n└────"
        fi
      fi

      # Last 3 mined blocks (compact & cute display)
      tooltip="$tooltip\n┌─ 🧊 LAST 3 BLOCKS ───"

      for i in 0 1 2; do
        block_height=$(echo "$blocks_data" | ${pkgs.jq}/bin/jq -r ".[$i].height // \"N/A\"")
        block_tx_count=$(echo "$blocks_data" | ${pkgs.jq}/bin/jq -r ".[$i].tx_count // \"N/A\"")
        block_timestamp=$(echo "$blocks_data" | ${pkgs.jq}/bin/jq -r ".[$i].timestamp // \"N/A\"")
        block_size=$(echo "$blocks_data" | ${pkgs.jq}/bin/jq -r ".[$i].size // \"N/A\"")
        coinbase_raw=$(echo "$blocks_data" | ${pkgs.jq}/bin/jq -r ".[$i].extras.coinbaseRaw // \"\"")

        if [ "$block_height" != "N/A" ]; then
          # Calculate time ago
          current_time=$(date +%s)
          time_diff=$((current_time - block_timestamp))

          if [ $time_diff -lt 60 ]; then
            time_ago="''${time_diff}s"
          elif [ $time_diff -lt 3600 ]; then
            time_ago="$((time_diff / 60))m"
          else
            time_ago="$((time_diff / 3600))h"
          fi

          # Format size (compact)
          if [ "$block_size" != "N/A" ]; then
            size_mb=$(echo "scale=1; $block_size / 1048576" | ${pkgs.bc}/bin/bc)
            size_fmt="''${size_mb}MB"
          else
            size_fmt="N/A"
          fi

          # Extract pool name (short version)
          pool_name="❓"
          if [ -n "$coinbase_raw" ]; then
            pool_text=$(echo "$coinbase_raw" | ${pkgs.xxd}/bin/xxd -r -p 2>/dev/null | strings | head -1)

            if echo "$pool_text" | grep -qi "foundry"; then
              pool_name="Foundry"
            elif echo "$pool_text" | grep -qi "antpool"; then
              pool_name="AntPool"
            elif echo "$pool_text" | grep -qi "f2pool"; then
              pool_name="F2Pool"
            elif echo "$pool_text" | grep -qi "binance"; then
              pool_name="Binance"
            elif echo "$pool_text" | grep -qi "viabtc"; then
              pool_name="ViaBTC"
            elif echo "$pool_text" | grep -qi "marathon"; then
              pool_name="MARA"
            elif echo "$pool_text" | grep -qi "luxor"; then
              pool_name="Luxor"
            elif echo "$pool_text" | grep -qi "braiins"; then
              pool_name="Braiins"
            elif [ -n "$pool_text" ]; then
              pool_name=$(echo "$pool_text" | awk '{print $1}' | cut -c1-8)
            fi
          fi

          # Create sparkline based on tx count
          tx_scaled=$(echo "scale=0; ($block_tx_count - 1000) / 500" | ${pkgs.bc}/bin/bc 2>/dev/null || echo "4")
          [ "$tx_scaled" -lt 0 ] && tx_scaled=0
          [ "$tx_scaled" -gt 7 ] && tx_scaled=7
          spark_chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
          block_bar="''${spark_chars[$tx_scaled]}"

          # Multi-line cute display inside box
          tooltip="$tooltip\n│"
          tooltip="$tooltip\n│ $block_bar  #$block_height"
          tooltip="$tooltip\n│    📊 $block_tx_count txs"
          tooltip="$tooltip\n│    💾 $size_fmt · ⏰ $time_ago"
          tooltip="$tooltip\n│    ⛏️  $pool_name"
        fi
      done
      tooltip="$tooltip\n└────"

      # Next 3 blocks estimation (based on mempool)
      if [ -n "$mempool_data" ]; then
        mempool_count=$(echo "$mempool_data" | ${pkgs.jq}/bin/jq -r '.count // 0')
        mempool_vsize=$(echo "$mempool_data" | ${pkgs.jq}/bin/jq -r '.vsize // 0')
        mempool_total_fee=$(echo "$mempool_data" | ${pkgs.jq}/bin/jq -r '.total_fee // 0')

        tooltip="$tooltip\n┌─ ⏳ NEXT 3 BLOCKS ───"

        # Get current tip height
        tip_height=$(echo "$blocks_data" | ${pkgs.jq}/bin/jq -r '.[0].height // 0')

        # Estimate blocks based on mempool
        avg_block_vsize=1500000  # ~1.5MB average

        if [ "$mempool_vsize" -gt 0 ]; then
          blocks_in_mempool=$(echo "scale=0; $mempool_vsize / $avg_block_vsize" | ${pkgs.bc}/bin/bc)

          for i in 1 2 3; do
            next_height=$((tip_height + i))
            est_time=$((i * 10))  # 10 minutes per block

            # Visual progress indicator (8 chars, compact)
            if [ $i -le $blocks_in_mempool ]; then
              bar="████████"
              icon="🎯"
            elif [ $i -eq $((blocks_in_mempool + 1)) ]; then
              bar="████░░░░"
              icon="⏳"
            else
              bar="░░░░░░░░"
              icon="⏸️"
            fi

            tooltip="$tooltip\n│ $icon #$next_height $bar ~$est_time m"
          done
          tooltip="$tooltip\n└────"

          # Show mempool stats with more info
          if [ "$mempool_count" != "0" ]; then
            mempool_mb=$(echo "scale=1; $mempool_vsize / 1048576" | ${pkgs.bc}/bin/bc)
            # Convert satoshis to BTC
            mempool_btc=$(echo "scale=2; $mempool_total_fee / 100000000" | ${pkgs.bc}/bin/bc)
            # Calculate fee rate (sat/vB)
            avg_fee_rate=$(echo "scale=0; ($mempool_total_fee / $mempool_vsize) * 1000" | ${pkgs.bc}/bin/bc)

            tooltip="$tooltip\n┌─ 📦 MEMPOOL ─────────"
            tooltip="$tooltip\n│ Txs:  $mempool_count"
            tooltip="$tooltip\n│ Size: $mempool_mb MB"
            tooltip="$tooltip\n│ Fees: $mempool_btc BTC"
            tooltip="$tooltip\n│ Rate: ~$avg_fee_rate sat/vB"
            tooltip="$tooltip\n└────"
          fi
        fi
      fi
    fi

    # Output JSON for Waybar
    echo "{\"text\": \"$usd_formatted\", \"tooltip\": \"$tooltip\"}"
  '';

  # Brightness sync script - synchronizes internal and external monitor brightness
  brightnessSyncScript = pkgs.writeShellScriptBin "brightness-sync" ''
    #!/usr/bin/env bash
    # Synchronize brightness between internal (Lenovo) and external (HDMI) monitors

    # Check if argument is provided
    if [ -z "$1" ]; then
      echo "Usage: brightness-sync <+5%|-5%|50%>"
      exit 1
    fi

    CHANGE="$1"

    # Change internal display brightness (Lenovo laptop screen)
    ${pkgs.brightnessctl}/bin/brightnessctl set "$CHANGE" > /dev/null

    # Get current brightness percentage
    CURRENT=$(${pkgs.brightnessctl}/bin/brightnessctl get)
    MAX=$(${pkgs.brightnessctl}/bin/brightnessctl max)
    PERCENT=$((CURRENT * 100 / MAX))

    # Sync external display if connected (HDMI via DDC/CI)
    # Check if external display is available (suppress errors if not connected)
    if ${pkgs.ddcutil}/bin/ddcutil detect 2>/dev/null | grep -q "Display"; then
      # Set external monitor brightness to match internal
      ${pkgs.ddcutil}/bin/ddcutil setvcp 10 "$PERCENT" 2>/dev/null || true
    fi
  '';

  # VPN Status Script
  vpnStatusScript = pkgs.writeShellScriptBin "vpn-status-waybar" ''
    #!/usr/bin/env bash
    # VPN Status Monitor: Detects Proton VPN connection status and country

    # Check if any Proton VPN connection is active in NetworkManager (use terse mode)
    vpn_line=$(${pkgs.networkmanager}/bin/nmcli -t -f NAME,TYPE,DEVICE connection show --active | ${pkgs.gnugrep}/bin/grep -i "proton" || true)

    # Double check: verify the VPN interface actually exists and has an IP
    if [ -n "$vpn_line" ]; then
      # Extract fields from terse output (delimiter is :)
      vpn_name=$(echo "$vpn_line" | cut -d: -f1)
      device=$(echo "$vpn_line" | cut -d: -f3)

      # Verify device exists and has an IP address
      if ! ${pkgs.iproute2}/bin/ip addr show "$device" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "inet "; then
        # Device doesn't exist or has no IP - VPN is NOT really connected
        vpn_line=""
      fi
    fi

    if [ -n "$vpn_line" ]; then
      # VPN is connected

      # Try to extract country from connection name
      # Proton VPN format: "ProtonVPN CH-123" or "Proton VPN NL" or "ProtonVPN PT#20"
      country=$(echo "$vpn_name" | ${pkgs.gnugrep}/bin/grep -oP '(?<=[A-Z]{2}[#-])?\K[A-Z]{2}(?=[#-]|$)' | head -1 || echo "?")

      # Get detailed connection info using connection name
      vpn_details=$(${pkgs.networkmanager}/bin/nmcli connection show "$vpn_name" 2>/dev/null)

      # Extract VPN type (WireGuard, OpenVPN, etc.)
      vpn_type=$(echo "$vpn_details" | ${pkgs.gnugrep}/bin/grep "connection.type:" | ${pkgs.gawk}/bin/awk '{print $2}')

      # Get local VPN IP address
      local_ip=$(${pkgs.iproute2}/bin/ip addr show "$device" 2>/dev/null | ${pkgs.gnugrep}/bin/grep "inet " | ${pkgs.gawk}/bin/awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

      # Get VPN gateway
      # WireGuard doesn't have a traditional gateway, so we check multiple sources:
      # 1. Try IP4.GATEWAY first (OpenVPN, etc.)
      gateway=$(echo "$vpn_details" | ${pkgs.gnugrep}/bin/grep "IP4.GATEWAY:" | ${pkgs.gawk}/bin/awk '{print $2}')

      # 2. If gateway is "--" or empty (WireGuard case), use DNS server as reference
      if [ "$gateway" = "--" ] || [ -z "$gateway" ]; then
        gateway=$(echo "$vpn_details" | ${pkgs.gnugrep}/bin/grep "IP4.DNS" | ${pkgs.gawk}/bin/awk '{print $2}' | head -1)
        if [ -z "$gateway" ]; then
          gateway="N/A"
        fi
      fi

      # Get public IP (with timeout to avoid hanging) - Using Cloudflare for privacy
      public_ip=$(${pkgs.curl}/bin/curl -s --max-time 2 https://icanhazip.com 2>/dev/null || echo "N/A")

      # Get DNS servers
      dns_servers=$(echo "$vpn_details" | ${pkgs.gnugrep}/bin/grep "IP4.DNS" | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.coreutils}/bin/tr '\n' ', ' | ${pkgs.gnused}/bin/sed 's/,$//' || echo "N/A")

      # Get connection start time and calculate uptime
      # Use connection.timestamp instead of GENERAL.STATE
      timestamp=$(echo "$vpn_details" | ${pkgs.gnugrep}/bin/grep "^connection.timestamp:" | ${pkgs.gawk}/bin/awk '{print $2}')
      if [ -n "$timestamp" ] && [ "$timestamp" != "0" ]; then
        current_time=$(date +%s)
        uptime_sec=$((current_time - timestamp))
        if [ $uptime_sec -lt 60 ]; then
          uptime="''${uptime_sec}s"
        elif [ $uptime_sec -lt 3600 ]; then
          uptime="$((uptime_sec / 60))m $((uptime_sec % 60))s"
        else
          uptime="$((uptime_sec / 3600))h $((uptime_sec % 3600 / 60))m"
        fi
      else
        uptime="N/A"
      fi

      # Build detailed tooltip
      tooltip="┌─ 󰖂 VPN CONNECTED ─────"
      tooltip="$tooltip\n│"
      tooltip="$tooltip\n│ 🌍 Country:  $country"
      tooltip="$tooltip\n│ 📡 Server:   $vpn_name"
      tooltip="$tooltip\n│ 🔒 Protocol: $vpn_type"
      tooltip="$tooltip\n│"
      tooltip="$tooltip\n│ 🖧  Device:   $device"
      tooltip="$tooltip\n│ 🏠 Local IP: $local_ip"
      tooltip="$tooltip\n│ 🌐 Public IP: $public_ip"
      tooltip="$tooltip\n│ 🚪 Gateway:  $gateway"
      tooltip="$tooltip\n│"
      tooltip="$tooltip\n│ 🕐 Uptime:   $uptime"
      if [ "$dns_servers" != "N/A" ]; then
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
      active_conn=$(${pkgs.networkmanager}/bin/nmcli -t -f NAME,TYPE,DEVICE connection show --active | ${pkgs.gnugrep}/bin/grep -E "wireless|ethernet" | head -1 || true)

      if [ -n "$active_conn" ]; then
        conn_name=$(echo "$active_conn" | cut -d: -f1)
        conn_type=$(echo "$active_conn" | cut -d: -f2)
        conn_device=$(echo "$active_conn" | cut -d: -f3)

        # Get local IP
        local_ip=$(${pkgs.iproute2}/bin/ip addr show "$conn_device" 2>/dev/null | ${pkgs.gnugrep}/bin/grep "inet " | ${pkgs.gawk}/bin/awk '{print $2}' | cut -d'/' -f1 || echo "N/A")

        # Get gateway
        gateway=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gnugrep}/bin/grep default | ${pkgs.gawk}/bin/awk '{print $3}' | head -1 || echo "N/A")

        # Get DNS servers (read from /etc/resolv.conf since systemd-resolved is disabled)
        dns_servers=$(${pkgs.gnugrep}/bin/grep "^nameserver" /etc/resolv.conf | ${pkgs.gawk}/bin/awk '{print $2}' | ${pkgs.coreutils}/bin/tr '\n' ', ' | ${pkgs.gnused}/bin/sed 's/,$//' || echo "N/A")

        # Connection type icon
        if [ "$conn_type" = "wireless" ] || [ "$conn_type" = "802-11-wireless" ]; then
          conn_icon="📶 WiFi"
        else
          conn_icon="🔌 Ethernet"
        fi

        # Get public IP (with timeout) - Using Cloudflare for privacy
        public_ip=$(${pkgs.curl}/bin/curl -s --max-time 3 https://icanhazip.com 2>/dev/null || echo "N/A")

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
  '';

  # NixOS Updates Script
  nixUpdatesScript = pkgs.writeShellScriptBin "nix-updates-waybar" ''
    #!/usr/bin/env bash
    # NixOS Updates Monitor: Checks for available flake updates

    FLAKE_DIR="$HOME/dotfiles/thinkpad-p14s-gen5"
    CACHE_FILE="$HOME/.cache/waybar-nix-updates"
    CACHE_DURATION=3600  # Cache for 1 hour

    # Check if cache is fresh
    if [ -f "$CACHE_FILE" ]; then
      cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
      if [ $cache_age -lt $CACHE_DURATION ]; then
        cat "$CACHE_FILE"
        exit 0
      fi
    fi

    # Check if flake directory exists
    if [ ! -d "$FLAKE_DIR" ]; then
      echo '{"text": "󰄬", "tooltip": "Flake directory not found", "class": "ok"}' | tee "$CACHE_FILE"
      exit 0
    fi

    cd "$FLAKE_DIR" || exit 1

    # Check for updates (compare current lock with latest)
    # This is a simplified check - just see if flake.lock is old
    lock_age=$(($(date +%s) - $(stat -c %Y "flake.lock" 2>/dev/null || echo 0)))
    days_old=$((lock_age / 86400))

    if [ $days_old -gt 7 ]; then
      # Flake is more than 7 days old
      tooltip="┌─ 󰏔 NixOS UPDATES ────┐"
      tooltip="$tooltip\n│ Last update: $days_old days ago"
      tooltip="$tooltip\n│"
      tooltip="$tooltip\n│ Run: nix flake update"
      tooltip="$tooltip\n└──────────────────────┘"
      tooltip="$tooltip\n\nClick to open terminal"

      echo "{\"text\": \"󰏔 $days_old\", \"tooltip\": \"$tooltip\", \"class\": \"updates\"}" | tee "$CACHE_FILE"
    else
      tooltip="󰄬 System is up to date\n\nLast update: $days_old days ago"
      echo "{\"text\": \"󰄬\", \"tooltip\": \"$tooltip\", \"class\": \"ok\"}" | tee "$CACHE_FILE"
    fi
  '';

  # Systemd Failed Services Script
  systemdFailedScript = pkgs.writeShellScriptBin "systemd-failed-waybar" ''
    #!/usr/bin/env bash
    # Systemd Failed Services Monitor

    # Count failed services
    failed_count=$(${pkgs.systemd}/bin/systemctl --failed --no-legend --no-pager | wc -l)

    if [ "$failed_count" -gt 0 ]; then
      # Get list of failed services
      failed_list=$(${pkgs.systemd}/bin/systemctl --failed --no-legend --no-pager | ${pkgs.gawk}/bin/awk '{print $1}')

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
  '';

  # Mako Notifications Script
  makoScript = pkgs.writeShellScriptBin "mako-waybar" ''
    #!/usr/bin/env bash
    # Mako Notifications Counter

    # Count notifications in history
    notif_count=$(${pkgs.mako}/bin/makoctl history | ${pkgs.jq}/bin/jq '.data[0] | length' 2>/dev/null || echo "0")

    if [ "$notif_count" -gt 0 ]; then
      # Get last few notifications
      recent=$(${pkgs.mako}/bin/makoctl history | ${pkgs.jq}/bin/jq -r '.data[0][:3] | .[] | "\(.app_name.data): \(.summary.data)"' 2>/dev/null)

      tooltip="┌─ 󰂚 NOTIFICATIONS ─────┐"
      tooltip="$tooltip\n│ Unread: $notif_count"
      tooltip="$tooltip\n│"

      if [ -n "$recent" ]; then
        while IFS= read -r notif; do
          # Truncate long notifications
          truncated=$(echo "$notif" | ${pkgs.coreutils}/bin/cut -c1-35)
          tooltip="$tooltip\n│ • $truncated"
        done <<< "$recent"
      fi

      tooltip="$tooltip\n└───────────────────────┘"
      tooltip="$tooltip\n\nClick: invoke | Right: dismiss all"

      echo "{\"text\": \"󰂚 $notif_count\", \"tooltip\": \"$tooltip\", \"class\": \"notification\"}"
    else
      echo "{\"text\": \"\", \"tooltip\": \"No notifications\", \"class\": \"empty\"}"
    fi
  '';

  # World Clocks Script
  worldClocksScript = pkgs.writeShellScriptBin "world-clocks-waybar" ''
    #!/usr/bin/env bash
    # World Clocks: Shows NY and Beijing times in tooltip

    # Get current times
    local_time=$(TZ="Europe/Lisbon" date "+%H:%M")
    ny_time=$(TZ="America/New_York" date "+%H:%M")
    beijing_time=$(TZ="Asia/Shanghai" date "+%H:%M")

    # Build tooltip
    tooltip="┌─ 🌍 WORLD CLOCKS ─────┐"
    tooltip="$tooltip\n│ 🇵🇹 Lisbon    $local_time"
    tooltip="$tooltip\n│ 🇺🇸 New York  $ny_time"
    tooltip="$tooltip\n│ 🇨🇳 Beijing   $beijing_time"
    tooltip="$tooltip\n└───────────────────────┘"

    echo "{\"text\": \"🌍\", \"tooltip\": \"$tooltip\", \"class\": \"world-clocks\"}"
  '';

  # Monitor Rotation Display Script - Shows current rotation status
  monitorRotationScript = pkgs.writeShellScriptBin "monitor-rotation-waybar" ''
    #!/usr/bin/env bash
    # Monitor Rotation Display: Shows current rotation status

    STATE_FILE="$HOME/.config/monitor-rotation-state"

    # Read current rotation (default: 0 = normal)
    CURRENT_ROTATION=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

    # Detect external monitor (HDMI-A-1 or DP-1)
    EXTERNAL_MONITOR=""
    if ${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep -q "HDMI-A-1"; then
      EXTERNAL_MONITOR="HDMI-A-1"
    elif ${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep -q "DP-1"; then
      EXTERNAL_MONITOR="DP-1"
    fi

    if [ -z "$EXTERNAL_MONITOR" ]; then
      # No external monitor - show disabled state
      echo "{\"text\": \"󰹑\", \"tooltip\": \"No external monitor\", \"class\": \"disabled\"}"
      exit 0
    fi

    # Display current rotation status based on state file
    case "$CURRENT_ROTATION" in
      0)
        ICON="󰹑"  # Monitor icon (normal)
        DESC="0° (Normal)"
        ;;
      1)
        ICON="󰹑"  # Monitor icon (90°)
        DESC="90° (Portrait)"
        ;;
      2)
        ICON="󰹑"  # Monitor icon (180°)
        DESC="180° (Inverted)"
        ;;
      3)
        ICON="󰹑"  # Monitor icon (270°)
        DESC="270° (Portrait Flipped)"
        ;;
      *)
        ICON="󰹑"
        DESC="0° (Normal)"
        ;;
    esac

    # Return current state for Waybar display
    tooltip="┌─ 󰹑 MONITOR ───────────┐"
    tooltip="$tooltip\n│ Display: $EXTERNAL_MONITOR"
    tooltip="$tooltip\n│ Current: $DESC"
    tooltip="$tooltip\n└───────────────────────┘"
    tooltip="$tooltip\n\nClick to rotate 90°"

    echo "{\"text\": \"$ICON\", \"tooltip\": \"$tooltip\", \"class\": \"active\"}"
  '';

  # Monitor Rotation Action Script - Performs the actual rotation
  monitorRotateAction = pkgs.writeShellScriptBin "monitor-rotate-action" ''
    #!/usr/bin/env bash
    # Monitor Rotation Action: Rotates the external monitor by 90°

    STATE_FILE="$HOME/.config/monitor-rotation-state"

    # Read current rotation (default: 0 = normal)
    CURRENT_ROTATION=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

    # Detect external monitor (HDMI-A-1 or DP-1)
    EXTERNAL_MONITOR=""
    if ${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep -q "HDMI-A-1"; then
      EXTERNAL_MONITOR="HDMI-A-1"
    elif ${pkgs.hyprland}/bin/hyprctl monitors | ${pkgs.gnugrep}/bin/grep -q "DP-1"; then
      EXTERNAL_MONITOR="DP-1"
    fi

    if [ -z "$EXTERNAL_MONITOR" ]; then
      ${pkgs.libnotify}/bin/notify-send "Monitor Rotation" "No external monitor detected" -i video-display
      exit 1
    fi

    # Determine next rotation (cycle: 0 -> 90 -> 180 -> 270 -> 0)
    case "$CURRENT_ROTATION" in
      0)
        NEXT_ROTATION="1"  # 90° clockwise
        TRANSFORM="1"
        DESC="90° (Portrait)"
        ;;
      1)
        NEXT_ROTATION="2"  # 180° upside-down
        TRANSFORM="2"
        DESC="180° (Inverted)"
        ;;
      2)
        NEXT_ROTATION="3"  # 270° counter-clockwise
        TRANSFORM="3"
        DESC="270° (Portrait Flipped)"
        ;;
      3)
        NEXT_ROTATION="0"  # 0° normal
        TRANSFORM="0"
        DESC="0° (Normal)"
        ;;
      *)
        NEXT_ROTATION="0"
        TRANSFORM="0"
        DESC="0° (Normal)"
        ;;
    esac

    # Apply rotation using Hyprland
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "$EXTERNAL_MONITOR,transform,$TRANSFORM"

    # Fix duplicate cursor bug by reloading cursor theme
    sleep 0.3
    ${pkgs.hyprland}/bin/hyprctl setcursor Bibata-Modern-Classic 24

    # Save state
    echo "$NEXT_ROTATION" > "$STATE_FILE"

    # Send notification
    ${pkgs.libnotify}/bin/notify-send "Monitor Rotation" "$EXTERNAL_MONITOR: $DESC" -i video-display
  '';
in
{
  # Create scripts in waybar config directory
  home.file.".config/waybar/scripts/bitcoin.sh" = {
    source = "${bitcoinScript}/bin/bitcoin-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/removable-disks.sh" = {
    source = "${removableDisksScript}/bin/removable-disks-waybar";
    executable = true;
  };

  # Brightness sync script for syncing internal + external monitors
  home.file.".config/waybar/scripts/brightness-sync.sh" = {
    source = "${brightnessSyncScript}/bin/brightness-sync";
    executable = true;
  };

  # New system monitoring scripts
  home.file.".config/waybar/scripts/vpn-status.sh" = {
    source = "${vpnStatusScript}/bin/vpn-status-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/nix-updates.sh" = {
    source = "${nixUpdatesScript}/bin/nix-updates-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/systemd-failed.sh" = {
    source = "${systemdFailedScript}/bin/systemd-failed-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/mako.sh" = {
    source = "${makoScript}/bin/mako-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/world-clocks.sh" = {
    source = "${worldClocksScript}/bin/world-clocks-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/monitor-rotation.sh" = {
    source = "${monitorRotationScript}/bin/monitor-rotation-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/monitor-rotate-action.sh" = {
    source = "${monitorRotateAction}/bin/monitor-rotate-action";
    executable = true;
  };

  # Bitcoin wallet balance monitor (privacy-focused zpub derivation)
  home.file.".config/waybar/scripts/wallets.py" = {
    source = ./waybar-scripts/wallets.py;
    executable = true;
  };

  home.file.".config/waybar/scripts/audio-switch.sh" = {
    source = "${audioSwitchScript}/bin/audio-switch-waybar";
    executable = true;
  };

  # Wallet configuration template
  home.file.".config/waybar/.env.example" = {
    source = ./waybar-scripts/.env.example;
  };

  # Bitcoin price alerts configuration example
  home.file.".config/waybar/bitcoin-alerts.conf.example" = {
    text = ''
      # Bitcoin Price Alerts Configuration
      #
      # Format: threshold_type=value
      #
      # Types:
      #   above=PRICE   - Alert when price goes ABOVE this value
      #   below=PRICE   - Alert when price goes BELOW this value
      #
      # Examples:

      # Alert when Bitcoin goes above $120,000
      #above=120000

      # Alert when Bitcoin drops below $100,000
      #below=100000

      # Multiple alerts are supported
      #above=125000
      #below=95000

      # To activate alerts:
      # 1. Copy this file: cp bitcoin-alerts.conf.example bitcoin-alerts.conf
      # 2. Uncomment and modify the alert thresholds above
      # 3. Waybar will check prices every 5 minutes and notify you
    '';
  };

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 2;  # Compact spacing between modules

        modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
        modules-center = [ ];
        modules-right = [
          # Finance modules
          "custom/polymarket"
          "custom/bitcoin"
          "custom/wallets"
          # System monitoring modules
          "custom/systemd-failed"
          "custom/mako"
          # Hardware modules
          "custom/removable-disks"
          "custom/monitor-rotation"
          "pulseaudio"
          "disk"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "network"
          "custom/weather"
          "clock"
          "custom/nix-updates"
          "custom/vpn"  # Moved next to updates
          "tray"  # System tray (shows service status like btrbk, next to updates)
        ];

        "hyprland/workspaces" = {
          format = "{name}";  # Show workspace number/name
          on-click = "activate";
          sort-by-number = true;
          all-outputs = true;  # Show workspaces from all monitors
          active-only = false;

          # Show workspaces 1-10
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
          };
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
          format = "{}";
        };

        "clock" = {
          format = " {:%H:%M}";
          format-alt = " {:%A, %d %B %Y - %H:%M:%S}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#f9cc6c'><b>{}</b></span>";
              days = "<span color='#e6d9db'>{}</span>";
              weeks = "<span color='#f9cc6c'><b>W{}</b></span>";
              weekdays = "<span color='#f9cc6c'><b>{}</b></span>";
              today = "<span color='#fd6883'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          tooltip-format = "{timeTo}\nPower: {power}W";
        };

        "bluetooth" = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          format-disabled = "";
          format-off = "";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        "network" = {
          # Waybar will auto-detect the default route interface
          # When VPN is active, it switches to the tunnel interface
          interface-types = [ "wifi" "ethernet" "bridge" "wireguard" "tun" ];  # Include WireGuard & VPN tunnels
          format = "󰌘 {ifname}";  # Generic format for VPN/tunnel interfaces
          format-wifi = "󰖩 {essid}";
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-linked = "󰌘 {ifname}";  # Interface up but no IP (shouldn't happen)
          format-disconnected = "󰖪";
          tooltip-format = "{ifname}\nIP: {ipaddr}\nGateway: {gwaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";  # Generic format for VPN/tunnel
          tooltip-format-wifi = "WiFi: {essid} ({signalStrength}%)\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-linked = "{ifname} (No IP)\nGateway: {gwaddr}";
          tooltip-format-disconnected = "No network connection";
          on-click = "nm-connection-editor";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰖁 ";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󱡏";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰦢";
            car = "󰄋";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          tooltip-format = "Volume: {volume}%\nDevice: {desc}\n\nClick icon to switch output";
          on-click = "$HOME/.config/waybar/scripts/audio-switch.sh";
          on-click-right = "pamixer -t";
          on-scroll-up = "pamixer -i 5";
          on-scroll-down = "pamixer -d 5";
        };

        "disk" = {
          format = "󰋊 {percentage_used}%";
          path = "/";
          tooltip-format = "Disk Usage: {used} / {total}\nAvailable: {free}";
          on-click = "nemo /";
        };

        "cpu" = {
          format = "󰻠 {usage}%";
          tooltip-format = "CPU Usage: {usage}%\nLoad: {load}";
          on-click = "kitty --class btop -e btop";
          interval = 2;
        };

        "memory" = {
          format = "󰍛 {percentage}%";
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nAvailable: {avail:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          on-click = "kitty --class btop -e btop";
          interval = 5;
        };

        "temperature" = {
          thermal-zone = 0;  # AMD Ryzen 7 PRO 8840HS thermal zone
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "󰔏" "󱃃" "󰸁" ];
          tooltip-format = "Temperature: {temperatureC}°C";
          on-click = "kitty --class btop -e btop";
        };

        "backlight" = {
          device = "amdgpu_bl1";  # AMD Radeon 780M backlight (was intel_backlight)
          format = "{icon} {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" "󱩎" "󱩏" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󰛨" ];
          tooltip-format = "Brightness: {percent}%\nScroll to adjust (syncs both screens)";
          on-scroll-up = "~/.config/waybar/scripts/brightness-sync.sh 5%+";
          on-scroll-down = "~/.config/waybar/scripts/brightness-sync.sh 5%-";
          # on-click removed to prevent system freeze
        };

        "custom/weather" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/weather.py";
          return-type = "json";
          interval = 600;  # Update every 10 minutes (600 seconds) - cached
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://open-meteo.com";
          signal = 4;  # Use SIGRTMIN+4 for manual refresh
          on-scroll-up = "pkill -RTMIN+4 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+4 waybar";  # Force refresh on scroll
        };

        "custom/polymarket" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/polymarket.py";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds) - cached
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://polymarket.com";
          signal = 2;  # Use SIGRTMIN+2 for manual refresh
          on-scroll-up = "pkill -RTMIN+2 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+2 waybar";  # Force refresh on scroll
        };

        "custom/bitcoin" = {
          exec = "~/.config/waybar/scripts/bitcoin.sh";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds)
          format = "₿ {}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://mempool.space/";
          signal = 1;  # Use SIGRTMIN+1 for manual refresh
          on-scroll-up = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
        };

        "custom/wallets" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/wallets.py";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds) - updates price only, balances cached
          format = "{}";  # Shows balance - blurred by CSS, clear on hover
          tooltip = true;
          signal = 3;  # Use SIGRTMIN+3 for manual refresh
          on-scroll-up = "pkill -RTMIN+3 waybar";  # Force price refresh (EUR/USD only, balances stay cached)
          on-scroll-down = "pkill -RTMIN+3 waybar";  # Force price refresh (EUR/USD only, balances stay cached)
        };

        # System Monitoring Modules
        "custom/vpn" = {
          exec = "~/.config/waybar/scripts/vpn-status.sh";
          return-type = "json";
          interval = 2;  # Update every 2 seconds for faster detection
          format = "{}";
          tooltip = true;
          on-click = "protonvpn-app";  # Open Proton VPN GUI
          signal = 8;  # Use SIGRTMIN+8 for manual refresh
        };

        "custom/nix-updates" = {
          exec = "~/.config/waybar/scripts/nix-updates.sh";
          return-type = "json";
          interval = 3600;  # Update every hour
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.hyprland}/bin/hyprctl dispatch exec '[float;size 800 600;center]' '${pkgs.kitty}/bin/kitty --hold sh -c \"cd ~/dotfiles/thinkpad-p14s-gen5 && nix flake update\"'";
        };

        "custom/systemd-failed" = {
          exec = "~/.config/waybar/scripts/systemd-failed.sh";
          return-type = "json";
          interval = 60;  # Update every minute
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.kitty}/bin/kitty --hold systemctl --failed";
        };

        "custom/mako" = {
          exec = "~/.config/waybar/scripts/mako.sh";
          return-type = "json";
          interval = 5;  # Update every 5 seconds
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.mako}/bin/makoctl invoke";
          on-click-right = "${pkgs.mako}/bin/makoctl dismiss --all";
        };

        "custom/removable-disks" = {
          exec = "~/.config/waybar/scripts/removable-disks.sh";
          return-type = "json";
          interval = 5;  # Update every 5 seconds to detect new devices
          format = "{}";
          tooltip = true;
          on-click = "nemo";  # Open file manager
        };

        "custom/monitor-rotation" = {
          exec = "~/.config/waybar/scripts/monitor-rotation.sh";
          return-type = "json";
          interval = 10;  # Update every 10 seconds
          format = "{}";
          tooltip = true;
          on-click = "~/.config/waybar/scripts/monitor-rotate-action.sh && pkill -RTMIN+9 waybar";
          signal = 9;  # Use SIGRTMIN+9 for manual refresh
        };

        "tray" = {
          spacing = 10;
          icon-size = 18;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(44, 37, 37, 0.93);
        color: #e6d9db;
      }

      #workspaces {
        margin: 0 6px;
      }

      #workspaces button {
        padding: 0 10px;
        min-width: 30px;
        color: #e6d9db;
        background: transparent;
        border-bottom: 2px solid transparent;
        border-radius: 0;
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        background: rgba(230, 217, 219, 0.1);
        border-bottom: 2px solid rgba(230, 217, 219, 0.3);
      }

      #workspaces button.active {
        background: #f9cc6c;
        color: #2c2525;
        border-bottom: 2px solid #f9cc6c;
        font-weight: bold;
      }

      #workspaces button.urgent {
        background: #fd6883;
        color: #2c2525;
        border-bottom: 2px solid #fd6883;
      }

      #workspaces button.visible {
        color: #f9cc6c;
      }

      #workspaces button.empty {
        opacity: 0.5;
      }

      #window {
        margin: 0 12px;
        padding: 0 10px;
        color: #f9cc6c;
      }

      #clock {
        padding: 0 12px;
        margin: 0 2px;
        background: rgba(249, 204, 108, 0.15);
        color: #f9cc6c;
        border-radius: 10px;
      }

      #custom-bitcoin,
      #custom-wallets,
      #custom-vpn,
      #custom-nix-updates,
      #custom-systemd-failed,
      #custom-mako,
      #custom-monitor-rotation,
      #pulseaudio,
      #bluetooth,
      #network,
      #disk,
      #cpu,
      #memory,
      #temperature,
      #backlight,
      #battery,
      #tray {
        padding: 0 8px;
        margin: 0 1px;
        background: rgba(64, 62, 65, 0.85);
        border-radius: 6px;
        color: #e6d9db;
      }

      #custom-bitcoin {
        padding: 0 8px;
        font-size: 12px;
        background: rgba(249, 204, 108, 0.2);
        color: #f9cc6c;
      }

      #custom-wallets {
        padding: 0 8px;
        font-size: 12px;
        background: rgba(253, 104, 131, 0.2);
        color: transparent;
        text-shadow: 0 0 8px #fd6883;
        transition: all 0.2s ease;
      }

      #custom-wallets:hover {
        color: #fd6883;
        text-shadow: none;
      }

      #custom-removable-disks {
        padding: 0 8px;
        margin: 0 1px;
        background: rgba(173, 218, 120, 0.2);
        color: #adda78;
      }

      #custom-monitor-rotation {
        padding: 0 8px;
        margin: 0 1px;
        background: rgba(173, 218, 120, 0.2);
        color: #adda78;
        transition: all 0.2s ease;
      }

      #custom-monitor-rotation:hover {
        background: rgba(173, 218, 120, 0.3);
      }

      #custom-monitor-rotation.disabled {
        background: rgba(64, 62, 65, 0.85);
        color: #665c54;
      }

      #custom-weather,
      #custom-polymarket {
        padding: 0 8px;
        margin: 0 1px;
        background: rgba(64, 62, 65, 0.85);
        border-radius: 6px;
        color: #e6d9db;
      }

      #pulseaudio.muted {
        color: #fd6883;
      }

      #battery.charging,
      #battery.plugged {
        color: #adda78;
      }

      #battery.warning:not(.charging) {
        color: #f9cc6c;
      }

      #battery.critical:not(.charging) {
        color: #fd6883;
      }

      #temperature.critical {
        color: #fd6883;
      }

      tooltip {
        background: rgba(44, 37, 37, 0.95);
        border: 2px solid rgba(249, 204, 108, 0.5);
        border-radius: 10px;
        color: #e6d9db;
      }
    '';
  };

  home.packages = with pkgs; [
    pavucontrol
    blueman
    networkmanagerapplet
    brightnessctl
    btop
  ];
}