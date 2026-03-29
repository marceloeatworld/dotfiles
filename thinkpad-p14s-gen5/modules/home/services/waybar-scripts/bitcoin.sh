#!/usr/bin/env bash
# Bitcoin price monitor: Coinbase (price) + CoinGecko (market data) + Mempool.space (blockchain)
# Optimized: Parallel API requests for faster loading

ALERT_FILE="$HOME/.config/waybar/bitcoin-alerts.conf"
LAST_PRICE_FILE="$HOME/.config/waybar/bitcoin-last-price"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Fetch all APIs in parallel
curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot" --max-time 10 > "$TEMP_DIR/usd" &
curl -s "https://api.coinbase.com/v2/prices/BTC-EUR/spot" --max-time 10 > "$TEMP_DIR/eur" &
curl -s --max-time 10 "https://api.coingecko.com/api/v3/coins/bitcoin?localization=false&tickers=false&community_data=false&developer_data=false" > "$TEMP_DIR/coingecko" &
curl -s --max-time 10 "https://api.coingecko.com/api/v3/global" > "$TEMP_DIR/global" &
curl -s "https://mempool.space/api/v1/blocks" --max-time 10 > "$TEMP_DIR/blocks" &
curl -s "https://mempool.space/api/mempool" --max-time 10 > "$TEMP_DIR/mempool" &
curl -s "https://mempool.space/api/v1/difficulty-adjustment" --max-time 10 > "$TEMP_DIR/difficulty" &
wait

# Parse Coinbase prices
usd_response=$(cat "$TEMP_DIR/usd")
eur_response=$(cat "$TEMP_DIR/eur")

if [ -z "$usd_response" ]; then
  echo '{"text": "BTC: N/A", "tooltip": "Failed to fetch Bitcoin data"}'
  exit 0
fi

usd=$(echo "$usd_response" | jq -r '.data.amount // "N/A"')
eur=$(echo "$eur_response" | jq -r '.data.amount // "N/A"')

if [ "$usd" = "N/A" ] || [ "$usd" = "null" ]; then
  echo '{"text": "BTC: N/A", "tooltip": "Failed to parse Bitcoin data"}'
  exit 0
fi

# Parse CoinGecko market data
coingecko_data=$(cat "$TEMP_DIR/coingecko")
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
  change_24h="N/A"; change_7d="N/A"; change_30d="N/A"; change_1y="N/A"
  market_cap="N/A"; volume_24h="N/A"
  high_24h_usd="N/A"; high_24h_eur="N/A"; low_24h_usd="N/A"; low_24h_eur="N/A"
fi

# Bitcoin Dominance
global_data=$(cat "$TEMP_DIR/global")
btc_dominance=$(echo "$global_data" | jq -r '.data.market_cap_percentage.btc // "N/A"')

