#!/usr/bin/env bash
# Bitcoin price monitor: Coinbase (price) + CoinGecko (market data) + Mempool.space (blockchain)
# Optimized: Parallel API requests, sats/USD calculation, halving countdown, fear & greed

ALERT_FILE="$HOME/.config/waybar/bitcoin-alerts.conf"
LAST_PRICE_FILE="$HOME/.config/waybar/bitcoin-last-price"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

pango_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

json_output() {
  local tooltip="${2//\\n/$'\n'}"
  jq -cn --arg text "$1" --arg tooltip "$tooltip" '{text: $text, tooltip: $tooltip}'
}

repeat_char() {
  local char="$1"
  local count="$2"
  local out=""
  while [ "$count" -gt 0 ]; do
    out="${out}${char}"
    count=$((count - 1))
  done
  printf '%s' "$out"
}

jq_file() {
  local file="$1"
  local filter="$2"
  local fallback="${3:-N/A}"
  local value
  value=$(jq -r "$filter" "$file" 2>/dev/null) || value="$fallback"
  [ -z "$value" ] || [ "$value" = "null" ] && value="$fallback"
  printf '%s' "$value"
}

# Fetch all APIs in parallel
curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot" --max-time 10 > "$TEMP_DIR/usd" &
curl -s "https://api.coinbase.com/v2/prices/BTC-EUR/spot" --max-time 10 > "$TEMP_DIR/eur" &
curl -s --max-time 10 "https://api.coingecko.com/api/v3/coins/bitcoin?localization=false&tickers=false&community_data=false&developer_data=false" > "$TEMP_DIR/coingecko" &
curl -s --max-time 10 "https://api.coingecko.com/api/v3/global" > "$TEMP_DIR/global" &
curl -s "https://mempool.space/api/v1/blocks" --max-time 10 > "$TEMP_DIR/blocks" &
curl -s "https://mempool.space/api/mempool" --max-time 10 > "$TEMP_DIR/mempool" &
curl -s "https://mempool.space/api/v1/difficulty-adjustment" --max-time 10 > "$TEMP_DIR/difficulty" &
curl -s "https://mempool.space/api/v1/fees/recommended" --max-time 10 > "$TEMP_DIR/fees" &
wait

# Parse Coinbase prices
usd_response=$(cat "$TEMP_DIR/usd")
eur_response=$(cat "$TEMP_DIR/eur")

if [ -z "$usd_response" ]; then
  json_output "BTC: N/A" "Failed to fetch Bitcoin data"
  exit 0
fi

usd=$(jq_file "$TEMP_DIR/usd" '.data.amount // "N/A"')
eur=$(jq_file "$TEMP_DIR/eur" '.data.amount // "N/A"')

if [ "$usd" = "N/A" ] || [ "$usd" = "null" ]; then
  json_output "BTC: N/A" "Failed to parse Bitcoin data"
  exit 0
fi

# Parse CoinGecko market data
coingecko_data=$(cat "$TEMP_DIR/coingecko")
if [ -n "$coingecko_data" ] && jq -e . "$TEMP_DIR/coingecko" >/dev/null 2>&1; then
  change_24h=$(jq_file "$TEMP_DIR/coingecko" '.market_data.price_change_percentage_24h // "N/A"')
  change_7d=$(jq_file "$TEMP_DIR/coingecko" '.market_data.price_change_percentage_7d // "N/A"')
  change_30d=$(jq_file "$TEMP_DIR/coingecko" '.market_data.price_change_percentage_30d // "N/A"')
  change_1y=$(jq_file "$TEMP_DIR/coingecko" '.market_data.price_change_percentage_1y // "N/A"')
  market_cap=$(jq_file "$TEMP_DIR/coingecko" '.market_data.market_cap.usd // "N/A"')
  volume_24h=$(jq_file "$TEMP_DIR/coingecko" '.market_data.total_volume.usd // "N/A"')
  high_24h_usd=$(jq_file "$TEMP_DIR/coingecko" '.market_data.high_24h.usd // "N/A"')
  high_24h_eur=$(jq_file "$TEMP_DIR/coingecko" '.market_data.high_24h.eur // "N/A"')
  low_24h_usd=$(jq_file "$TEMP_DIR/coingecko" '.market_data.low_24h.usd // "N/A"')
  low_24h_eur=$(jq_file "$TEMP_DIR/coingecko" '.market_data.low_24h.eur // "N/A"')
  ath_usd=$(jq_file "$TEMP_DIR/coingecko" '.market_data.ath.usd // "N/A"')
  ath_change=$(jq_file "$TEMP_DIR/coingecko" '.market_data.ath_change_percentage.usd // "N/A"')
  circulating=$(jq_file "$TEMP_DIR/coingecko" '.market_data.circulating_supply // "N/A"')
