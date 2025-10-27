# Waybar - Simple colors (Ristretto theme)
{ pkgs, config, ... }:

let
  removableDisksScript = pkgs.writeShellScriptBin "removable-disks-waybar" ''
    #!/usr/bin/env bash
    # List removable USB/external disks and allow ejecting

    # Get list of removable devices (excluding loop devices)
    devices=$(lsblk -nrpo "name,type,rm,size,mountpoint,label" | awk '$2=="part" && $3=="1" {print $0}')

    if [ -z "$devices" ]; then
      echo '{"text": "", "tooltip": "No removable disks"}'
      exit 0
    fi

    # Count mounted devices
    count=$(echo "$devices" | wc -l)

    # Build tooltip with device list
    tooltip="Removable Disks ($count):\n"
    while IFS= read -r line; do
      name=$(echo "$line" | awk '{print $1}')
      size=$(echo "$line" | awk '{print $4}')
      mount=$(echo "$line" | awk '{print $5}')
      label=$(echo "$line" | awk '{print $6}')

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
    # Advanced Bitcoin price monitor with blocks info, difficulty, and 30-day chart
    PATH="${pkgs.xxd}/bin:$PATH"

    # Configuration files
    ALERT_FILE="$HOME/.config/waybar/bitcoin-alerts.conf"
    LAST_PRICE_FILE="$HOME/.config/waybar/bitcoin-last-price"

    # Fetch comprehensive data from CoinGecko (free API, no key needed)
    # This single call gets: current price, 24h change, market cap, volume, and more
    coingecko_data=$(${pkgs.curl}/bin/curl -s "https://api.coingecko.com/api/v3/coins/bitcoin?localization=false&tickers=false&community_data=false&developer_data=false")

    if [ $? -ne 0 ] || [ -z "$coingecko_data" ]; then
      echo '{"text": "BTC: N/A", "tooltip": "Failed to fetch Bitcoin data"}'
      exit 0
    fi

    # Parse current prices and market data
    usd=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.current_price.usd // "N/A"')
    eur=$(echo "$coingecko_data" | ${pkgs.jq}/bin/jq -r '.market_data.current_price.eur // "N/A"')
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

    if [ "$usd" = "N/A" ]; then
      echo '{"text": "BTC: N/A", "tooltip": "Failed to parse Bitcoin data"}'
      exit 0
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

    # Fetch 30-day historical data for detailed chart (USD and EUR)
    history_response_usd=$(${pkgs.curl}/bin/curl -s "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=30&interval=daily")
    history_response_eur=$(${pkgs.curl}/bin/curl -s "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=eur&days=30&interval=daily")

    # Extract daily prices - CoinGecko returns [timestamp, price] arrays
    prices_usd=$(echo "$history_response_usd" | ${pkgs.jq}/bin/jq -r '.prices[]?[1]' 2>/dev/null)
    prices_eur=$(echo "$history_response_eur" | ${pkgs.jq}/bin/jq -r '.prices[]?[1]' 2>/dev/null)

    # Initialize sparkline and stats
    sparkline=""
    min_price_usd=""
    max_price_usd=""
    min_price_eur=""
    max_price_eur=""
    trend_indicator=""

    if [ -n "$prices_usd" ]; then
      price_array_usd=($prices_usd)

      if [ ''${#price_array_usd[@]} -gt 0 ]; then
        # Calculate min and max for USD
        min_price_usd=''${price_array_usd[0]}
        max_price_usd=''${price_array_usd[0]}

        for price in "''${price_array_usd[@]}"; do
          if (( $(echo "$price < $min_price_usd" | ${pkgs.bc}/bin/bc -l) )); then
            min_price_usd=$price
          fi
          if (( $(echo "$price > $max_price_usd" | ${pkgs.bc}/bin/bc -l) )); then
            max_price_usd=$price
          fi
        done

        # Calculate trend indicator using simple moving average
        # Compare first half average vs second half average
        array_len=''${#price_array_usd[@]}
        mid_point=$((array_len / 2))

        first_half_sum=0
        second_half_sum=0

        for ((i=0; i<mid_point; i++)); do
          first_half_sum=$(echo "$first_half_sum + ''${price_array_usd[$i]}" | ${pkgs.bc}/bin/bc -l)
        done

        for ((i=mid_point; i<array_len; i++)); do
          second_half_sum=$(echo "$second_half_sum + ''${price_array_usd[$i]}" | ${pkgs.bc}/bin/bc -l)
        done

        first_half_avg=$(echo "scale=2; $first_half_sum / $mid_point" | ${pkgs.bc}/bin/bc -l)
        second_half_avg=$(echo "scale=2; $second_half_sum / ($array_len - $mid_point)" | ${pkgs.bc}/bin/bc -l)

        trend_diff=$(echo "scale=2; (($second_half_avg - $first_half_avg) / $first_half_avg) * 100" | ${pkgs.bc}/bin/bc -l)

        if (( $(echo "$trend_diff > 2" | ${pkgs.bc}/bin/bc -l) )); then
          trend_indicator="↗ Bullish"
        elif (( $(echo "$trend_diff < -2" | ${pkgs.bc}/bin/bc -l) )); then
          trend_indicator="↘ Bearish"
        else
          trend_indicator="→ Stable"
        fi

        # Generate detailed sparkline using Unicode block characters ▁▂▃▄▅▆▇█
        spark_chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
        range=$(echo "$max_price_usd - $min_price_usd" | ${pkgs.bc}/bin/bc -l)

        if (( $(echo "$range > 0" | ${pkgs.bc}/bin/bc -l) )); then
          for price in "''${price_array_usd[@]}"; do
            normalized=$(echo "scale=2; (($price - $min_price_usd) / $range) * 7" | ${pkgs.bc}/bin/bc -l)
            index=$(printf "%.0f" "$normalized")
            [ "$index" -lt 0 ] && index=0
            [ "$index" -gt 7 ] && index=7
            sparkline="''${sparkline}''${spark_chars[$index]}"
          done
        fi
      fi
    fi

    # Calculate min and max for EUR
    if [ -n "$prices_eur" ]; then
      price_array_eur=($prices_eur)

      if [ ''${#price_array_eur[@]} -gt 0 ]; then
        min_price_eur=''${price_array_eur[0]}
        max_price_eur=''${price_array_eur[0]}

        for price in "''${price_array_eur[@]}"; do
          if (( $(echo "$price < $min_price_eur" | ${pkgs.bc}/bin/bc -l) )); then
            min_price_eur=$price
          fi
          if (( $(echo "$price > $max_price_eur" | ${pkgs.bc}/bin/bc -l) )); then
            max_price_eur=$price
          fi
        done
      fi
    fi

    # Format prices
    usd_formatted=$(printf "%.0fk" $(echo "$usd / 1000" | ${pkgs.bc}/bin/bc))

    usd_full=$(printf "%'.0f" "$usd" 2>/dev/null || echo "$usd")
    eur_full=$(printf "%'.0f" "$eur" 2>/dev/null || echo "$eur")

    # Format market cap (in trillions or billions)
    if [ "$market_cap" != "N/A" ]; then
      market_cap_t=$(echo "scale=3; $market_cap / 1000000000000" | ${pkgs.bc}/bin/bc)
      # If >= 1 trillion, show in trillions, otherwise billions
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

    # Format 24h range
    high_24h_usd_formatted=$(printf "%'.0f" "$high_24h_usd" 2>/dev/null || echo "$high_24h_usd")
    high_24h_eur_formatted=$(printf "%'.0f" "$high_24h_eur" 2>/dev/null || echo "$high_24h_eur")
    low_24h_usd_formatted=$(printf "%'.0f" "$low_24h_usd" 2>/dev/null || echo "$low_24h_usd")
    low_24h_eur_formatted=$(printf "%'.0f" "$low_24h_eur" 2>/dev/null || echo "$low_24h_eur")

    # Build comprehensive tooltip - centered, compact version
    tooltip="       ₿ BITCOIN (BTC)"
    tooltip="$tooltip\n"

    # Current Price (no box, compact, centered)
    tooltip="$tooltip\n        💰 PRICE"
    tooltip="$tooltip\n      USD  \$$usd_full"
    tooltip="$tooltip\n      EUR  €$eur_full"

    # Price changes with visual bars (centered)
    tooltip="$tooltip\n\n      📊 PERFORMANCE"

    if [ "$change_24h" != "N/A" ]; then
      change_24h_fmt=$(printf "%.2f" "$change_24h")
      # Create mini bar for percentage
      abs_change=$(echo "$change_24h" | sed 's/-//')
      bar_len=$(echo "scale=0; $abs_change / 2" | ${pkgs.bc}/bin/bc 2>/dev/null || echo "5")
      [ "$bar_len" -gt 20 ] && bar_len=20
      bar=""
      for ((i=0; i<bar_len; i++)); do bar="''${bar}█"; done

      if (( $(echo "$change_24h >= 0" | ${pkgs.bc}/bin/bc -l) )); then
        tooltip="$tooltip\n      24h  🟢 $bar +$change_24h_fmt%"
      else
        tooltip="$tooltip\n      24h  🔴 $bar $change_24h_fmt%"
      fi
    fi

    if [ "$change_7d" != "N/A" ]; then
      change_7d_fmt=$(printf "%.2f" "$change_7d")
      abs_change=$(echo "$change_7d" | sed 's/-//')
      bar_len=$(echo "scale=0; $abs_change / 2" | ${pkgs.bc}/bin/bc 2>/dev/null || echo "5")
      [ "$bar_len" -gt 20 ] && bar_len=20
      bar=""
      for ((i=0; i<bar_len; i++)); do bar="''${bar}█"; done

      if (( $(echo "$change_7d >= 0" | ${pkgs.bc}/bin/bc -l) )); then
        tooltip="$tooltip\n      7d   🟢 $bar +$change_7d_fmt%"
      else
        tooltip="$tooltip\n      7d   🔴 $bar $change_7d_fmt%"
      fi
    fi

    if [ "$change_30d" != "N/A" ]; then
      change_30d_fmt=$(printf "%.2f" "$change_30d")
      abs_change=$(echo "$change_30d" | sed 's/-//')
      bar_len=$(echo "scale=0; $abs_change / 2" | ${pkgs.bc}/bin/bc 2>/dev/null || echo "5")
      [ "$bar_len" -gt 20 ] && bar_len=20
      bar=""
      for ((i=0; i<bar_len; i++)); do bar="''${bar}█"; done

      if (( $(echo "$change_30d >= 0" | ${pkgs.bc}/bin/bc -l) )); then
        tooltip="$tooltip\n      30d  🟢 $bar +$change_30d_fmt%"
      else
        tooltip="$tooltip\n      30d  🔴 $bar $change_30d_fmt%"
      fi
    fi

    if [ "$change_1y" != "N/A" ]; then
      change_1y_fmt=$(printf "%.2f" "$change_1y")
      abs_change=$(echo "$change_1y" | sed 's/-//')
      bar_len=$(echo "scale=0; $abs_change / 10" | ${pkgs.bc}/bin/bc 2>/dev/null || echo "5")
      [ "$bar_len" -gt 20 ] && bar_len=20
      bar=""
      for ((i=0; i<bar_len; i++)); do bar="''${bar}█"; done

      if (( $(echo "$change_1y >= 0" | ${pkgs.bc}/bin/bc -l) )); then
        tooltip="$tooltip\n      1yr  🟢 $bar +$change_1y_fmt%"
      else
        tooltip="$tooltip\n      1yr  🔴 $bar $change_1y_fmt%"
      fi
    fi

    # 24h range (centered)
    if [ "$high_24h_usd" != "N/A" ] && [ "$low_24h_usd" != "N/A" ]; then
      tooltip="$tooltip\n\n      📈 24H RANGE"
      tooltip="$tooltip\n     High  \$$high_24h_usd_formatted / €$high_24h_eur_formatted"
      tooltip="$tooltip\n     Low   \$$low_24h_usd_formatted / €$low_24h_eur_formatted"
    fi

    # Market data (centered)
    tooltip="$tooltip\n\n        💎 MARKET"
    tooltip="$tooltip\n     Cap     \$$market_cap_formatted"
    tooltip="$tooltip\n     Volume  \$$volume_formatted"

    # 30-day chart and trend (centered)
    if [ -n "$sparkline" ]; then
      tooltip="$tooltip\n\n     📉 30-DAY CHART"
      tooltip="$tooltip\n   $sparkline"

      if [ -n "$trend_indicator" ]; then
        tooltip="$tooltip\n      $trend_indicator"
      fi

      if [ -n "$min_price_usd" ] && [ -n "$max_price_usd" ]; then
        min_usd_formatted=$(printf "%'.0f" "$min_price_usd")
        max_usd_formatted=$(printf "%'.0f" "$max_price_usd")
        min_eur_formatted=$(printf "%'.0f" "$min_price_eur")
        max_eur_formatted=$(printf "%'.0f" "$max_price_eur")
        tooltip="$tooltip\n     High  \$$max_usd_formatted / €$max_eur_formatted"
        tooltip="$tooltip\n     Low   \$$min_usd_formatted / €$min_eur_formatted"
      fi
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
      tooltip="$tooltip\n\n       ⛓️  BLOCKCHAIN"

      # Difficulty Adjustment info with progress bar (centered)
      if [ -n "$difficulty_data" ]; then
        progress=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.progressPercent // "N/A"')
        diff_change=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.difficultyChange // "N/A"')
        remaining_blocks=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.remainingBlocks // "N/A"')
        next_height=$(echo "$difficulty_data" | ${pkgs.jq}/bin/jq -r '.nextRetargetHeight // "N/A"')

        if [ "$progress" != "N/A" ]; then
          progress_fmt=$(printf "%.1f" "$progress")
          diff_change_fmt=$(printf "%+.2f" "$diff_change")

          # Create visual progress bar (24 chars)
          progress_int=$(printf "%.0f" "$progress")
          filled=$((progress_int / 4))  # 24 blocks = 100%
          empty=$((24 - filled))

          bar=""
          for ((i=0; i<filled; i++)); do bar="''${bar}█"; done
          for ((i=0; i<empty; i++)); do bar="''${bar}░"; done

          tooltip="$tooltip\n\n       ⚙️  DIFFICULTY"
          tooltip="$tooltip\n     $bar $progress_fmt%"
          tooltip="$tooltip\n     Remaining: $remaining_blocks blocks"

          if (( $(echo "$diff_change >= 0" | ${pkgs.bc}/bin/bc -l) )); then
            tooltip="$tooltip\n     Next: 📈 $diff_change_fmt% HARDER"
          else
            tooltip="$tooltip\n     Next: 📉 $diff_change_fmt% easier"
          fi
        fi
      fi

      # Last 3 mined blocks (compact & cute display)
      tooltip="$tooltip\n\n      🧊 LAST 3 BLOCKS"

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

          # Multi-line cute display
          tooltip="$tooltip\n"
          tooltip="$tooltip\n     $block_bar  Block #$block_height"
          tooltip="$tooltip\n        📊 $block_tx_count txs  💾 $size_fmt"
          tooltip="$tooltip\n        ⏰ $time_ago  ⛏️  $pool_name"
        fi
      done

      # Next 3 blocks estimation (based on mempool) (centered)
      if [ -n "$mempool_data" ]; then
        mempool_count=$(echo "$mempool_data" | ${pkgs.jq}/bin/jq -r '.count // 0')
        mempool_vsize=$(echo "$mempool_data" | ${pkgs.jq}/bin/jq -r '.vsize // 0')
        mempool_total_fee=$(echo "$mempool_data" | ${pkgs.jq}/bin/jq -r '.total_fee // 0')

        tooltip="$tooltip\n\n     ⏳ NEXT 3 BLOCKS"

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

            tooltip="$tooltip\n     $icon #$next_height $bar ~$est_time min"
          done

          # Show mempool stats with more info (centered)
          if [ "$mempool_count" != "0" ]; then
            mempool_mb=$(echo "scale=1; $mempool_vsize / 1048576" | ${pkgs.bc}/bin/bc)
            # Convert satoshis to BTC
            mempool_btc=$(echo "scale=2; $mempool_total_fee / 100000000" | ${pkgs.bc}/bin/bc)
            # Calculate fee rate (sat/vB)
            avg_fee_rate=$(echo "scale=0; ($mempool_total_fee / $mempool_vsize) * 1000" | ${pkgs.bc}/bin/bc)

            tooltip="$tooltip\n\n        📦 MEMPOOL"
            tooltip="$tooltip\n     Transactions: $mempool_count txs"
            tooltip="$tooltip\n     Size: $mempool_mb MB"
            tooltip="$tooltip\n     Total Fees: $mempool_btc BTC"
            tooltip="$tooltip\n     Avg Fee Rate: ~$avg_fee_rate sat/vB"
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

  # Bitcoin wallet balance monitor (privacy-focused zpub derivation)
  home.file.".config/waybar/scripts/wallets.py" = {
    source = ./waybar-scripts/wallets.py;
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
        spacing = 2;

        modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/bitcoin"
          "custom/wallets"
          "custom/removable-disks"
          "pulseaudio"
          "bluetooth"
          "network"
          "disk"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "tray"
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
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [ "" "" "" "" "" ];
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
          format-wifi = "󰖩 {essid}";
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-disconnected = "󰖪";
          tooltip-format-wifi = "WiFi: {essid} ({signalStrength}%)\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-disconnected = "No network connection";
          on-click = "nm-connection-editor";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰖁";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          tooltip-format = "Volume: {volume}%\nDevice: {desc}";
          on-click = "pavucontrol";
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
          format-icons = [ "" "" "" "" "" "" "" "" "" ];
          tooltip-format = "Brightness: {percent}%\nScroll to adjust (syncs both screens)";
          on-scroll-up = "~/.config/waybar/scripts/brightness-sync.sh 5%+";
          on-scroll-down = "~/.config/waybar/scripts/brightness-sync.sh 5%-";
          # on-click removed to prevent system freeze
        };

        "custom/bitcoin" = {
          exec = "~/.config/waybar/scripts/bitcoin.sh";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds)
          format = "₿ {}";
          tooltip = true;
          on-scroll-up = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
        };

        "custom/wallets" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/wallets.py";
          return-type = "json";
          interval = 1200;  # Update every 20 minutes (1200 seconds) - uses cache, very fast
          format = "{}";  # Shows balance - blurred by CSS, clear on hover
          tooltip = true;
        };

        "custom/removable-disks" = {
          exec = "~/.config/waybar/scripts/removable-disks.sh";
          return-type = "json";
          interval = 5;  # Update every 5 seconds to detect new devices
          format = "{}";
          tooltip = true;
          on-click = "nemo";  # Open file manager
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
        padding: 0 16px;
        margin: 0 8px;
        background: rgba(249, 204, 108, 0.15);
        color: #f9cc6c;
        border-radius: 10px;
      }

      #custom-bitcoin,
      #custom-wallets,
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
        padding: 0 10px;
        margin: 0 2px;
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
        padding: 0 10px;
        background: rgba(173, 218, 120, 0.2);
        color: #adda78;
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