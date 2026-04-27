#!/usr/bin/env bash
# Quick NixOS update — runs in background, notifies on completion
# No terminal needed — just a notification + waybar refresh

FLAKE_DIR="$HOME/dotfiles/thinkpad-p14s-gen5"
LOG="/tmp/nix-quick-update.log"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/nix-quick-update.lock"

# Prevent double-run
exec 9>"$LOCK"
if ! flock -n 9; then
  notify-send "NixOS Update" "󰏔 Already running..." -i system-software-update
  exit 0
fi

notify-send "NixOS Update" "󰏔 Updating flake inputs..." -i system-software-update

cd "$FLAKE_DIR" || exit 1

# Update flake + overlays (captures output)
{
  echo "=== $(date) ==="
  nix flake update 2>&1
  echo ""
  echo "=== Overlay updates ==="
  # Source shell functions (they're defined in zsh initContent)
  # Use direct API calls instead for background execution
  update_count=0

  # Check Claude Code
  CC_LATEST=$(curl -s "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" 2>/dev/null | jq -r '.version')
  CC_CURRENT=$(grep 'version = ' overlays/claude-code-latest.nix | sed 's/.*"\(.*\)".*/\1/')
  [ -n "$CC_LATEST" ] && [ "$CC_LATEST" != "null" ] && [ "$CC_LATEST" != "$CC_CURRENT" ] && echo "Claude Code: $CC_CURRENT → $CC_LATEST" && update_count=$((update_count + 1))

  # Check VS Code
  VS_LATEST=$(curl -s "https://update.code.visualstudio.com/api/update/linux-x64/stable/latest" 2>/dev/null | jq -r '.productVersion')
  VS_CURRENT=$(grep 'version = ' overlays/vscode-latest.nix | sed 's/.*"\(.*\)".*/\1/')
  [ -n "$VS_LATEST" ] && [ "$VS_LATEST" != "null" ] && [ "$VS_LATEST" != "$VS_CURRENT" ] && echo "VS Code: $VS_CURRENT → $VS_LATEST" && update_count=$((update_count + 1))

  # Check OpenCode
  OC_LATEST=$(curl -s "https://api.github.com/repos/anomalyco/opencode/releases/latest" 2>/dev/null | jq -r '.tag_name' | sed 's/^v//')
  OC_CURRENT=$(grep 'version = ' overlays/opencode-latest.nix | sed 's/.*"\(.*\)".*/\1/')
  [ -n "$OC_LATEST" ] && [ "$OC_LATEST" != "null" ] && [ "$OC_LATEST" != "$OC_CURRENT" ] && echo "OpenCode: $OC_CURRENT → $OC_LATEST" && update_count=$((update_count + 1))

  echo ""
  echo "Overlay updates available: $update_count"
} > "$LOG" 2>&1

# Count changed inputs (grep -c can return multi-line, take first number only)
CHANGED=$(grep -c "Updated\|updated" "$LOG" 2>/dev/null | head -1 || echo "0")
CHANGED=${CHANGED//[^0-9]/}  # Strip non-digits
[ -z "$CHANGED" ] && CHANGED=0

# Clear waybar cache to refresh the module
rm -f "$HOME/.cache/waybar-nix-updates"
pkill -RTMIN+5 waybar 2>/dev/null

# Notify result
if [ "$CHANGED" -gt 0 ]; then
  notify-send "NixOS Update" "󰏔 Flake updated ($CHANGED inputs changed)\n\nRun 'rebuild' to apply" -i system-software-update
else
  notify-send "NixOS Update" "󰄬 Already up to date" -i system-software-update
fi