else
  change_24h="N/A"; change_7d="N/A"; change_30d="N/A"; change_1y="N/A"
  market_cap="N/A"; volume_24h="N/A"
  high_24h_usd="N/A"; high_24h_eur="N/A"; low_24h_usd="N/A"; low_24h_eur="N/A"
  ath_usd="N/A"; ath_change="N/A"; circulating="N/A"
fi

# Bitcoin Dominance
global_data=$(cat "$TEMP_DIR/global")
if [ -n "$global_data" ] && jq -e . "$TEMP_DIR/global" >/dev/null 2>&1; then
  btc_dominance=$(jq_file "$TEMP_DIR/global" '.data.market_cap_percentage.btc // "N/A"')
else
  btc_dominance="N/A"
fi

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
usd_formatted=$(printf "%.0fk" "$(echo "$usd / 1000" | bc)")
usd_full=$(printf "%'.0f" "$usd" 2>/dev/null || echo "$usd")
eur_full=$(printf "%'.0f" "$eur" 2>/dev/null || echo "$eur")

# Sats per dollar
sats_per_usd=$(echo "scale=0; 100000000 / $usd" | bc 2>/dev/null || echo "N/A")

# 24h direction arrow for bar display
bar_arrow=""
if [ "$change_24h" != "N/A" ]; then
  if (( $(echo "$change_24h >= 0" | bc -l) )); then
    bar_arrow="▲"
  else
    bar_arrow="▼"
  fi
fi

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

# Load theme colors for Pango markup
source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_ACCENT="#d4c080"; C_RED="#d08080"; C_GREEN="#90c090"; C_BLUE="#90a8c8"; C_ORANGE="#c8a080"; C_CYAN="#80b8c8"; C_MAGENTA="#b888b8"; }

# Pango helpers
h() { local text; text=$(pango_escape "$1"); echo "<span color='$C_ACCENT'><b>$text</b></span>"; }  # header
v() { local text; text=$(pango_escape "$1"); echo "<span color='$C_FG'>$text</span>"; }              # value
d() { local text; text=$(pango_escape "$1"); echo "<span color='$C_DIM'>$text</span>"; }             # dim
g() { local text; text=$(pango_escape "$1"); echo "<span color='$C_GREEN'>$text</span>"; }           # green
r() { local text; text=$(pango_escape "$1"); echo "<span color='$C_RED'>$text</span>"; }             # red

# Build tooltip with Pango markup
tooltip="$(h '  BITCOIN')\n"
tooltip="$tooltip\n$(d 'USD')  $(v "\$$usd_full")"
tooltip="$tooltip\n$(d 'EUR')  $(v "€$eur_full")"
tooltip="$tooltip\n$(d 'SAT')  $(v "1\$ = $sats_per_usd sats")"

# Performance section
if [ "$change_24h" != "N/A" ]; then
  tooltip="$tooltip\n\n$(h '  PERFORMANCE')\n"
  for period in "24h:$change_24h" "7d:$change_7d" "30d:$change_30d" "1yr:$change_1y"; do
    label="${period%%:*}"
    value="${period#*:}"
    if [ "$value" != "N/A" ]; then
      value_fmt=$(printf "%.2f" "$value")
      if (( $(echo "$value >= 0" | bc -l) )); then
        tooltip="$tooltip\n$(d "$label")  $(g "+$value_fmt%")"
      else
        tooltip="$tooltip\n$(d "$label")  $(r "$value_fmt%")"
      fi
    fi
  done
fi

# 24h range
if [ "$high_24h_usd" != "N/A" ] && [ "$low_24h_usd" != "N/A" ]; then
  tooltip="$tooltip\n\n$(h '  24H RANGE')\n"
  tooltip="$tooltip\n$(d 'High') $(v "\$$(printf "%'.0f" "$high_24h_usd")") $(d '/') $(v "€$(printf "%'.0f" "$high_24h_eur")")"
  tooltip="$tooltip\n$(d 'Low')  $(v "\$$(printf "%'.0f" "$low_24h_usd")") $(d '/') $(v "€$(printf "%'.0f" "$low_24h_eur")")"
