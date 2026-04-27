# Hyprland helper scripts.
{ pkgs, hyprlandPkg }:

let
  # YouTube PiP toggle - launch / show+pin / unpin+hide
  # Always resets to detached mode so the opacity daemon takes over
  youtube-toggle = pkgs.writeShellScriptBin "youtube-toggle" ''
    CLASS="brave-youtube.com__-Default"
    JQ="${pkgs.jq}/bin/jq"
    STATE_FILE="/tmp/youtube-pip-state"

    # Force detached mode: terminal-sized tile on the right side.
    reset_to_detached() {
      local addr="$1"
      local mon_info mon_x mon_y mon_lw mon_lh mon_top mon_bottom usable_h w h x y
      mon_info=$(hyprctl monitors -j | $JQ '.[] | select(.focused == true)')
      mon_x=$(echo "$mon_info" | $JQ -r '.x')
      mon_y=$(echo "$mon_info" | $JQ -r '.y')
      mon_lw=$(echo "$mon_info" | $JQ -r '.width / .scale | floor')
      mon_lh=$(echo "$mon_info" | $JQ -r '.height / .scale | floor')
      mon_top=$(echo "$mon_info" | $JQ -r '.reserved[1] // 32')
      mon_bottom=$(echo "$mon_info" | $JQ -r '.reserved[3] // 0')
      usable_h=$((mon_lh - mon_top - mon_bottom))
      w=$((mon_lw / 2 - 5))
      h=$((usable_h / 2 - 5))
      x=$((mon_x + mon_lw / 2 + 2))
      y=$((mon_y + mon_top + usable_h / 2 + 2))
      hyprctl --batch "\
        dispatch setfloating address:$addr ; \
        dispatch resizewindowpixel exact $w $h,address:$addr ; \
        dispatch movewindowpixel exact $x $y,address:$addr ; \
        dispatch setprop address:$addr rounding 12 lock ; \
        dispatch setprop address:$addr border_size 0 lock ; \
        dispatch setprop address:$addr no_shadow 0 lock ; \
        dispatch setprop address:$addr opacity 1.0 lock ; \
        dispatch setprop address:$addr opacity_inactive 1.0 lock ; \
        dispatch setprop address:$addr opacity_override 1 lock ; \
        dispatch setprop address:$addr opacity_inactive_override 1 lock ; \
        dispatch setprop address:$addr no_focus 0 lock" 2>/dev/null
      echo "detached" > "$STATE_FILE"
    }

    WIN=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$CLASS\") | .address" | head -1)

    if [ -z "$WIN" ]; then
      # Not running → launch and pre-clear any stale state (opacity daemon defaults to detached)
      rm -f "$STATE_FILE"
      brave --app=https://youtube.com/ &
      disown
      exit 0
    fi

    # Check if on special workspace (hidden)
    WS=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .workspace.name")
    if echo "$WS" | ${pkgs.gnugrep}/bin/grep -q "special"; then
      # Hidden → bring back, pin, focus, force detached PiP mode
      hyprctl dispatch movetoworkspacesilent "$(hyprctl activeworkspace -j | $JQ -r '.id'),address:$WIN"
      hyprctl dispatch pin address:$WIN
      hyprctl dispatch focuswindow address:$WIN
      reset_to_detached "$WIN"
    else
      # Visible → unpin, hide to special workspace, clear state
      hyprctl dispatch pin address:$WIN
      hyprctl dispatch movetoworkspacesilent special:youtube,address:$WIN
      rm -f "$STATE_FILE"
    fi
  '';

  # Twitch PiP toggle - launch / show+pin / unpin+hide
  # Mirrors youtube-toggle. Bottom-left placement to avoid overlap with YouTube PiP.
  twitch-toggle = pkgs.writeShellScriptBin "twitch-toggle" ''
    CLASS="brave-twitch.tv__-Default"
    JQ="${pkgs.jq}/bin/jq"
    STATE_FILE="/tmp/twitch-pip-state"

    reset_to_detached() {
      local addr="$1"
      local mon_info mon_x mon_y mon_lh x y
      mon_info=$(hyprctl monitors -j | $JQ '.[] | select(.focused == true)')
      mon_x=$(echo "$mon_info" | $JQ -r '.x')
      mon_y=$(echo "$mon_info" | $JQ -r '.y')
      mon_lh=$(echo "$mon_info" | $JQ -r '.height / .scale | floor')
      x=$((mon_x + 10))
      y=$((mon_y + mon_lh - 550))
      hyprctl --batch "\
        dispatch setfloating address:$addr ; \
        dispatch resizewindowpixel exact 960 540,address:$addr ; \
        dispatch movewindowpixel exact $x $y,address:$addr ; \
        dispatch setprop address:$addr rounding 12 lock ; \
        dispatch setprop address:$addr border_size 0 lock ; \
        dispatch setprop address:$addr no_shadow 0 lock ; \
        dispatch setprop address:$addr opacity 1.0 lock ; \
        dispatch setprop address:$addr opacity_inactive 0.85 lock ; \
        dispatch setprop address:$addr opacity_override 1 lock ; \
        dispatch setprop address:$addr opacity_inactive_override 1 lock ; \
        dispatch setprop address:$addr no_focus 0 lock" 2>/dev/null
      echo "detached" > "$STATE_FILE"
    }

    WIN=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$CLASS\") | .address" | head -1)

    if [ -z "$WIN" ]; then
      rm -f "$STATE_FILE"
      brave --app=https://twitch.tv/ &
      disown
      exit 0
    fi

    WS=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .workspace.name")
    if echo "$WS" | ${pkgs.gnugrep}/bin/grep -q "special"; then
      hyprctl dispatch movetoworkspacesilent "$(hyprctl activeworkspace -j | $JQ -r '.id'),address:$WIN"
      hyprctl dispatch pin address:$WIN
      hyprctl dispatch focuswindow address:$WIN
      reset_to_detached "$WIN"
    else
      hyprctl dispatch pin address:$WIN
      hyprctl dispatch movetoworkspacesilent special:twitch,address:$WIN
      rm -f "$STATE_FILE"
    fi
  '';

  # YouTube PiP dock toggle - immediate attach/detach for explicit controls
  # Attached: 480x270 mini-player centered below waybar
  # Detached: terminal-sized tile in the bottom-right corner
  youtube-pip-dock-toggle = pkgs.writeShellScriptBin "youtube-pip-dock-toggle" ''
    CLASS="brave-youtube.com__-Default"
    JQ="${pkgs.jq}/bin/jq"
    STATE_FILE="/tmp/youtube-pip-state"

    # Find YouTube window
    WIN=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$CLASS\") | .address" | head -1)

    if [ -z "$WIN" ]; then
      brave --app=https://youtube.com/ &
      disown
      exit 0
    fi

    # If hidden on special workspace, bring back as PiP first
    WS=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .workspace.name")
    STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "detached")
    if echo "$WS" | ${pkgs.gnugrep}/bin/grep -q "special"; then
      hyprctl dispatch movetoworkspacesilent "$(hyprctl activeworkspace -j | $JQ -r '.id'),address:$WIN"
      hyprctl dispatch setfloating address:$WIN
      STATE="detached"
    fi

    # Get focused monitor geometry (logical pixels, scale-aware)
    FOCUSED_MON=$(hyprctl activeworkspace -j | $JQ -r '.monitor')
    MON_INFO=$(hyprctl monitors -j | $JQ ".[] | select(.name == \"$FOCUSED_MON\")")
    MON_X=$(echo "$MON_INFO" | $JQ -r '.x')
    MON_Y=$(echo "$MON_INFO" | $JQ -r '.y')
    MON_LW=$(echo "$MON_INFO" | $JQ -r '.width / .scale | floor')
    MON_LH=$(echo "$MON_INFO" | $JQ -r '.height / .scale | floor')
    MON_TOP=$(echo "$MON_INFO" | $JQ -r '.reserved[1] // 32')
    MON_BOTTOM=$(echo "$MON_INFO" | $JQ -r '.reserved[3] // 0')
    USABLE_H=$((MON_LH - MON_TOP - MON_BOTTOM))

    if [ "$STATE" = "detached" ]; then
      # Attach: 480x270 fused with waybar — no gap, no rounding, seamless
      X=$((MON_X + (MON_LW - 480) / 2))
      Y=$((MON_Y + 32))
      hyprctl --batch "\
        dispatch setfloating address:$WIN ; \
        dispatch resizewindowpixel exact 480 270,address:$WIN ; \
        dispatch movewindowpixel exact $X $Y,address:$WIN ; \
        dispatch setprop address:$WIN rounding 0 lock ; \
        dispatch setprop address:$WIN border_size 0 lock ; \
        dispatch setprop address:$WIN no_shadow 1 lock ; \
        dispatch setprop address:$WIN opacity 1.0 lock ; \
        dispatch setprop address:$WIN opacity_inactive 1.0 lock ; \
        dispatch setprop address:$WIN opacity_override 1 lock ; \
        dispatch setprop address:$WIN opacity_inactive_override 1 lock ; \
        dispatch setprop address:$WIN no_focus 1 lock"
      PINNED=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .pinned")
      [ "$PINNED" != "true" ] && hyprctl dispatch pin address:$WIN
      echo "attached" > "$STATE_FILE"
    else
      # Detach: terminal-sized bottom-right tile — matches the regular split layout
      W=$((MON_LW / 2 - 5))
      H=$((USABLE_H / 2 - 5))
      X=$((MON_X + MON_LW / 2 + 2))
      Y=$((MON_Y + MON_TOP + USABLE_H / 2 + 2))
      hyprctl --batch "\
        dispatch setfloating address:$WIN ; \
        dispatch resizewindowpixel exact $W $H,address:$WIN ; \
        dispatch movewindowpixel exact $X $Y,address:$WIN ; \
        dispatch setprop address:$WIN rounding 12 lock ; \
        dispatch setprop address:$WIN border_size 0 lock ; \
        dispatch setprop address:$WIN no_shadow 0 lock ; \
        dispatch setprop address:$WIN opacity 1.0 lock ; \
        dispatch setprop address:$WIN opacity_inactive 1.0 lock ; \
        dispatch setprop address:$WIN opacity_override 1 lock ; \
        dispatch setprop address:$WIN opacity_inactive_override 1 lock ; \
        dispatch setprop address:$WIN no_focus 0 lock"
      PINNED=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .pinned")
      [ "$PINNED" != "true" ] && hyprctl dispatch pin address:$WIN
      echo "detached" > "$STATE_FILE"
    fi
  '';

  # Twitch PiP dock toggle - immediate attach/detach for explicit controls
  # Attached: 480x270 mini-player below waybar, left side to avoid YouTube
  # Detached: 960x540 PiP in bottom-left corner
  twitch-pip-dock-toggle = pkgs.writeShellScriptBin "twitch-pip-dock-toggle" ''
    CLASS="brave-twitch.tv__-Default"
    JQ="${pkgs.jq}/bin/jq"
    STATE_FILE="/tmp/twitch-pip-state"

    WIN=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$CLASS\") | .address" | head -1)

    if [ -z "$WIN" ]; then
      brave --app=https://twitch.tv/ &
      disown
      exit 0
    fi

    WS=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .workspace.name")
    STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "detached")
    if echo "$WS" | ${pkgs.gnugrep}/bin/grep -q "special"; then
      hyprctl dispatch movetoworkspacesilent "$(hyprctl activeworkspace -j | $JQ -r '.id'),address:$WIN"
      hyprctl dispatch setfloating address:$WIN
      STATE="detached"
    fi

    FOCUSED_MON=$(hyprctl activeworkspace -j | $JQ -r '.monitor')
    MON_INFO=$(hyprctl monitors -j | $JQ ".[] | select(.name == \"$FOCUSED_MON\")")
    MON_X=$(echo "$MON_INFO" | $JQ -r '.x')
    MON_Y=$(echo "$MON_INFO" | $JQ -r '.y')
    MON_LH=$(echo "$MON_INFO" | $JQ -r '.height / .scale | floor')

    if [ "$STATE" = "detached" ]; then
      X=$((MON_X + 10))
      Y=$((MON_Y + 32))
      hyprctl --batch "\
        dispatch setfloating address:$WIN ; \
        dispatch resizewindowpixel exact 480 270,address:$WIN ; \
        dispatch movewindowpixel exact $X $Y,address:$WIN ; \
        dispatch setprop address:$WIN rounding 0 lock ; \
        dispatch setprop address:$WIN border_size 0 lock ; \
        dispatch setprop address:$WIN no_shadow 1 lock ; \
        dispatch setprop address:$WIN opacity 1.0 lock ; \
        dispatch setprop address:$WIN opacity_inactive 1.0 lock ; \
        dispatch setprop address:$WIN opacity_override 1 lock ; \
        dispatch setprop address:$WIN opacity_inactive_override 1 lock ; \
        dispatch setprop address:$WIN no_focus 1 lock"
      PINNED=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .pinned")
      [ "$PINNED" != "true" ] && hyprctl dispatch pin address:$WIN
      echo "attached" > "$STATE_FILE"
    else
      X=$((MON_X + 10))
      Y=$((MON_Y + MON_LH - 550))
      hyprctl --batch "\
        dispatch setfloating address:$WIN ; \
        dispatch resizewindowpixel exact 960 540,address:$WIN ; \
        dispatch movewindowpixel exact $X $Y,address:$WIN ; \
        dispatch setprop address:$WIN rounding 12 lock ; \
        dispatch setprop address:$WIN border_size 0 lock ; \
        dispatch setprop address:$WIN no_shadow 0 lock ; \
        dispatch setprop address:$WIN opacity 1.0 lock ; \
        dispatch setprop address:$WIN opacity_inactive 0.85 lock ; \
        dispatch setprop address:$WIN opacity_override 1 lock ; \
        dispatch setprop address:$WIN opacity_inactive_override 1 lock ; \
        dispatch setprop address:$WIN no_focus 0 lock"
      PINNED=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .pinned")
      [ "$PINNED" != "true" ] && hyprctl dispatch pin address:$WIN
      echo "detached" > "$STATE_FILE"
    fi
  '';

  # YouTube PiP dock toggle from MPRIS - double-click guard for accidental clicks
  youtube-pip-toggle = pkgs.writeShellScriptBin "youtube-pip-toggle" ''
    CLICK_FILE="/tmp/youtube-pip-dblclick"
    NOW=$(date +%s%3N)
    if [ -f "$CLICK_FILE" ]; then
      LAST=$(cat "$CLICK_FILE")
      DIFF=$((NOW - LAST))
      if [ "$DIFF" -lt 400 ]; then
        rm -f "$CLICK_FILE"
      else
        echo "$NOW" > "$CLICK_FILE"
        exit 0
      fi
    else
      echo "$NOW" > "$CLICK_FILE"
      exit 0
    fi

    exec ${youtube-pip-dock-toggle}/bin/youtube-pip-dock-toggle
  '';

  # Blue light filter toggle - cycles through temperature levels
  bluelight-toggle = pkgs.writeShellScriptBin "bluelight-toggle" ''
    set -euo pipefail

    STATE_FILE="$HOME/.config/bluelight-state"

    # Read current state (default to off)
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

    # Temperature levels for eye protection:
    # 5500K = Slight warmth (afternoon sun)
    # 4500K = Warm (sunset)
    # 3500K = Very warm (golden hour)
    # 2500K = Candlelight
    # 2000K = Deep amber (late night)
    # 1500K = Very deep amber (pre-sleep)
    # 1200K = Maximum protection (extreme night mode)
    # 1000K = Ultra deep (absolute minimum)
    case "$CURRENT" in
      off|6500) NEXT="5500"; TEMP=5500; DESC="󰖨  Level 1 (5500K - Afternoon)" ;;
      5500)     NEXT="4500"; TEMP=4500; DESC="󰖨  Level 2 (4500K - Sunset)" ;;
      4500)     NEXT="3500"; TEMP=3500; DESC="󰖨  Level 3 (3500K - Golden hour)" ;;
      3500)     NEXT="2500"; TEMP=2500; DESC="󰖨  Level 4 (2500K - Candlelight)" ;;
      2500)     NEXT="2000"; TEMP=2000; DESC="󱩌  Level 5 (2000K - Late night)" ;;
      2000)     NEXT="1500"; TEMP=1500; DESC="󱩌  Level 6 (1500K - Pre-sleep)" ;;
      1500)     NEXT="1200"; TEMP=1200; DESC="󱩌  Level 7 (1200K - Maximum)" ;;
      1200)     NEXT="1000"; TEMP=1000; DESC="󱩌  Level 8 (1000K - Ultra deep)" ;;
      1000)     NEXT="off";  TEMP=0;    DESC="󰖙  Filter Off" ;;
      *)        NEXT="5500"; TEMP=5500; DESC="󰖨  Level 1 (5500K - Afternoon)" ;;
    esac

    # Kill existing hyprsunset gracefully
    ${pkgs.procps}/bin/pkill -TERM hyprsunset 2>/dev/null && sleep 0.2 || true
    ${pkgs.procps}/bin/pkill -KILL hyprsunset 2>/dev/null || true

    # Start with new temperature (if not off)
    if [ "$NEXT" != "off" ]; then
      ${pkgs.hyprsunset}/bin/hyprsunset -t $TEMP &
      disown
    fi

    echo "$NEXT" > "$STATE_FILE"
    ${pkgs.libnotify}/bin/notify-send -t 2000 "Blue Light Filter" "$DESC" -i "weather-clear-night"
  '';

  # Quick off - instantly disable blue light filter
  bluelight-off = pkgs.writeShellScriptBin "bluelight-off" ''
    ${pkgs.procps}/bin/pkill hyprsunset 2>/dev/null || true
    echo "off" > "$HOME/.config/bluelight-state"
    ${pkgs.libnotify}/bin/notify-send -t 1500 "Blue Light Filter" "󰖙  Disabled" -i "weather-clear"
  '';

  # Auto-enable blue light filter at boot based on time of day
  # Night hours: 20:00-07:00 → auto-enable at 2000K
  bluelight-auto = pkgs.writeShellScriptBin "bluelight-auto" ''
    STATE_FILE="$HOME/.config/bluelight-state"
    HOUR=$(date +%H)

    # Night hours: 20:00 (8pm) to 07:00 (7am)
    if [ "$HOUR" -ge 20 ] || [ "$HOUR" -lt 7 ]; then
      # Check if already running
      if ${pkgs.procps}/bin/pgrep -x hyprsunset > /dev/null; then
        exit 0
      fi

      # Set to 2000K for night mode
      TEMP=2000
      echo "2000" > "$STATE_FILE"
      ${pkgs.hyprsunset}/bin/hyprsunset -t $TEMP &
      disown
    fi
  '';

  # Toggle performance mode - cycles through 3 modes
  # BATTERY SAVER → BALANCED → MAX PERFORMANCE → BATTERY SAVER
  perf-mode = pkgs.writeShellScriptBin "perf-mode" ''
    set -euo pipefail

    STATE_FILE="$HOME/.config/perf-mode-state"

    # Read current state (default to balanced)
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "balanced")

    case "$CURRENT" in
      battery)
        # Switch to BALANCED (some animations, moderate FPS)
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:glow:enabled false
        echo "balanced" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "⚖️ Balanced Mode" "Animations ON, moderate savings" -i "battery-good"
        ;;
      balanced)
        # Switch to MAX PERFORMANCE (all effects, high FPS)
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 60
        hyprctl keyword decoration:blur:enabled true
        hyprctl keyword decoration:shadow:enabled true
        hyprctl keyword decoration:glow:enabled true
        echo "max" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "🚀 Max Performance" "All effects ON (uses more power)" -i "video-display"
        ;;
      max|*)
        # Switch to BATTERY SAVER (no effects, minimal FPS)
        hyprctl keyword animations:enabled false
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:blur:enabled false
        hyprctl keyword decoration:shadow:enabled false
        hyprctl keyword decoration:glow:enabled false
        echo "battery" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "🔋 Battery Saver" "All effects OFF (max battery life)" -i "battery-caution"
        ;;
    esac
  '';

  # Auto-apply performance mode on battery at startup
  perf-mode-auto = pkgs.writeShellScriptBin "perf-mode-auto" ''
    STATE_FILE="$HOME/.config/perf-mode-state"

    # Check if on battery
    if [ -f /sys/class/power_supply/BAT0/status ]; then
      BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status)

      if [ "$BAT_STATUS" = "Discharging" ]; then
        # On battery - enable battery saver mode
        hyprctl keyword animations:enabled false
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:blur:enabled false
        hyprctl keyword decoration:shadow:enabled false
        hyprctl keyword decoration:glow:enabled false
        echo "battery" > "$STATE_FILE"
      else
        # On AC - restore saved state or default to balanced
        SAVED_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "balanced")
        case "$SAVED_STATE" in
          battery)
            hyprctl keyword animations:enabled false
            hyprctl keyword misc:render_unfocused_fps 10
            hyprctl keyword decoration:blur:enabled false
            hyprctl keyword decoration:shadow:enabled false
            hyprctl keyword decoration:glow:enabled false
            ;;
          max)
            hyprctl keyword animations:enabled true
            hyprctl keyword misc:render_unfocused_fps 60
            hyprctl keyword decoration:blur:enabled true
            hyprctl keyword decoration:shadow:enabled true
            hyprctl keyword decoration:glow:enabled true
            ;;
          *)
            hyprctl keyword animations:enabled true
            hyprctl keyword misc:render_unfocused_fps 10
            hyprctl keyword decoration:glow:enabled false
            ;;
        esac
      fi
    fi
  '';

  # Battery-aware performance daemon (monitors power state changes via upower events)
  perf-mode-daemon = pkgs.writeShellScriptBin "perf-mode-daemon" ''
    # Monitors power state via upower events (instant reaction, zero idle CPU)

    STATE_FILE="$HOME/.config/perf-mode-state"
    LAST_STATUS=""

    apply_mode() {
      local status="$1"
      if [ "$status" = "Discharging" ] && [ "$LAST_STATUS" != "Discharging" ]; then
        hyprctl keyword animations:enabled false
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:blur:enabled false
        hyprctl keyword decoration:shadow:enabled false
        hyprctl keyword decoration:glow:enabled false
        echo "battery" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "Battery Mode" "󰂃 Battery saver auto-enabled" -i "battery-good"
        LAST_STATUS="$status"
      elif [ "$status" != "Discharging" ] && [ "$LAST_STATUS" = "Discharging" ]; then
        hyprctl keyword animations:enabled true
        hyprctl keyword misc:render_unfocused_fps 10
        hyprctl keyword decoration:glow:enabled false
        echo "balanced" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "AC Power" "󰂄 Balanced mode restored" -i "battery-full-charging"
        LAST_STATUS="$status"
      elif [ -z "$LAST_STATUS" ]; then
        LAST_STATUS="$status"
      fi
    }

    # Apply initial state
    if [ -f /sys/class/power_supply/BAT0/status ]; then
      apply_mode "$(cat /sys/class/power_supply/BAT0/status)"
    fi

    # Listen for upower events (blocks until event, zero CPU when idle)
    ${pkgs.upower}/bin/upower --monitor-detail | while read -r line; do
      if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "state:"; then
        state=$(echo "$line" | ${pkgs.gnused}/bin/sed 's/.*state:\s*//' | ${pkgs.findutils}/bin/xargs)
        case "$state" in
          discharging) apply_mode "Discharging" ;;
          charging|fully-charged) apply_mode "Charging" ;;
        esac
      fi
    done
  '';

  # Quick notes - Open floating terminal with nvim for quick note-taking
  quick-notes = pkgs.writeShellScriptBin "quick-notes" ''
        set -euo pipefail

        # Notes directory (create if doesn't exist)
        NOTES_DIR="$HOME/Notes"
        mkdir -p "$NOTES_DIR"

        # Generate filename with timestamp
        DATE=$(date +%Y-%m-%d)
        TIME=$(date +%H-%M-%S)
        NOTE_FILE="$NOTES_DIR/quick-$DATE-$TIME.md"

        # Create note template
        cat > "$NOTE_FILE" << EOF
    # Quick Note - $(date '+%Y-%m-%d %H:%M')

    ---

    EOF

        # Open in floating Ghostty with nvim
        # The window rule in Hyprland will make it float
        ghostty --class="quick-notes" -e nvim "+normal G" "$NOTE_FILE"
  '';

  # Hyprland keybindings cheatsheet - shows all shortcuts in a notification
  hypr-keys = pkgs.writeShellScriptBin "hypr-keys" ''
        # Get current states
        PERF_STATE=$(cat "$HOME/.config/perf-mode-state" 2>/dev/null || echo "balanced")
        BAT_MODE=$(cat "$HOME/.config/battery-mode-state" 2>/dev/null || echo "conservation")
        BLUELIGHT=$(cat "$HOME/.config/bluelight-state" 2>/dev/null || echo "off")

        case "$PERF_STATE" in
          battery) PERF_ICON="󰂃" ;;
          max)     PERF_ICON="🚀" ;;
          *)       PERF_ICON="󰂄" ;;
        esac

        case "$BAT_MODE" in
          conservation) BAT_ICON="󰂃 55-60%" ;;
          balanced) BAT_ICON="󰂀 75-80%" ;;
          full) BAT_ICON="󰁹 95-100%" ;;
          *) BAT_ICON="?" ;;
        esac

        if [ "$BLUELIGHT" = "off" ]; then
          BL_ICON="󰖙 Off"
        else
          BL_ICON="󰖨 $BLUELIGHT K"
        fi

        INFO="<b>═══ APPS ═══</b>
    <tt>Super+Return</tt>    Terminal (Ghostty)
    <tt>Super+B</tt>         Browser (Brave)
    <tt>Super+E</tt>         Files (Nemo)
    <tt>Super+D</tt>         App launcher
    <tt>Super+A</tt>         Audio panel
    <tt>Super+Y</tt>         YouTube PiP (show/hide)
    <tt>Super+U</tt>         Twitch PiP (show/hide)
    <tt>Super+V</tt>         Clipboard history
    <tt>Super+O</tt>         Quick notes
    <tt>Super+I</tt>         System info (hyprland)
    <tt>Super+Shift+I</tt>   System info (detailed)
    <tt>Super+Z</tt>         Freeze/unfreeze window

    <b>═══ WINDOWS ═══</b>
    <tt>Super+Q</tt>         Kill window
    <tt>Super+Shift+Q</tt>   Force kill
    <tt>Super+F</tt>         Fullscreen
    <tt>Super+Shift+F</tt>   Fullscreen (keep bar)
    <tt>Super+Space</tt>     Float toggle
    <tt>Super+P</tt>         Pin (all workspaces)
    <tt>Super+T</tt>         Toggle split
    <tt>Super+W</tt>         Center floating
    <tt>Super+G</tt>         Group windows (tabs)
    <tt>Super+[ ]</tt>       Switch tabs in group
    <tt>Super+Ctrl+[ ]</tt>  Reorder tabs in group
    <tt>Super+Tab</tt>       Last focused window
    <tt>Alt+Tab</tt>         Cycle windows
    <tt>Super+Ctrl+Shift+HJKL</tt> Swap positions
      Floating windows snap to edges

    <b>═══ WORKSPACES ═══</b>
    <tt>Super+1-9</tt>       Switch workspace
    <tt>Super+Shift+1-9</tt> Move window to WS
    <tt>Super+Ctrl+1-5</tt>  Focus WS on this monitor
    <tt>Super+Shift+Tab</tt> Swap WS between monitors
    <tt>Super+Ctrl+M</tt>    WS to next monitor
    <tt>Super+Alt+H/L</tt>   Window to prev/next WS
    <tt>Super+S</tt>         Scratchpad toggle
    <tt>Super+Shift+S</tt>   Move to scratchpad
    <tt>Super+-</tt>         Minimize to special
    <tt>Super+Shift+-</tt>   Show minimized

    <b>═══ SCREENSHOTS (grimblast) ═══</b>
    <tt>Print</tt>              Region → clipboard
    <tt>Super+Print</tt>       Region → file
    <tt>Shift+Print</tt>       Full → clipboard
    <tt>Super+Shift+Print</tt> Full → file
    <tt>Super+Ctrl+Print</tt>  Window → clipboard

    <b>═══ SYSTEM ═══</b>
    <tt>Super+Escape</tt>    Lock screen
    <tt>Super+Shift+Esc</tt> Power off (graceful)
    <tt>Super+Ctrl+Esc</tt>  Reboot (graceful)
    <tt>Super+Alt+Esc</tt>   Suspend
    <tt>Super+Ctrl+Shift+Esc</tt> Monitors off
    <tt>Super+F1</tt>        This cheatsheet
    <tt>Super+F3</tt>        Keyboard FR/US
    <tt>Super+Shift+R</tt>   Restart Waybar
    <tt>Super+C</tt>         Color picker
    <tt>Super+Shift+C</tt>   Window inspector (hyprprop)

    <b>═══ WIFI ═══</b>
    <tt>Super+F2</tt>         Reconnect WiFi
    <tt>Super+Shift+F2</tt>   Scan & connect
    <tt>Super+Ctrl+F2</tt>    Toggle WiFi on/off

    <b>═══ BATTERY & DISPLAY ═══</b>
    <tt>Super+M</tt>         Battery mode → $BAT_ICON
    <tt>Super+Shift+M</tt>   Performance → $PERF_ICON $PERF_STATE
    <tt>Super+N</tt>         Blue light → $BL_ICON
    <tt>Super+Shift+N</tt>   Blue light off
    <tt>Super+Shift+T</tt>   Toggle touchpad

    <b>═══ MALWARE LAB ═══</b>
    <tt>Super+X</tt>         Lab menu (FLARE-VM + REMnux)
      Start/stop/revert VMs, killswitch, snapshots

    <b>═══ RESIZE ═══</b>
    <tt>Super+Ctrl+HJKL</tt> Resize window
    <tt>Super+Drag</tt>      Move window
    <tt>Super+RClick</tt>    Resize window"

        ${pkgs.libnotify}/bin/notify-send -t 20000 "⌨ Hyprland Shortcuts" "$INFO" -i "input-keyboard"
  '';

  # System info panel - Shows system stats in a notification or floating window
  sysinfo-panel = pkgs.writeShellScriptBin "sysinfo-panel" ''
        set -euo pipefail

        # Colors for output
        BOLD='\033[1m'
        DIM='\033[2m'
        RESET='\033[0m'
        YELLOW='\033[33m'
        CYAN='\033[36m'
        GREEN='\033[32m'
        RED='\033[31m'

        # Gather system info
        HOSTNAME=$(hostname)
        KERNEL=$(uname -r)
        UPTIME=$(uptime -p | sed 's/up //')

        # CPU info
        CPU_MODEL=$(${pkgs.gawk}/bin/awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo)
        CPU_USAGE=$(${pkgs.procps}/bin/ps -A -o pcpu | ${pkgs.gawk}/bin/awk '{s+=$1} END {printf "%.1f", s}')
        CPU_TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | ${pkgs.gawk}/bin/awk '{printf "%.1f", $1/1000}')

        # Memory info
        MEM_INFO=$(free -h | ${pkgs.gawk}/bin/awk '/^Mem:/{print $3 "/" $2}')
        MEM_PERCENT=$(free | ${pkgs.gawk}/bin/awk '/^Mem:/{printf "%.0f", $3/$2*100}')

        # Disk info
        DISK_INFO=$(df -h / | ${pkgs.gawk}/bin/awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')

        # Battery info
        if [ -f /sys/class/power_supply/BAT0/capacity ]; then
          BAT_CAP=$(cat /sys/class/power_supply/BAT0/capacity)
          BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status)
          # Get charge thresholds if available
          if [ -f /sys/class/power_supply/BAT0/charge_control_start_threshold ]; then
            BAT_START=$(cat /sys/class/power_supply/BAT0/charge_control_start_threshold)
            BAT_END=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold)
            BAT_THRESHOLDS="[$BAT_START-$BAT_END%]"
          else
            BAT_THRESHOLDS=""
          fi
          BATTERY="$BAT_CAP% ($BAT_STATUS) $BAT_THRESHOLDS"
        else
          BATTERY="N/A"
        fi

        # Network info
        NET_IFACE=$(${pkgs.iproute2}/bin/ip route | ${pkgs.gawk}/bin/awk '/default/{print $5; exit}')
        if [ -n "$NET_IFACE" ]; then
          NET_IP=$(${pkgs.iproute2}/bin/ip -4 addr show "$NET_IFACE" | ${pkgs.gawk}/bin/awk '/inet /{print $2}' | cut -d'/' -f1)
          # Check for VPN
          if ${pkgs.iproute2}/bin/ip link show | ${pkgs.gnugrep}/bin/grep -q "proton"; then
            VPN_STATUS="🔒 VPN"
          else
            VPN_STATUS="No VPN"
          fi
        else
          NET_IP="Disconnected"
          VPN_STATUS="No VPN"
        fi

        # GPU info (AMD)
        if [ -f /sys/class/drm/card1/device/gpu_busy_percent ]; then
          GPU_USAGE=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo "N/A")
          GPU_USAGE="$GPU_USAGE%"
        else
          GPU_USAGE="N/A"
        fi

        # Services status
        LLAMA_STATUS=$(systemctl is-active llama-cpp 2>/dev/null || echo "inactive")
        PODMAN_STATUS=$(systemctl is-active podman 2>/dev/null || echo "inactive")

        # Blue light filter status
        BLUELIGHT_STATE=$(cat "$HOME/.config/bluelight-state" 2>/dev/null || echo "off")
        if [ "$BLUELIGHT_STATE" = "off" ]; then
          BLUELIGHT="Off"
        else
          BLUELIGHT="$BLUELIGHT_STATE K"
        fi

        # Format output for notification
        INFO="<b>󰌢 $HOSTNAME</b>
    <small>$DIM Kernel: $KERNEL</small>
    <small>$DIM Uptime: $UPTIME</small>

    <b>󰻠 CPU</b>  $CPU_USAGE% @ $CPU_TEMP°C
    <b>󰍛 RAM</b>  $MEM_INFO ($MEM_PERCENT%)
    <b>󰋊 Disk</b>  $DISK_INFO
    <b>󰂄 Battery</b>  $BATTERY
    <b>󰢮 GPU</b>  $GPU_USAGE

    <b>󰖩 Network</b>  $NET_IP
    <b>󰦝 VPN</b>  $VPN_STATUS
    <b>󰖨 Filter</b>  $BLUELIGHT

    <b>Services</b>
      llama.cpp: $LLAMA_STATUS
      Podman: $PODMAN_STATUS"

        # Show notification with longer timeout
        ${pkgs.libnotify}/bin/notify-send -t 10000 "System Info" "$INFO" -i "utilities-system-monitor"
  '';

  # WiFi management script - toggle, reconnect, or connect to new network
  wifi-manage = pkgs.writeShellScriptBin "wifi-manage" ''
    set -euo pipefail

    ACTION="''${1:-toggle}"

    case "$ACTION" in
      toggle)
        # Toggle WiFi on/off
        STATUS=$(nmcli radio wifi)
        if [ "$STATUS" = "enabled" ]; then
          nmcli radio wifi off
          ${pkgs.libnotify}/bin/notify-send -t 2000 "WiFi" "󰤭  WiFi disabled" -i "network-wireless-offline"
        else
          nmcli radio wifi on
          ${pkgs.libnotify}/bin/notify-send -t 2000 "WiFi" "󰤨  WiFi enabled" -i "network-wireless"
        fi
        ;;
      reconnect)
        # Force reconnect: reload ath11k driver + restart NetworkManager
        ${pkgs.libnotify}/bin/notify-send -t 2000 "WiFi" "󰤩  Reconnecting..." -i "network-wireless-acquiring"
        # Restart the WiFi interface
        nmcli radio wifi off
        sleep 1
        nmcli radio wifi on
        sleep 3
        # Check if connected
        if nmcli -t -f STATE general | grep -q "connected"; then
          SSID=$(nmcli -t -f ACTIVE,SSID dev wifi | grep "^yes" | cut -d: -f2)
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless"
        else
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Not connected. Try SUPER+SHIFT+W to pick a network" -i "network-wireless-offline"
        fi
        ;;
      scan)
        # Scan and connect via wofi menu
        ${pkgs.libnotify}/bin/notify-send -t 1500 "WiFi" "󰤩  Scanning..." -i "network-wireless-acquiring"
        nmcli radio wifi on 2>/dev/null || true
        sleep 1
        # Get available networks (deduplicated, sorted by signal)
        NETWORKS=$(nmcli -t -f SIGNAL,SECURITY,SSID dev wifi list --rescan yes 2>/dev/null | \
          ${pkgs.gawk}/bin/awk -F: 'NF>=3 && $3!="" {
            sig=$1; sec=$2; ssid=$3;
            icon = (sig+0 >= 75) ? "󰤨" : (sig+0 >= 50) ? "󰤥" : (sig+0 >= 25) ? "󰤢" : "󰤟";
            lock = (sec != "" && sec != "--") ? "󰌾" : "󰌿";
            if (!seen[ssid]++) printf "%s %s %s (%s%%)\n", icon, lock, ssid, sig
          }')

        if [ -z "$NETWORKS" ]; then
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "No networks found" -i "network-wireless-offline"
          exit 1
        fi

        # Show in wofi
        CHOSEN=$(echo "$NETWORKS" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "WiFi Network" --width 400 --height 300) || exit 0

        # Extract SSID (remove icon, lock, and signal from the line)
        SSID=$(echo "$CHOSEN" | ${pkgs.gnused}/bin/sed 's/^[^ ]* [^ ]* //' | ${pkgs.gnused}/bin/sed 's/ ([0-9]*%)$//')

        # Check if already a saved connection
        if nmcli -t -f NAME connection show | grep -qx "$SSID"; then
          nmcli connection up "$SSID" && \
            ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless" || \
            ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Failed to connect to $SSID" -i "network-wireless-offline"
        else
          # New network - check if it needs a password
          SECURITY=$(nmcli -t -f SSID,SECURITY dev wifi list | grep "^$SSID:" | head -1 | cut -d: -f2)
          if [ -n "$SECURITY" ] && [ "$SECURITY" != "--" ]; then
            # Ask for password via wofi
            PASSWORD=$(echo "" | ${pkgs.wofi}/bin/wofi --dmenu --prompt "Password for $SSID" --password --width 400 --height 100) || exit 0
            nmcli device wifi connect "$SSID" password "$PASSWORD" && \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID" -i "network-wireless" || \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Failed (wrong password?)" -i "network-wireless-offline"
          else
            nmcli device wifi connect "$SSID" && \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤨  Connected to $SSID (open)" -i "network-wireless" || \
              ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Failed to connect" -i "network-wireless-offline"
          fi
        fi
        ;;
    esac
  '';

  # Smart YouTube PiP opacity daemon
  # Transparent when focused window overlaps, opaque when working elsewhere
  youtube-opacity-daemon = pkgs.writeShellScriptBin "youtube-opacity-daemon" ''
    YT_CLASS="brave-youtube.com__-Default"
    JQ="${pkgs.jq}/bin/jq"
    SOCAT="${pkgs.socat}/bin/socat"
    LAST_STATE=""

    update_opacity() {
      local yt_addr
      yt_addr=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$YT_CLASS\") | .address" | head -1)
      [ -z "$yt_addr" ] && return

      # Skip when docked to waybar — opacity is locked to 1.0 in attached mode
      local pip_state
      pip_state=$(cat /tmp/youtube-pip-state 2>/dev/null || echo "detached")
      if [ "$pip_state" = "attached" ]; then
        LAST_STATE=""
        return
      fi

      # Get focused window info
      local focused_class focused_x focused_y focused_w focused_h
      focused_class=$(hyprctl activewindow -j | $JQ -r '.class // ""')

      # YouTube itself focused → opaque
      if [ "$focused_class" = "$YT_CLASS" ]; then
        if [ "$LAST_STATE" != "focused" ]; then
          hyprctl dispatch setprop "address:$yt_addr opacity_inactive 1.0 lock" 2>/dev/null
          LAST_STATE="focused"
        fi
        return
      fi

      # Get rectangles
      local yt_info focused_info
      yt_info=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$YT_CLASS\") | \"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])\"" | head -1)
      focused_info=$(hyprctl activewindow -j | $JQ -r '"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"')

      [ -z "$yt_info" ] || [ -z "$focused_info" ] && return

      read -r yx yy yw yh <<< "$yt_info"
      read -r fx fy fw fh <<< "$focused_info"

      # Check rectangle overlap
      local overlap=false
      if (( fx < yx + yw )) && (( fx + fw > yx )) && \
         (( fy < yy + yh )) && (( fy + fh > yy )); then
        overlap=true
      fi

      if [ "$overlap" = "true" ]; then
        # Focused window is under YouTube → very transparent
        if [ "$LAST_STATE" != "transparent" ]; then
          hyprctl dispatch setprop "address:$yt_addr opacity_inactive 0.4 lock" 2>/dev/null
          LAST_STATE="transparent"
        fi
      else
        # Focused window is elsewhere → fully opaque to keep watching
        if [ "$LAST_STATE" != "opaque" ]; then
          hyprctl dispatch setprop "address:$yt_addr opacity_inactive 1.0 lock" 2>/dev/null
          LAST_STATE="opaque"
        fi
      fi
    }

    # Listen to Hyprland IPC events
    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

    $SOCAT -U - "UNIX-CONNECT:$SOCKET" | while read -r line; do
      case "$line" in
        activewindow\>*|activewindowv2\>*|movewindow\>*|openwindow\>*)
          update_opacity
          ;;
      esac
    done
  '';

  # Smart Twitch PiP opacity daemon (mirror of youtube-opacity-daemon)
  twitch-opacity-daemon = pkgs.writeShellScriptBin "twitch-opacity-daemon" ''
    TW_CLASS="brave-twitch.tv__-Default"
    JQ="${pkgs.jq}/bin/jq"
    SOCAT="${pkgs.socat}/bin/socat"
    LAST_STATE=""

    update_opacity() {
      local tw_addr
      tw_addr=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$TW_CLASS\") | .address" | head -1)
      [ -z "$tw_addr" ] && return

      local pip_state
      pip_state=$(cat /tmp/twitch-pip-state 2>/dev/null || echo "detached")
      if [ "$pip_state" = "attached" ]; then
        LAST_STATE=""
        return
      fi

      local focused_class
      focused_class=$(hyprctl activewindow -j | $JQ -r '.class // ""')

      if [ "$focused_class" = "$TW_CLASS" ]; then
        if [ "$LAST_STATE" != "focused" ]; then
          hyprctl dispatch setprop "address:$tw_addr opacity_inactive 1.0 lock" 2>/dev/null
          LAST_STATE="focused"
        fi
        return
      fi

      local tw_info focused_info
      tw_info=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$TW_CLASS\") | \"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])\"" | head -1)
      focused_info=$(hyprctl activewindow -j | $JQ -r '"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])"')

      [ -z "$tw_info" ] || [ -z "$focused_info" ] && return

      read -r yx yy yw yh <<< "$tw_info"
      read -r fx fy fw fh <<< "$focused_info"

      local overlap=false
      if (( fx < yx + yw )) && (( fx + fw > yx )) && \
         (( fy < yy + yh )) && (( fy + fh > yy )); then
        overlap=true
      fi

      if [ "$overlap" = "true" ]; then
        if [ "$LAST_STATE" != "transparent" ]; then
          hyprctl dispatch setprop "address:$tw_addr opacity_inactive 0.4 lock" 2>/dev/null
          LAST_STATE="transparent"
        fi
      else
        if [ "$LAST_STATE" != "opaque" ]; then
          hyprctl dispatch setprop "address:$tw_addr opacity_inactive 1.0 lock" 2>/dev/null
          LAST_STATE="opaque"
        fi
      fi
    }

    SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

    $SOCAT -U - "UNIX-CONNECT:$SOCKET" | while read -r line; do
      case "$line" in
        activewindow\>*|activewindowv2\>*|movewindow\>*|openwindow\>*)
          update_opacity
          ;;
      esac
    done
  '';

  battery-mode = pkgs.writeShellScriptBin "battery-mode" ''
    # Battery charge mode selector for ThinkPad (requires sudo privileges)
    # Cycles through: Conservation -> Balanced -> Full -> Conservation

    STATE_FILE="$HOME/.config/battery-mode-state"

    # Read current mode (default to conservation if file doesn't exist)
    if [ -f "$STATE_FILE" ]; then
      CURRENT_MODE=$(cat "$STATE_FILE")
    else
      CURRENT_MODE="conservation"
    fi

    # Determine next mode
    case "$CURRENT_MODE" in
      conservation)
        NEXT_MODE="balanced"
        START=75
        STOP=80
        ICON="battery-good-charging"
        TITLE="Balanced Mode"
        DESC="Charge: 75-80% (daily use)"
        ;;
      balanced)
        NEXT_MODE="full"
        START=95
        STOP=100
        ICON="battery-full-charging"
        TITLE="Full Mode"
        DESC="Charge: 95-100% (travel)"
        ;;
      full)
        NEXT_MODE="conservation"
        START=55
        STOP=60
        ICON="battery-low-charging"
        TITLE="Conservation Mode"
        DESC="Charge: 55-60% (always plugged)"
        ;;
      *)
        NEXT_MODE="balanced"
        START=75
        STOP=80
        ICON="battery-good-charging"
        TITLE="Balanced Mode"
        DESC="Charge: 75-80% (daily use)"
        ;;
    esac

    # Apply settings using official TLP command
    if command -v tlp &> /dev/null; then
      sudo tlp setcharge $START $STOP BAT0

      if [ $? -eq 0 ]; then
        echo "$NEXT_MODE" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 3000 "$TITLE" "$DESC" -i "$ICON"
      else
        ${pkgs.libnotify}/bin/notify-send -t 3000 "Battery Error" "Failed to change mode" -i "dialog-error"
      fi
    else
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Error" "TLP is not installed" -i "dialog-error"
    fi
  '';

  touchpad-toggle = pkgs.writeShellScriptBin "touchpad-toggle" ''
    set -euo pipefail

    DEVICES_JSON=$(${hyprlandPkg}/bin/hyprctl devices -j)
    DEVICE=$(echo "$DEVICES_JSON" | ${pkgs.jq}/bin/jq -r '
      .mice
      | map(select((.name // "" | ascii_downcase | test("touchpad"))))
      | .[0].name // empty
    ')

    if [ -z "$DEVICE" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Aucun touchpad détecté" -i "dialog-error"
      exit 1
    fi

    STATE=$(echo "$DEVICES_JSON" | ${pkgs.jq}/bin/jq -r --arg device "$DEVICE" '
      .mice[]
      | select(.name == $device)
      | if .enabled == false then "false" else "true" end
    ')

    if [ "$STATE" = "true" ]; then
      ${hyprlandPkg}/bin/hyprctl keyword "device[$DEVICE]:enabled" false
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Désactivé" -i "input-touchpad"
    else
      ${hyprlandPkg}/bin/hyprctl keyword "device[$DEVICE]:enabled" true
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Activé" -i "input-touchpad"
    fi
  '';

  hypr-current-workspace-launch = pkgs.writeShellScriptBin "hypr-current-workspace-launch" ''
    set -euo pipefail

    if [ "$#" -lt 2 ]; then
      echo "usage: hypr-current-workspace-launch <class-regex> <command> [args...]" >&2
      exit 64
    fi

    CLASS_RE="$1"
    shift

    # Preserve URI/file actions from .desktop handlers. Plain app launches get
    # smart focusing; protocol launches should still be delivered to the app.
    if [ "$#" -gt 1 ]; then
      exec "$@"
    fi

    JQ="${pkgs.jq}/bin/jq"

    if ! CLIENTS_JSON=$(hyprctl clients -j 2>/dev/null); then
      exec "$@"
    fi

    WIN=$(printf '%s\n' "$CLIENTS_JSON" | "$JQ" -r --arg class_re "$CLASS_RE" '
      [
        .[]
        | select(
            ((.class // "") | test($class_re))
            or ((.initialClass // "") | test($class_re))
          )
        | select((.mapped // true) == true)
      ]
      | sort_by(if ((.focusHistoryID // 999999) < 0) then 999999 else (.focusHistoryID // 999999) end)
      | .[0].address // empty
    ')

    if [ -z "$WIN" ]; then
      exec "$@"
    fi

    ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | "$JQ" -r '.id // empty' || true)
    case "$ACTIVE_WS" in
      ""|null|-*) ;;
      *) hyprctl dispatch movetoworkspacesilent "$ACTIVE_WS,address:$WIN" >/dev/null 2>&1 || true ;;
    esac

    hyprctl dispatch focuswindow "address:$WIN" >/dev/null 2>&1 || true
  '';

  zapzap-current-workspace = pkgs.writeShellScriptBin "zapzap-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(com\.rtosta\.zapzap|zapzap|ZapZap)$' zapzap "$@"
  '';

  steam-current-workspace = pkgs.writeShellScriptBin "steam-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(steam|Steam)$' steam "$@"
  '';

  vesktop-current-workspace = pkgs.writeShellScriptBin "vesktop-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(vesktop|Vesktop)$' vesktop "$@"
  '';

  spotify-current-workspace = pkgs.writeShellScriptBin "spotify-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(spotify|Spotify)$' spotify "$@"
  '';

  telegram-current-workspace = pkgs.writeShellScriptBin "telegram-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(telegram-desktop|org\.telegram\.desktop|TelegramDesktop|Telegram)$' Telegram "$@"
  '';

  keepassxc-current-workspace = pkgs.writeShellScriptBin "keepassxc-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(org\.keepassxc\.KeePassXC|keepassxc|KeePassXC)$' keepassxc "$@"
  '';

  joplin-current-workspace = pkgs.writeShellScriptBin "joplin-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(@joplin/app-desktop|joplin|Joplin|joplin-desktop)$' joplin-desktop "$@"
  '';

  bruno-current-workspace = pkgs.writeShellScriptBin "bruno-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(bruno|Bruno)$' bruno "$@"
  '';

  rustdesk-current-workspace = pkgs.writeShellScriptBin "rustdesk-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(rustdesk|RustDesk)$' rustdesk "$@"
  '';
in
{
  inherit
    youtube-toggle
    twitch-toggle
    youtube-pip-dock-toggle
    twitch-pip-dock-toggle
    youtube-pip-toggle
    bluelight-toggle
    bluelight-off
    bluelight-auto
    perf-mode
    perf-mode-auto
    perf-mode-daemon
    quick-notes
    hypr-keys
    sysinfo-panel
    wifi-manage
    youtube-opacity-daemon
    twitch-opacity-daemon
    battery-mode
    touchpad-toggle
    hypr-current-workspace-launch
    zapzap-current-workspace
    steam-current-workspace
    vesktop-current-workspace
    spotify-current-workspace
    telegram-current-workspace
    keepassxc-current-workspace
    joplin-current-workspace
    bruno-current-workspace
    rustdesk-current-workspace
    ;
}
