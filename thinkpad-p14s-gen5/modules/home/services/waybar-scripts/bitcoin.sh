#!/usr/bin/env bash
# Bitcoin price monitor: Coinbase (price) + CoinGecko (market data)

# Configuration files
ALERT_FILE="$HOME/.config/waybar/bitcoin-alerts.conf"
LAST_PRICE_FILE="$HOME/.config/waybar/bitcoin-last-price"

# Fetch prices from Coinbase API (reliable primary source)
usd_response=$(curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot" --max-time 10)
eur_response=$(curl -s "https://api.coinbase.com/v2/prices/BTC-EUR/spot" --max-time 10)

if [ $? -ne 0 ] || [ -z "$usd_response" ]; then
  echo '{"text": "BTC: N/A", "tooltip": "Failed to fetch Bitcoin data"}'
  exit 0
fi

# Parse prices from Coinbase
usd=$(echo "$usd_response" | jq -r '.data.amount // "N/A"')
eur=$(echo "$eur_response" | jq -r '.data.amount // "N/A"')

if [ "$usd" = "N/A" ] || [ "$usd" = "null" ]; then
  echo '{"text": "BTC: N/A", "tooltip": "Failed to parse Bitcoin data"}'
  exit 0
fi

# Fetch market data from CoinGecko (optional, with fallback)
coingecko_data=$(curl -s --max-time 10 "https://api.coingecko.com/api/v3/coins/bitcoin?localization=false&tickers=false&community_data=false&developer_data=false")

# Parse CoinGecko data (with fallback to N/A if it fails)
if [ -n "$coingecko_data" ]; then
  change_24h=$(echo "$coingecko_data" | jq -r '.market_data.price_change_percentage_24h // "N/A"')
  change_7d=$(echo "$coingecko_data" | jq -r '.market_data.price_change_percentage_7d // "N/A"')
  change_30d=$(echo "$coingecko_data" | jq -r '.market_data.price_change_percentage_30d // "N/A"')
  change_1y=$(echo "$coingecko_data" | jq -r '.market_data.price_change_percentage_1y // "N/A"')
  market_cap=$(echo "$coingecko_data" | jq -r '.market_data.market_cap.usd // "N/A"')
  volume_24h=$(echo "$coingecko_data" | jq -r '.market_data.total_volume.usd // "N/A"')
  high_24h_usd=$(echo "$coingecko_data" | jq -r '.market_data.high_24h.usd // "N/A"')
  high_24h_eur=$(echo "$coingecko_data" | jq -r '.market_data.high_24h.eur // "N/A"')
  low_24h_usd=$(echo "$coingecko_data" | jq -r '.market_data.low_24h.usd // "N/A"')
  low_24h_eur=$(echo "$coingecko_data" | jq -r '.market_data.low_24h.eur // "N/A"')
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
global_data=$(curl -s --max-time 10 "https://api.coingecko.com/api/v3/global")
if [ -n "$global_data" ]; then
  btc_dominance=$(echo "$global_data" | jq -r '.data.market_cap_percentage.btc // "N/A"')
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
        if (( $(echo "$usd >= $threshold_value" | bc -l) )); then
          # Check if we already notified
          last_price=$(cat "$LAST_PRICE_FILE" 2>/dev/null || echo "0")
          if (( $(echo "$last_price < $threshold_value" | bc -l) )); then
            notify-send -u critical "Bitcoin Alert" "Price crossed above \$$threshold_value\nCurrent: \$$usd"
          fi
        fi
        ;;
      below)
        if (( $(echo "$usd <= $threshold_value" | bc -l) )); then
          last_price=$(cat "$LAST_PRICE_FILE" 2>/dev/null || echo "999999")
          if (( $(echo "$last_price > $threshold_value" | bc -l) )); then
            notify-send -u critical "Bitcoin Alert" "Price dropped below \$$threshold_value\nCurrent: \$$usd"
          fi
        fi
        ;;
    esac
  done < "$ALERT_FILE"

  # Save current price for next check
  echo "$usd" > "$LAST_PRICE_FILE"
fi

# Format prices
usd_formatted=$(printf "%.0fk" $(echo "$usd / 1000" | bc))
usd_full=$(printf "%'.0f" "$usd" 2>/dev/null || echo "$usd")
eur_full=$(printf "%'.0f" "$eur" 2>/dev/null || echo "$eur")

# Format market data
if [ "$market_cap" != "N/A" ]; then
  market_cap_t=$(echo "scale=3; $market_cap / 1000000000000" | bc)
  if (( $(echo "$market_cap_t >= 1" | bc -l) )); then
    market_cap_formatted=$(printf "%.2fT" "$market_cap_t")
  else
    market_cap_b=$(echo "scale=2; $market_cap / 1000000000" | bc)
    market_cap_formatted=$(printf "%.2fB" "$market_cap_b")
  fi
else
  market_cap_formatted="N/A"
fi