fi

# Market data
if [ "$market_cap" != "N/A" ]; then
  tooltip="$tooltip\n\n$(h '  MARKET')\n"
  tooltip="$tooltip\n$(d 'Cap')    $(v "\$$market_cap_formatted")"
  tooltip="$tooltip\n$(d 'Vol')    $(v "\$$volume_formatted")"
  if [ "$ath_usd" != "N/A" ]; then
    ath_fmt=$(printf "%'.0f" "$ath_usd" 2>/dev/null || echo "$ath_usd")
    ath_pct=$(printf "%.1f" "$ath_change" 2>/dev/null || echo "$ath_change")
    tooltip="$tooltip\n$(d 'ATH')    $(v "\$$ath_fmt") $(r "($ath_pct%)")"
  fi
  if [ "$circulating" != "N/A" ]; then
    circ_m=$(printf "%.2f" "$(echo "$circulating / 1000000" | bc -l)" 2>/dev/null)
    tooltip="$tooltip\n$(d 'Supply') $(v "${circ_m}M") $(d '/ 21M')"
  fi
fi

# Bitcoin Dominance
if [ "$btc_dominance" != "N/A" ]; then
  btc_dom_fmt=$(printf "%.1f" "$btc_dominance")
  tooltip="$tooltip\n\n$(h '  DOMINANCE')\n"
  tooltip="$tooltip\n$(d 'BTC') $(v "$btc_dom_fmt%")  $(d 'ALT') $(v "$(printf "%.1f" "$(echo "100 - $btc_dominance" | bc)")%")"
fi

# Alert info
[ -f "$ALERT_FILE" ] && tooltip="$tooltip\n\n$(g '  Price Alerts Active')"

# Recommended fees
fees_data=$(cat "$TEMP_DIR/fees")
if [ -n "$fees_data" ] && jq -e . "$TEMP_DIR/fees" >/dev/null 2>&1; then
  fee_fast=$(jq_file "$TEMP_DIR/fees" '.fastestFee // "N/A"')
  fee_half=$(jq_file "$TEMP_DIR/fees" '.halfHourFee // "N/A"')
  fee_hour=$(jq_file "$TEMP_DIR/fees" '.hourFee // "N/A"')
  fee_eco=$(jq_file "$TEMP_DIR/fees" '.economyFee // "N/A"')

  tooltip="$tooltip\n\n$(h '  FEES') $(d 'sat/vB')\n"
  tooltip="$tooltip\n$(d 'Next')  $(v "$fee_fast")  $(d '30m') $(v "$fee_half")  $(d '1h') $(v "$fee_hour")  $(d 'Eco') $(v "$fee_eco")"
fi

# Blockchain info
blocks_data=$(cat "$TEMP_DIR/blocks")
mempool_data=$(cat "$TEMP_DIR/mempool")
difficulty_data=$(cat "$TEMP_DIR/difficulty")

