#!/usr/bin/env bash
# NixOS Updates Monitor with Pango markup tooltip

FLAKE_DIR="$HOME/dotfiles/thinkpad-p14s-gen5"
CACHE_FILE="$HOME/.cache/waybar-nix-updates"
CACHE_DURATION=3600
mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null || true

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

emit() {
  local output
  output=$(json_output "$1" "$2" "$3")
  printf '%s\n' "$output"
  { printf '%s\n' "$output" > "$CACHE_FILE"; } 2>/dev/null || true
}

if [ -f "$CACHE_FILE" ]; then
  cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
  if [ $cache_age -lt $CACHE_DURATION ] && jq -e . "$CACHE_FILE" >/dev/null 2>&1; then
    jq -c '.tooltip |= gsub("\\\\n"; "\n")' "$CACHE_FILE"
    exit 0
  fi
fi

if [ ! -d "$FLAKE_DIR" ]; then
  emit "󰄬" "Flake directory not found" "ok"
  exit 0
fi

cd "$FLAKE_DIR" || exit 1

if [ ! -f "flake.lock" ]; then
  emit "󰄬" "flake.lock not found" "ok"
  exit 0
fi

source "$HOME/.config/waybar/scripts/theme-colors.sh" 2>/dev/null || { C_FG="#d4d4d4"; C_DIM="#9d9d9d"; C_ACCENT="#d4c080"; C_GREEN="#90c090"; }

lock_age=$(($(date +%s) - $(stat -c %Y "flake.lock" 2>/dev/null || echo 0)))
days_old=$((lock_age / 86400))
hours_old=$(((lock_age % 86400) / 3600))

# Overlay versions
cc=$(pango_escape "$(grep 'version = ' overlays/claude-code-latest.nix 2>/dev/null | sed 's/.*"\(.*\)".*/\1/')")
vs=$(pango_escape "$(grep 'version = ' overlays/vscode-latest.nix 2>/dev/null | sed 's/.*"\(.*\)".*/\1/')")
oc=$(pango_escape "$(grep 'version = ' overlays/opencode-latest.nix 2>/dev/null | sed 's/.*"\(.*\)".*/\1/')")
ll=$(pango_escape "$(grep 'version = ' overlays/llama-cpp-latest.nix 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')")

ov="<span color='$C_DIM'>Claude Code</span>  <span color='$C_FG'>$cc</span>"
ov="$ov\n<span color='$C_DIM'>VS Code</span>      <span color='$C_FG'>$vs</span>"
ov="$ov\n<span color='$C_DIM'>OpenCode</span>     <span color='$C_FG'>$oc</span>"
ov="$ov\n<span color='$C_DIM'>llama.cpp</span>    <span color='$C_FG'>b$ll</span>"

if [ $days_old -gt 7 ]; then
  tooltip="<span color='$C_ACCENT'><b>󰏔 UPDATE AVAILABLE</b></span>\n"
  tooltip="$tooltip\n<span color='$C_DIM'>Last update:</span> <span color='$C_ACCENT'>${days_old} days ago</span>"
  tooltip="$tooltip\n\n$ov"
  tooltip="$tooltip\n\n<span color='$C_DIM'>Click to update</span>"

  emit "󰏔 ${days_old}d" "$tooltip" "updates"
else
  if [ $days_old -eq 0 ]; then
    [ $hours_old -eq 0 ] && time_str="just now" || time_str="${hours_old}h ago"
  elif [ $days_old -eq 1 ]; then
    time_str="yesterday"
  else
    time_str="${days_old}d ago"
  fi

  tooltip="<span color='$C_GREEN'><b>󰄬 Up to date</b></span> <span color='$C_DIM'>($time_str)</span>"
  tooltip="$tooltip\n\n$ov"

  emit "󰄬" "$tooltip" "ok"
fi
