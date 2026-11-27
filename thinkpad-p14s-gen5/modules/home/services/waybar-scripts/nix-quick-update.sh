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
  # Selective update matching the update() shell function (overlay-updates.nix).
  # The Hyprland flake inputs are left out (update-hyprland) and nixpkgs-llama
  # stays pinned (update-llama).
  nix flake update disko home-manager jail-nix nix-index-database nixos-hardware nixpkgs sops-nix 2>&1
  echo ""
  echo "=== Overlay updates ==="
  # update-overlays is a zsh function (overlay-updates.nix): it bumps every
  # quick overlay (VS Code, Claude Code, OpenCode, ForgeCode, Codex, RunPod,
  # pnpm) plus the agent skills, the same step the `update` function runs.
  zsh -ic 'update-overlays' 2>&1
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