if [ -n "$blocks_data" ] && jq -e . "$TEMP_DIR/blocks" >/dev/null 2>&1; then
  # Halving countdown
  tip_height=$(jq_file "$TEMP_DIR/blocks" '.[0].height // 0' "0")
  if [ "$tip_height" != "0" ]; then
    next_halving=$((1050000))
    blocks_to_halving=$((next_halving - tip_height))
    if [ $blocks_to_halving -gt 0 ]; then
      days_to_halving=$((blocks_to_halving * 10 / 1440))
      tooltip="$tooltip\n\n$(h '  HALVING')\n"
      tooltip="$tooltip\n$(d 'Block') $(v "#$(printf "%'d" $next_halving)")  $(d 'in') $(v "$(printf "%'d" $blocks_to_halving) blks") $(d "(~${days_to_halving}d)")"
    fi
  fi

  # Difficulty Adjustment
  if [ -n "$difficulty_data" ] && jq -e . "$TEMP_DIR/difficulty" >/dev/null 2>&1; then
    progress=$(jq_file "$TEMP_DIR/difficulty" '.progressPercent // "N/A"')
    diff_change=$(jq_file "$TEMP_DIR/difficulty" '.difficultyChange // "N/A"')
    remaining_blocks=$(jq_file "$TEMP_DIR/difficulty" '.remainingBlocks // "N/A"')

    if [ "$progress" != "N/A" ]; then
      progress_fmt=$(printf "%.1f" "$progress")
      diff_change_fmt=$(printf "%+.2f" "$diff_change")
      progress_int=$(printf "%.0f" "$progress")
      filled=$((progress_int / 6))
      [ "$filled" -gt 17 ] && filled=17
      empty=$((17 - filled))

      bar="<span color='$C_ACCENT'>$(repeat_char '█' "$filled")</span><span color='$C_DIM'>$(repeat_char '░' "$empty")</span>"

      tooltip="$tooltip\n\n$(h '  DIFFICULTY')\n"
      tooltip="$tooltip\n$bar $(v "$progress_fmt%")  $(d "remain") $(v "$remaining_blocks")"
      if (( $(echo "$diff_change >= 0" | bc -l) )); then
        tooltip="$tooltip\n$(d 'Next adj:') $(g "$diff_change_fmt%")"
      else
        tooltip="$tooltip\n$(d 'Next adj:') $(r "$diff_change_fmt%")"
      fi
    fi
  fi

  # Recent blocks (compact)
  tooltip="$tooltip\n\n$(h '  BLOCKS')\n"
  now=$(date +%s)
  for i in 0 1 2; do
    block_height=$(jq_file "$TEMP_DIR/blocks" ".[$i].height // \"N/A\"")
    block_tx_count=$(jq_file "$TEMP_DIR/blocks" ".[$i].tx_count // \"N/A\"")
    block_timestamp=$(jq_file "$TEMP_DIR/blocks" ".[$i].timestamp // \"N/A\"")
    block_size=$(jq_file "$TEMP_DIR/blocks" ".[$i].size // \"N/A\"")
    coinbase_raw=$(jq_file "$TEMP_DIR/blocks" ".[$i].extras.coinbaseRaw // \"\"" "")

    if [ "$block_height" != "N/A" ]; then
      time_diff=$((now - block_timestamp))
      if [ $time_diff -lt 60 ]; then time_ago="${time_diff}s"
      elif [ $time_diff -lt 3600 ]; then time_ago="$((time_diff / 60))m"
      else time_ago="$((time_diff / 3600))h$((time_diff % 3600 / 60))m"
      fi

      size_mb=$(echo "scale=1; $block_size / 1048576" | bc)

      pool="?"
      if [ -n "$coinbase_raw" ]; then
        pt=$(echo "$coinbase_raw" 2>/dev/null | xxd -r -p 2>/dev/null | strings 2>/dev/null | head -1)
        case "$pt" in
          *[Ff]oundry*) pool="Foundry";; *[Aa]ntpool*) pool="AntPool";;
          *[Ff]2pool*) pool="F2Pool";; *[Bb]inance*) pool="Binance";;
          *[Vv]ia[Bb][Tt][Cc]*) pool="ViaBTC";; *[Mm]arathon*) pool="MARA";;
          *[Ll]uxor*) pool="Luxor";; *[Bb]raiins*) pool="Braiins";;
          *OCEAN*|*[Oo]cean*) pool="OCEAN";; *SBI*) pool="SBI";;
          *) [ -n "$pt" ] && pool=$(echo "$pt" | cut -c1-7);;
        esac
      fi

      tooltip="$tooltip\n$(v "#$block_height") $(d "${block_tx_count}tx ${size_mb}MB ${time_ago}") $(v "⛏$pool")"
    fi
  done

  # Mempool stats
  if [ -n "$mempool_data" ] && jq -e . "$TEMP_DIR/mempool" >/dev/null 2>&1; then
    mempool_count=$(jq_file "$TEMP_DIR/mempool" '.count // 0' "0")
    mempool_vsize=$(jq_file "$TEMP_DIR/mempool" '.vsize // 0' "0")
    mempool_total_fee=$(jq_file "$TEMP_DIR/mempool" '.total_fee // 0' "0")

    if [ "$mempool_count" != "0" ] && [ "$mempool_vsize" -gt 0 ]; then
      mempool_mb=$(echo "scale=1; $mempool_vsize / 1048576" | bc)
      mempool_btc=$(echo "scale=2; $mempool_total_fee / 100000000" | bc)

      tooltip="$tooltip\n\n$(h '  MEMPOOL')\n"
      tooltip="$tooltip\n$(d 'Txs') $(v "$(printf "%'d" "$mempool_count")")  $(d 'Size') $(v "${mempool_mb}MB")  $(d 'Fees') $(v "${mempool_btc} BTC")"
    fi
  fi
fi

json_output "$usd_formatted $bar_arrow" "$tooltip"