# Check price alerts
if [ -f "$ALERT_FILE" ]; then
  while IFS='=' read -r threshold_type threshold_value; do
    [[ "$threshold_type" =~ ^#.*$ ]] && continue
    [[ -z "$threshold_type" ]] && continue
    case "$threshold_type" in
      above)
        if (( $(echo "$usd >= $threshold_value" | bc -l) )); then
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

# Build tooltip
tooltip="┌─ 🏷️ PRICE ──────────"
tooltip="$tooltip\n│ USD  \$$usd_full"
tooltip="$tooltip\n│ EUR  €$eur_full"
tooltip="$tooltip\n└────"

# Performance section
if [ "$change_24h" != "N/A" ]; then
  tooltip="$tooltip\n┌─ 📊 PERFORMANCE ─────"
  for period in "24h:$change_24h" "7d:$change_7d" "30d:$change_30d" "1yr:$change_1y"; do
    label="${period%%:*}"
    value="${period#*:}"
    if [ "$value" != "N/A" ]; then
      value_fmt=$(printf "%.2f" "$value")
      if (( $(echo "$value >= 0" | bc -l) )); then
        tooltip="$tooltip\n│ $label  🟢 +$value_fmt%"
      else
        tooltip="$tooltip\n│ $label  🔴 $value_fmt%"
      fi
    fi
  done
  tooltip="$tooltip\n└────"
fi

# 24h range
if [ "$high_24h_usd" != "N/A" ] && [ "$low_24h_usd" != "N/A" ]; then
  tooltip="$tooltip\n┌─ 📈 24H RANGE ───────"
  tooltip="$tooltip\n│ High \$$(printf "%'.0f" "$high_24h_usd") / €$(printf "%'.0f" "$high_24h_eur")"
  tooltip="$tooltip\n│ Low  \$$(printf "%'.0f" "$low_24h_usd") / €$(printf "%'.0f" "$low_24h_eur")"
  tooltip="$tooltip\n└────"
fi

# Market data
if [ "$market_cap" != "N/A" ]; then
  tooltip="$tooltip\n┌─ 💎 MARKET ──────────"
  tooltip="$tooltip\n│ Cap    \$$market_cap_formatted"
  tooltip="$tooltip\n│ Volume \$$volume_formatted"
  tooltip="$tooltip\n└────"
fi

# Bitcoin Dominance
if [ "$btc_dominance" != "N/A" ]; then
  btc_dom_fmt=$(printf "%.2f" "$btc_dominance")
  altcoin_dom_fmt=$(printf "%.2f" "$(echo "100 - $btc_dominance" | bc)")
  tooltip="$tooltip\n┌─ 📊 DOMINANCE ───────"
  tooltip="$tooltip\n│ BTC  $btc_dom_fmt%"
  tooltip="$tooltip\n│ ALT  $altcoin_dom_fmt%"
  tooltip="$tooltip\n└────"
fi

# Alert info
[ -f "$ALERT_FILE" ] && tooltip="$tooltip\n\n🔔 Price Alerts: Active"

# Blockchain info
blocks_data=$(cat "$TEMP_DIR/blocks")
mempool_data=$(cat "$TEMP_DIR/mempool")
difficulty_data=$(cat "$TEMP_DIR/difficulty")

if [ -n "$blocks_data" ]; then
  # Difficulty Adjustment
  if [ -n "$difficulty_data" ]; then
    progress=$(echo "$difficulty_data" | jq -r '.progressPercent // "N/A"')
    diff_change=$(echo "$difficulty_data" | jq -r '.difficultyChange // "N/A"')
    remaining_blocks=$(echo "$difficulty_data" | jq -r '.remainingBlocks // "N/A"')

    if [ "$progress" != "N/A" ]; then
      progress_fmt=$(printf "%.1f" "$progress")
      diff_change_fmt=$(printf "%+.2f" "$diff_change")
      progress_int=$(printf "%.0f" "$progress")
      filled=$((progress_int / 6))
      [ "$filled" -gt 17 ] && filled=17
      empty=$((17 - filled))

      bar=$(printf '█%.0s' $(seq 1 $filled 2>/dev/null) 2>/dev/null)$(printf '░%.0s' $(seq 1 $empty 2>/dev/null) 2>/dev/null)

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

  # Last 3 blocks
  tooltip="$tooltip\n┌─ 🧊 LAST 3 BLOCKS ───"
  for i in 0 1 2; do
    block_height=$(echo "$blocks_data" | jq -r ".[$i].height // \"N/A\"")
    block_tx_count=$(echo "$blocks_data" | jq -r ".[$i].tx_count // \"N/A\"")
    block_timestamp=$(echo "$blocks_data" | jq -r ".[$i].timestamp // \"N/A\"")
    block_size=$(echo "$blocks_data" | jq -r ".[$i].size // \"N/A\"")
    coinbase_raw=$(echo "$blocks_data" | jq -r ".[$i].extras.coinbaseRaw // \"\"")

    if [ "$block_height" != "N/A" ]; then
      time_diff=$(($(date +%s) - block_timestamp))
      if [ $time_diff -lt 60 ]; then time_ago="${time_diff}s"
      elif [ $time_diff -lt 3600 ]; then time_ago="$((time_diff / 60))m"
      else time_ago="$((time_diff / 3600))h"
      fi

      size_mb=$(echo "scale=1; $block_size / 1048576" | bc)
      size_fmt="${size_mb}MB"

      # Extract pool name
      pool_name="❓"
      if [ -n "$coinbase_raw" ]; then
        pool_text=$(echo "$coinbase_raw" | xxd -r -p 2>/dev/null | strings | head -1)
        case "$pool_text" in
          *[Ff]oundry*) pool_name="Foundry";;
          *[Aa]ntpool*) pool_name="AntPool";;
          *[Ff]2pool*) pool_name="F2Pool";;
          *[Bb]inance*) pool_name="Binance";;
          *[Vv]ia[Bb][Tt][Cc]*) pool_name="ViaBTC";;
          *[Mm]arathon*) pool_name="MARA";;
          *[Ll]uxor*) pool_name="Luxor";;
          *[Bb]raiins*) pool_name="Braiins";;
          *) [ -n "$pool_text" ] && pool_name=$(echo "$pool_text" | cut -c1-8);;
        esac
      fi

      # Sparkline based on tx count
      tx_scaled=$(echo "scale=0; ($block_tx_count - 1000) / 500" | bc 2>/dev/null || echo "4")
      [ "$tx_scaled" -lt 0 ] && tx_scaled=0
      [ "$tx_scaled" -gt 7 ] && tx_scaled=7
      spark_chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

      tooltip="$tooltip\n│"
      tooltip="$tooltip\n│ ${spark_chars[$tx_scaled]}  #$block_height"
      tooltip="$tooltip\n│    📊 $block_tx_count txs"
      tooltip="$tooltip\n│    💾 $size_fmt · ⏰ $time_ago"
      tooltip="$tooltip\n│    ⛏️  $pool_name"
    fi
  done
  tooltip="$tooltip\n└────"

  # Mempool stats
  if [ -n "$mempool_data" ]; then
    mempool_count=$(echo "$mempool_data" | jq -r '.count // 0')
    mempool_vsize=$(echo "$mempool_data" | jq -r '.vsize // 0')
    mempool_total_fee=$(echo "$mempool_data" | jq -r '.total_fee // 0')

    if [ "$mempool_count" != "0" ] && [ "$mempool_vsize" -gt 0 ]; then
      tip_height=$(echo "$blocks_data" | jq -r '.[0].height // 0')
      avg_block_vsize=1500000

      tooltip="$tooltip\n┌─ ⏳ NEXT 3 BLOCKS ───"
      blocks_in_mempool=$(echo "scale=0; $mempool_vsize / $avg_block_vsize" | bc)

      for i in 1 2 3; do
        next_height=$((tip_height + i))
        est_time=$((i * 10))
        if [ $i -le $blocks_in_mempool ]; then bar="████████"; icon="🎯"
        elif [ $i -eq $((blocks_in_mempool + 1)) ]; then bar="████░░░░"; icon="⏳"
        else bar="░░░░░░░░"; icon="⏸️"
        fi
        tooltip="$tooltip\n│ $icon #$next_height $bar ~${est_time}m"
      done
      tooltip="$tooltip\n└────"

      mempool_mb=$(echo "scale=1; $mempool_vsize / 1048576" | bc)
      mempool_btc=$(echo "scale=2; $mempool_total_fee / 100000000" | bc)
      avg_fee_rate=$(echo "scale=0; ($mempool_total_fee / $mempool_vsize) * 1000" | bc)

      tooltip="$tooltip\n┌─ 📦 MEMPOOL ─────────"
      tooltip="$tooltip\n│ Txs:  $mempool_count"
      tooltip="$tooltip\n│ Size: ${mempool_mb}MB"
      tooltip="$tooltip\n│ Fees: ${mempool_btc}BTC"
      tooltip="$tooltip\n│ Rate: ~${avg_fee_rate} sat/vB"
      tooltip="$tooltip\n└────"
    fi
  fi
fi

echo "{\"text\": \"$usd_formatted\", \"tooltip\": \"$tooltip\"}"