if [ "$volume_24h" != "N/A" ]; then
  volume_b=$(echo "scale=2; $volume_24h / 1000000000" | bc)
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
    if (( $(echo "$change_24h >= 0" | bc -l) )); then
      tooltip="$tooltip\n│ 24h  🟢 +$change_24h_fmt%"
    else
      tooltip="$tooltip\n│ 24h  🔴 $change_24h_fmt%"
    fi
  fi

  if [ "$change_7d" != "N/A" ]; then
    change_7d_fmt=$(printf "%.2f" "$change_7d")
    if (( $(echo "$change_7d >= 0" | bc -l) )); then
      tooltip="$tooltip\n│ 7d   🟢 +$change_7d_fmt%"
    else
      tooltip="$tooltip\n│ 7d   🔴 $change_7d_fmt%"
    fi
  fi

  if [ "$change_30d" != "N/A" ]; then
    change_30d_fmt=$(printf "%.2f" "$change_30d")
    if (( $(echo "$change_30d >= 0" | bc -l) )); then
      tooltip="$tooltip\n│ 30d  🟢 +$change_30d_fmt%"
    else
      tooltip="$tooltip\n│ 30d  🔴 $change_30d_fmt%"
    fi
  fi

  if [ "$change_1y" != "N/A" ]; then
    change_1y_fmt=$(printf "%.2f" "$change_1y")
    if (( $(echo "$change_1y >= 0" | bc -l) )); then
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
  altcoin_dom=$(echo "100 - $btc_dominance" | bc)
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
blocks_data=$(curl -s "https://mempool.space/api/v1/blocks")

# Fetch mempool info for next blocks estimation
mempool_data=$(curl -s "https://mempool.space/api/mempool")

# Fetch difficulty adjustment info
difficulty_data=$(curl -s "https://mempool.space/api/v1/difficulty-adjustment")

if [ $? -eq 0 ] && [ -n "$blocks_data" ]; then
  # Difficulty Adjustment info with progress bar (centered)
  if [ -n "$difficulty_data" ]; then
    progress=$(echo "$difficulty_data" | jq -r '.progressPercent // "N/A"')
    diff_change=$(echo "$difficulty_data" | jq -r '.difficultyChange // "N/A"')
    remaining_blocks=$(echo "$difficulty_data" | jq -r '.remainingBlocks // "N/A"')
    next_height=$(echo "$difficulty_data" | jq -r '.nextRetargetHeight // "N/A"')

    if [ "$progress" != "N/A" ]; then
      progress_fmt=$(printf "%.1f" "$progress")
      diff_change_fmt=$(printf "%+.2f" "$diff_change")

      # Create visual progress bar (17 chars for box width)
      progress_int=$(printf "%.0f" "$progress")
      filled=$((progress_int / 6))  # ~17 blocks = 100%
      [ "$filled" -gt 17 ] && filled=17
      empty=$((17 - filled))

      bar=""
      for ((i=0; i<filled; i++)); do bar="${bar}█"; done
      for ((i=0; i<empty; i++)); do bar="${bar}░"; done

      tooltip="$tooltip\n┌─ ⚙️  DIFFICULTY ─────"
      tooltip="$tooltip\n│ $bar"
      tooltip="$tooltip\n│ Progress: $progress_fmt%"
      tooltip="$tooltip\n│ Remain: $remaining_blocks blks"

      if (( $(echo "$diff_change >= 0" | bc -l) )); then
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
    block_height=$(echo "$blocks_data" | jq -r ".[$i].height // \"N/A\"")
    block_tx_count=$(echo "$blocks_data" | jq -r ".[$i].tx_count // \"N/A\"")
    block_timestamp=$(echo "$blocks_data" | jq -r ".[$i].timestamp // \"N/A\"")
    block_size=$(echo "$blocks_data" | jq -r ".[$i].size // \"N/A\"")
    coinbase_raw=$(echo "$blocks_data" | jq -r ".[$i].extras.coinbaseRaw // \"\"")

    if [ "$block_height" != "N/A" ]; then
      # Calculate time ago
      current_time=$(date +%s)
      time_diff=$((current_time - block_timestamp))

      if [ $time_diff -lt 60 ]; then
        time_ago="${time_diff}s"
      elif [ $time_diff -lt 3600 ]; then
        time_ago="$((time_diff / 60))m"
      else
        time_ago="$((time_diff / 3600))h"
      fi

      # Format size (compact)
      if [ "$block_size" != "N/A" ]; then
        size_mb=$(echo "scale=1; $block_size / 1048576" | bc)
        size_fmt="${size_mb}MB"
      else
        size_fmt="N/A"
      fi

      # Extract pool name (short version)
      pool_name="❓"
      if [ -n "$coinbase_raw" ]; then
        pool_text=$(echo "$coinbase_raw" | xxd -r -p 2>/dev/null | strings | head -1)

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
      tx_scaled=$(echo "scale=0; ($block_tx_count - 1000) / 500" | bc 2>/dev/null || echo "4")
      [ "$tx_scaled" -lt 0 ] && tx_scaled=0
      [ "$tx_scaled" -gt 7 ] && tx_scaled=7
      spark_chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")
      block_bar="${spark_chars[$tx_scaled]}"

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
    mempool_count=$(echo "$mempool_data" | jq -r '.count // 0')
    mempool_vsize=$(echo "$mempool_data" | jq -r '.vsize // 0')
    mempool_total_fee=$(echo "$mempool_data" | jq -r '.total_fee // 0')

    tooltip="$tooltip\n┌─ ⏳ NEXT 3 BLOCKS ───"

    # Get current tip height
    tip_height=$(echo "$blocks_data" | jq -r '.[0].height // 0')

    # Estimate blocks based on mempool
    avg_block_vsize=1500000  # ~1.5MB average

    if [ "$mempool_vsize" -gt 0 ]; then
      blocks_in_mempool=$(echo "scale=0; $mempool_vsize / $avg_block_vsize" | bc)

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
        mempool_mb=$(echo "scale=1; $mempool_vsize / 1048576" | bc)
        # Convert satoshis to BTC
        mempool_btc=$(echo "scale=2; $mempool_total_fee / 100000000" | bc)
        # Calculate fee rate (sat/vB)
        avg_fee_rate=$(echo "scale=0; ($mempool_total_fee / $mempool_vsize) * 1000" | bc)

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
