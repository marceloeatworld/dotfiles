# Hyprland helper scripts.
{ pkgs, hyprlandPkg }:

let
  balancedHyprConfig = "hl.config({ animations = { enabled = true }, misc = { render_unfocused_fps = 10 }, decoration = { blur = { enabled = true, special = false, popups = false }, shadow = { enabled = true, range = 12 }, glow = { enabled = false, range = 6 } } })";
  maxHyprConfig = "hl.config({ animations = { enabled = true }, misc = { render_unfocused_fps = 60 }, decoration = { blur = { enabled = true, special = true, popups = true }, shadow = { enabled = true, range = 20 }, glow = { enabled = true, range = 8 } } })";
  batteryHyprConfig = "hl.config({ animations = { enabled = false }, misc = { render_unfocused_fps = 10 }, decoration = { blur = { enabled = false, special = false, popups = false }, shadow = { enabled = false, range = 12 }, glow = { enabled = false, range = 6 } } })";

  # ── Picture-in-Picture (PiP) generators ──
  # YouTube and Twitch PiP scripts share identical control flow; only the window
  # class, launch URL, special-workspace name, detached geometry and detached
  # opacity differ. These three generators keep the logic in one place. The
  # geometry expressions (e.g. "$((mon_lw / 2 - 5))") are passed as parameters
  # because YouTube uses a dynamic half-screen tile while Twitch uses a fixed
  # 960x540 bottom-left tile.

  # show/hide toggle bound to a hotkey; resets to detached so the opacity daemon takes over.
  mkPipToggle =
    { name, class, url, special, stateFile, opacityDaemon
    , detachW, detachH, detachX, detachY, detachOpacityInactive
    }:
    pkgs.writeShellScriptBin name ''
      CLASS="${class}"
      JQ="${pkgs.jq}/bin/jq"
      STATE_FILE="${stateFile}"

      # Force detached mode: floating PiP tile.
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
        : "$mon_lw" "$usable_h" # Some generated PiP geometries use only fixed dimensions.
        w=${detachW}
        h=${detachH}
        x=${detachX}
        y=${detachY}
        # Hyprland 0.55 Lua mode: "hyprctl dispatch/--batch" args are parsed as
        # Lua and fail; drive dispatchers via hyprctl eval + hl.dsp instead.
        # The Lua set_prop API has no lock flag; nothing else sets these props.
        hyprctl eval "(function()
          local win = 'address:$addr'
          hl.dispatch(hl.dsp.window.float({ action = 'on', window = win }))
          hl.dispatch(hl.dsp.window.resize({ x = $w, y = $h, window = win }))
          hl.dispatch(hl.dsp.window.move({ x = $x, y = $y, window = win }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'rounding', value = '12' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'border_size', value = '0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'no_shadow', value = '0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity', value = '1.0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_inactive', value = '${detachOpacityInactive}' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_override', value = '1' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_inactive_override', value = '1' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'no_focus', value = '0' }))
        end)()" 2>/dev/null
        echo "detached" > "$STATE_FILE"
      }

      WIN=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$CLASS\") | .address" | head -1)

      if [ -z "$WIN" ]; then
        # Not running → launch and pre-clear any stale state (opacity daemon defaults to detached)
        rm -f "$STATE_FILE"
        brave --app=${url} &
        disown
        # Opacity daemon starts with the PiP and exits when it closes
        ${pkgs.lib.getExe opacityDaemon} &
        disown
        exit 0
      fi

      # Check if on special workspace (hidden)
      WS=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .workspace.name")
      if echo "$WS" | ${pkgs.gnugrep}/bin/grep -q "special"; then
        # Hidden → bring back, pin, focus, force detached PiP mode
        WSID=$(hyprctl activeworkspace -j | $JQ -r '.id')
        hyprctl eval "(function()
          local win = 'address:$WIN'
          hl.dispatch(hl.dsp.window.move({ workspace = $WSID, follow = false, window = win }))
          hl.dispatch(hl.dsp.window.pin({ window = win }))
          hl.dispatch(hl.dsp.focus({ window = win }))
        end)()"
        reset_to_detached "$WIN"
      else
        # Visible → unpin, hide to special workspace, clear state
        hyprctl eval "(function()
          local win = 'address:$WIN'
          hl.dispatch(hl.dsp.window.pin({ window = win }))
          hl.dispatch(hl.dsp.window.move({ workspace = 'special:${special}', follow = false, window = win }))
        end)()"
        rm -f "$STATE_FILE"
      fi
    '';

  # immediate attach (mini-player fused with waybar) / detach (floating tile) toggle.
  mkPipDockToggle =
    { name, class, url, stateFile, opacityDaemon
    , attachW, attachH, attachX, attachY
    , detachW, detachH, detachX, detachY, detachOpacityInactive
    }:
    pkgs.writeShellScriptBin name ''
      CLASS="${class}"
      JQ="${pkgs.jq}/bin/jq"
      STATE_FILE="${stateFile}"

      WIN=$(hyprctl clients -j | $JQ -r ".[] | select(.class == \"$CLASS\") | .address" | head -1)

      if [ -z "$WIN" ]; then
        brave --app=${url} &
        disown
        ${pkgs.lib.getExe opacityDaemon} &
        disown
        exit 0
      fi

      # If hidden on special workspace, bring back as PiP first
      WS=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .workspace.name")
      STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "detached")
      if echo "$WS" | ${pkgs.gnugrep}/bin/grep -q "special"; then
        WSID=$(hyprctl activeworkspace -j | $JQ -r '.id')
        hyprctl eval "(function()
          local win = 'address:$WIN'
          hl.dispatch(hl.dsp.window.move({ workspace = $WSID, follow = false, window = win }))
          hl.dispatch(hl.dsp.window.float({ action = 'on', window = win }))
        end)()"
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
        # Attach: floating mini-player 48px below waybar, rounded like the
        # detached tile so the gap reads as intentional
        W=${attachW}
        H=${attachH}
        X=${attachX}
        Y=${attachY}
        hyprctl eval "(function()
          local win = 'address:$WIN'
          hl.dispatch(hl.dsp.window.float({ action = 'on', window = win }))
          hl.dispatch(hl.dsp.window.resize({ x = $W, y = $H, window = win }))
          hl.dispatch(hl.dsp.window.move({ x = $X, y = $Y, window = win }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'rounding', value = '12' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'border_size', value = '0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'no_shadow', value = '0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity', value = '1.0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_inactive', value = '1.0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_override', value = '1' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_inactive_override', value = '1' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'no_focus', value = '1' }))
        end)()"
        PINNED=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .pinned")
        [ "$PINNED" != "true" ] && hyprctl eval "hl.dispatch(hl.dsp.window.pin({ window = 'address:$WIN' }))"
        echo "attached" > "$STATE_FILE"
      else
        # Detach: floating PiP tile
        W=${detachW}
        H=${detachH}
        X=${detachX}
        Y=${detachY}
        hyprctl eval "(function()
          local win = 'address:$WIN'
          hl.dispatch(hl.dsp.window.float({ action = 'on', window = win }))
          hl.dispatch(hl.dsp.window.resize({ x = $W, y = $H, window = win }))
          hl.dispatch(hl.dsp.window.move({ x = $X, y = $Y, window = win }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'rounding', value = '12' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'border_size', value = '0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'no_shadow', value = '0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity', value = '1.0' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_inactive', value = '${detachOpacityInactive}' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_override', value = '1' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'opacity_inactive_override', value = '1' }))
          hl.dispatch(hl.dsp.window.set_prop({ window = win, prop = 'no_focus', value = '0' }))
        end)()"
        PINNED=$(hyprctl clients -j | $JQ -r ".[] | select(.address == \"$WIN\") | .pinned")
        [ "$PINNED" != "true" ] && hyprctl eval "hl.dispatch(hl.dsp.window.pin({ window = 'address:$WIN' }))"
        echo "detached" > "$STATE_FILE"
      fi
    '';

  # Smart opacity daemon: transparent when the focused window overlaps the PiP,
  # opaque otherwise. Driven by Hyprland IPC events. Started on demand by the
  # PiP toggle scripts (not at session start) and exits when the PiP window
  # closes, so it never idles in the background.
  mkOpacityDaemon =
    { name, class, stateFile }:
    pkgs.writeShellScriptBin name ''
      exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/${name}.lock"
      ${pkgs.util-linux}/bin/flock -n 9 || exit 0

      PIP_CLASS="${class}"
      JQ="${pkgs.jq}/bin/jq"
      SOCAT="${pkgs.socat}/bin/socat"
      LAST_STATE=""
      ACTIVE_ADDR=""
      PIP_ADDR=""

      # One hyprctl call per event; the active-window address comes from the
      # IPC event payload instead of an extra "hyprctl activewindow" query.
      update_opacity() {
        # Skip when docked to waybar — opacity is locked to 1.0 in attached mode
        local pip_state
        pip_state=$(cat ${stateFile} 2>/dev/null || echo "detached")
        if [ "$pip_state" = "attached" ]; then
          LAST_STATE=""
          return
        fi

        local clients pip_info
        clients=$(hyprctl clients -j)
        pip_info=$(echo "$clients" | $JQ -r "first(.[] | select(.class == \"$PIP_CLASS\")) | \"\(.address) \(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])\"" 2>/dev/null)
        [ -z "$pip_info" ] && return

        local pip_addr yx yy yw yh
        read -r pip_addr yx yy yw yh <<< "$pip_info"
        PIP_ADDR="$pip_addr"

        # PiP itself focused → opaque
        if [ "$pip_addr" = "0x$ACTIVE_ADDR" ]; then
          if [ "$LAST_STATE" != "focused" ]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.set_prop({ window = 'address:$pip_addr', prop = 'opacity_inactive', value = '1.0' }))" 2>/dev/null
            LAST_STATE="focused"
          fi
          return
        fi

        local focused_info
        focused_info=$(echo "$clients" | $JQ -r "first(.[] | select(.address == \"0x$ACTIVE_ADDR\")) | \"\(.at[0]) \(.at[1]) \(.size[0]) \(.size[1])\"" 2>/dev/null)
        [ -z "$focused_info" ] && return

        local fx fy fw fh
        read -r fx fy fw fh <<< "$focused_info"

        # Rectangle overlap test
        local overlap=false
        if (( fx < yx + yw )) && (( fx + fw > yx )) && \
           (( fy < yy + yh )) && (( fy + fh > yy )); then
          overlap=true
        fi

        if [ "$overlap" = "true" ]; then
          # Focused window is under the PiP → very transparent
          if [ "$LAST_STATE" != "transparent" ]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.set_prop({ window = 'address:$pip_addr', prop = 'opacity_inactive', value = '0.4' }))" 2>/dev/null
            LAST_STATE="transparent"
          fi
        else
          # Focused window is elsewhere → fully opaque to keep watching
          if [ "$LAST_STATE" != "opaque" ]; then
            hyprctl eval "hl.dispatch(hl.dsp.window.set_prop({ window = 'address:$pip_addr', prop = 'opacity_inactive', value = '1.0' }))" 2>/dev/null
            LAST_STATE="opaque"
          fi
        fi
      }

      # Listen to Hyprland IPC events
      SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

      $SOCAT -U - "UNIX-CONNECT:$SOCKET" | while read -r line; do
        case "$line" in
          activewindowv2\>\>*)
            ACTIVE_ADDR="''${line#activewindowv2>>}"
            update_opacity
            ;;
          movewindow\>*|openwindow\>*)
            update_opacity
            ;;
          closewindow\>\>*)
            # Zero-cost skip unless the closed window is (or may be) the PiP;
            # PiP gone -> exit, the next toggle launch restarts us
            if [ -z "$PIP_ADDR" ] || [ "0x''${line#closewindow>>}" = "$PIP_ADDR" ]; then
              hyprctl clients -j | $JQ -e ".[] | select(.class == \"$PIP_CLASS\")" > /dev/null || exit 0
              PIP_ADDR=""
            fi
            ;;
        esac
      done
    '';

  # YouTube PiP toggle - launch / show+pin / unpin+hide
  youtube-toggle = mkPipToggle {
    name = "youtube-toggle";
    class = "brave-youtube.com__-Default";
    url = "https://youtube.com/";
    special = "youtube";
    stateFile = "/tmp/youtube-pip-state";
    opacityDaemon = youtube-opacity-daemon;
    # Dynamic half-screen tile, right side.
    detachW = "$((mon_lw / 2 - 5))";
    detachH = "$((usable_h / 2 - 5))";
    detachX = "$((mon_x + mon_lw / 2 + 2))";
    detachY = "$((mon_y + mon_top + usable_h / 2 + 2))";
    detachOpacityInactive = "1.0";
  };

  # Twitch PiP toggle - mirrors youtube-toggle; fixed 960x540 bottom-left tile to
  # avoid overlap with the YouTube PiP, and a dimmer detached opacity.
  twitch-toggle = mkPipToggle {
    name = "twitch-toggle";
    class = "brave-twitch.tv__-Default";
    url = "https://twitch.tv/";
    special = "twitch";
    stateFile = "/tmp/twitch-pip-state";
    opacityDaemon = twitch-opacity-daemon;
    detachW = "960";
    detachH = "540";
    detachX = "$((mon_x + 10))";
    detachY = "$((mon_y + mon_lh - 550))";
    detachOpacityInactive = "0.85";
  };

  # YouTube PiP dock toggle - immediate attach/detach for explicit controls.
  # Attached: 480x270 mini-player centered 48px below waybar (bar is 32px).
  # Detached: dynamic half-screen tile in the bottom-right corner.
  youtube-pip-dock-toggle = mkPipDockToggle {
    name = "youtube-pip-dock-toggle";
    class = "brave-youtube.com__-Default";
    url = "https://youtube.com/";
    stateFile = "/tmp/youtube-pip-state";
    opacityDaemon = youtube-opacity-daemon;
    attachW = "480";
    attachH = "270";
    attachX = "$((MON_X + (MON_LW - 480) / 2))";
    attachY = "$((MON_Y + 80))";
    detachW = "$((MON_LW / 2 - 5))";
    detachH = "$((USABLE_H / 2 - 5))";
    detachX = "$((MON_X + MON_LW / 2 + 2))";
    detachY = "$((MON_Y + MON_TOP + USABLE_H / 2 + 2))";
    detachOpacityInactive = "1.0";
  };

  # Twitch PiP dock toggle - mirrors youtube-pip-dock-toggle; attaches left of
  # centre and detaches to a fixed 960x540 bottom-left tile with dimmer opacity.
  twitch-pip-dock-toggle = mkPipDockToggle {
    name = "twitch-pip-dock-toggle";
    class = "brave-twitch.tv__-Default";
    url = "https://twitch.tv/";
    stateFile = "/tmp/twitch-pip-state";
    opacityDaemon = twitch-opacity-daemon;
    attachW = "480";
    attachH = "270";
    attachX = "$((MON_X + 10))";
    attachY = "$((MON_Y + 80))";
    detachW = "960";
    detachH = "540";
    detachX = "$((MON_X + 10))";
    detachY = "$((MON_Y + MON_LH - 550))";
    detachOpacityInactive = "0.85";
  };

  # PiP dock toggle from MPRIS - double-click guard for accidental clicks.
  # Docks whichever PiP is on screen: visible YouTube first, then visible
  # Twitch, then whichever exists hidden, else launches YouTube.
  pip-dock-toggle = pkgs.writeShellScriptBin "pip-dock-toggle" ''
    CLICK_FILE="/tmp/pip-dblclick"
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

    JQ="${pkgs.jq}/bin/jq"
    CLIENTS=$(hyprctl clients -j)
    YT_WS=$(echo "$CLIENTS" | $JQ -r 'first(.[] | select(.class == "brave-youtube.com__-Default")) | .workspace.name')
    TW_WS=$(echo "$CLIENTS" | $JQ -r 'first(.[] | select(.class == "brave-twitch.tv__-Default")) | .workspace.name')

    PICK=""
    case "$YT_WS" in ""|special*) ;; *) PICK="youtube" ;; esac
    if [ -z "$PICK" ]; then
      case "$TW_WS" in ""|special*) ;; *) PICK="twitch" ;; esac
    fi
    [ -z "$PICK" ] && [ -n "$YT_WS" ] && PICK="youtube"
    [ -z "$PICK" ] && [ -n "$TW_WS" ] && PICK="twitch"
    [ -z "$PICK" ] && PICK="youtube"

    if [ "$PICK" = "twitch" ]; then
      exec ${twitch-pip-dock-toggle}/bin/twitch-pip-dock-toggle
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

    if [ "$NEXT" = "off" ]; then
      ${pkgs.procps}/bin/pkill -TERM hyprsunset 2>/dev/null && sleep 0.2 || true
      ${pkgs.procps}/bin/pkill -KILL hyprsunset 2>/dev/null || true
    else
      # Adjust the running daemon via hyprsunset IPC - kill/restart flashed the
      # screen back to 6500K between levels. Fall back to a fresh daemon when
      # none is running or the socket call fails.
      if ! ${pkgs.procps}/bin/pgrep -x hyprsunset > /dev/null \
        || ! ${hyprlandPkg}/bin/hyprctl hyprsunset temperature $TEMP > /dev/null 2>&1; then
        ${pkgs.procps}/bin/pkill -TERM hyprsunset 2>/dev/null && sleep 0.2 || true
        ${pkgs.procps}/bin/pkill -KILL hyprsunset 2>/dev/null || true
        ${pkgs.hyprsunset}/bin/hyprsunset -t $TEMP &
        disown
      fi
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
        # Switch to BALANCED (some animations, moderate FPS, auto profile)
        ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg balancedHyprConfig}
        /run/wrappers/bin/sudo -n /run/current-system/sw/bin/game-platform-profile auto 2>/dev/null || true
        echo "balanced" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "⚖️ Balanced Mode" "Animations ON, platform profile auto" -i "battery-good"
        ;;
      balanced)
        # Switch to MAX PERFORMANCE (all effects, high FPS, performance profile)
        ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg maxHyprConfig}
        /run/wrappers/bin/sudo -n /run/current-system/sw/bin/game-platform-profile performance 2>/dev/null || true
        echo "max" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "🚀 Max Performance" "All effects + performance profile" -i "video-display"
        ;;
      max|*)
        # Switch to BATTERY SAVER (no effects, minimal FPS, low-power profile)
        ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg batteryHyprConfig}
        /run/wrappers/bin/sudo -n /run/current-system/sw/bin/game-platform-profile low-power 2>/dev/null || true
        echo "battery" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "🔋 Battery Saver" "Effects OFF + low-power profile" -i "battery-caution"
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
        # On battery - enable battery saver mode.
        # Right after session start Hyprland can silently drop the eval
        # during init; verify via getoption and retry, bounded.
        for _ in 1 2 3 4 5; do
          ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg batteryHyprConfig}
          ${hyprlandPkg}/bin/hyprctl getoption animations:enabled | ${pkgs.gnugrep}/bin/grep -q 'bool: false' && break
          sleep 1
        done
        echo "battery" > "$STATE_FILE"
      else
        # On AC - restore saved state or default to balanced
        SAVED_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "balanced")
        case "$SAVED_STATE" in
          battery)
            for _ in 1 2 3 4 5; do
              ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg batteryHyprConfig}
              ${hyprlandPkg}/bin/hyprctl getoption animations:enabled | ${pkgs.gnugrep}/bin/grep -q 'bool: false' && break
              sleep 1
            done
            ;;
          max)
            ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg maxHyprConfig}
            /run/wrappers/bin/sudo -n /run/current-system/sw/bin/game-platform-profile performance 2>/dev/null || true
            ;;
          *)
            ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg balancedHyprConfig}
            ;;
        esac
      fi
    fi
  '';

  # Battery-aware performance daemon (monitors power state changes via upower events)
  perf-mode-daemon = pkgs.writeShellScriptBin "perf-mode-daemon" ''
    # Monitors power state via upower events (instant reaction, zero idle CPU)

    STATE_FILE="$HOME/.config/perf-mode-state"
    PREV_FILE="$HOME/.config/perf-mode-prev-state"
    LAST_STATUS=""

    apply_mode() {
      local status="$1"
      if [ "$status" = "Discharging" ] && [ "$LAST_STATUS" != "Discharging" ]; then
        # Remember the mode we were in so AC restores it (don't clobber a manual "max")
        CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "balanced")
        [ "$CURRENT" != "battery" ] && echo "$CURRENT" > "$PREV_FILE"
        # The initial apply at session start races Hyprland's init and can
        # be silently dropped; verify via getoption and retry, bounded.
        for _ in 1 2 3 4 5; do
          ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg batteryHyprConfig}
          ${hyprlandPkg}/bin/hyprctl getoption animations:enabled | ${pkgs.gnugrep}/bin/grep -q 'bool: false' && break
          sleep 1
        done
        echo "battery" > "$STATE_FILE"
        ${pkgs.libnotify}/bin/notify-send -t 2000 "Battery Mode" "󰂃 Battery saver auto-enabled" -i "battery-good"
        LAST_STATUS="$status"
      elif [ "$status" != "Discharging" ] && [ "$LAST_STATUS" = "Discharging" ]; then
        RESTORE=$(cat "$PREV_FILE" 2>/dev/null || echo "balanced")
        if [ "$RESTORE" = "max" ]; then
          ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg maxHyprConfig}
          /run/wrappers/bin/sudo -n /run/current-system/sw/bin/game-platform-profile performance 2>/dev/null || true
          echo "max" > "$STATE_FILE"
          ${pkgs.libnotify}/bin/notify-send -t 2000 "AC Power" "󰂄 Max performance restored" -i "battery-full-charging"
        else
          ${hyprlandPkg}/bin/hyprctl eval ${pkgs.lib.escapeShellArg balancedHyprConfig}
          echo "balanced" > "$STATE_FILE"
          ${pkgs.libnotify}/bin/notify-send -t 2000 "AC Power" "󰂄 Balanced mode restored" -i "battery-full-charging"
        fi
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
          # pending-charge = AC with charge thresholds holding the battery
          # (BAT0 "Not charging"); with conservation mode this is the only
          # state a plug-in above the stop threshold ever produces.
          charging|fully-charged|pending-charge) apply_mode "Charging" ;;
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
    <tt>Copilot key</tt>     Voice dictation (toggle)
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
    <tt>Super+Shift+P</tt>   Toggle laptop screen (eDP-1)
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

        # GPU info (AMD) — resolve the amdgpu card dynamically; the DRM card index
        # is not stable across boots, and only the GPU exposes gpu_busy_percent.
        GPU_BUSY=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1)
        if [ -n "$GPU_BUSY" ]; then
          GPU_USAGE="$GPU_BUSY%"
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
          ${pkgs.libnotify}/bin/notify-send -t 3000 "WiFi" "󰤭  Not connected. Try SUPER+SHIFT+F2 to pick a network" -i "network-wireless-offline"
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

  # Smart PiP opacity daemons (transparent when overlapped, opaque elsewhere).
  youtube-opacity-daemon = mkOpacityDaemon {
    name = "youtube-opacity-daemon";
    class = "brave-youtube.com__-Default";
    stateFile = "/tmp/youtube-pip-state";
  };

  twitch-opacity-daemon = mkOpacityDaemon {
    name = "twitch-opacity-daemon";
    class = "brave-twitch.tv__-Default";
    stateFile = "/tmp/twitch-pip-state";
  };

  battery-mode = pkgs.writeShellScriptBin "battery-mode" ''
    # Battery charge mode toggle for ThinkPad (requires sudo privileges)
    # Conservation (55-60%, default on AC) <-> Full (95-100%, before travel).
    # TLP reapplies 55/60 at every boot, so Full is a one-trip override.

    STATE_FILE="$HOME/.config/battery-mode-state"

    # Derive current mode from the real threshold: TLP reapplies its
    # configured 55/60 at every boot, so the state file goes stale across
    # reboots. Resync it here; hypr-keys reads it for display.
    THRESHOLD_FILE="/sys/class/power_supply/BAT0/charge_control_end_threshold"
    if [ -r "$THRESHOLD_FILE" ]; then
      case "$(cat "$THRESHOLD_FILE")" in
        60) CURRENT_MODE="conservation" ;;
        *)  CURRENT_MODE="full" ;;
      esac
      echo "$CURRENT_MODE" > "$STATE_FILE"
    elif [ -f "$STATE_FILE" ]; then
      CURRENT_MODE=$(cat "$STATE_FILE")
    else
      CURRENT_MODE="conservation"
    fi

    # Determine next mode
    case "$CURRENT_MODE" in
      conservation)
        NEXT_MODE="full"
        START=95
        STOP=100
        ICON="battery-full-charging"
        TITLE="Full Mode"
        DESC="Charge: 95-100% (before travel)"
        ;;
      *)
        NEXT_MODE="conservation"
        START=55
        STOP=60
        ICON="battery-low-charging"
        TITLE="Conservation Mode"
        DESC="Charge: 55-60% (always on AC)"
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

    DEVICE=$(${hyprlandPkg}/bin/hyprctl devices -j | ${pkgs.jq}/bin/jq -r '
      .mice
      | map(select((.name // "" | ascii_downcase | test("touchpad"))))
      | .[0].name // empty
    ')

    if [ -z "$DEVICE" ]; then
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "No touchpad detected" -i "dialog-error"
      exit 1
    fi

    STATE_FILE="''${XDG_RUNTIME_DIR:-/tmp}/touchpad-state"
    CURRENT=$(cat "$STATE_FILE" 2>/dev/null || echo "enabled")

    # Hyprland 0.55 Lua parser rejects `hyprctl keyword` ("Use eval"); the
    # runtime equivalent for per-device config is hl.device() via `eval`.
    if [ "$CURRENT" = "enabled" ]; then
      ${hyprlandPkg}/bin/hyprctl eval "hl.device({ name = \"$DEVICE\", enabled = false })"
      echo "disabled" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Disabled" -i "input-touchpad"
    else
      ${hyprlandPkg}/bin/hyprctl eval "hl.device({ name = \"$DEVICE\", enabled = true })"
      echo "enabled" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Touchpad" "Enabled" -i "input-touchpad"
    fi
  '';

  # Toggle the laptop's internal screen (eDP-1) on/off. Disabling it pushes
  # everything onto the external; refuses to disable the only active monitor.
  monitor-toggle = pkgs.writeShellScriptBin "monitor-toggle" ''
    set -euo pipefail

    MON="eDP-1"
    JQ="${pkgs.jq}/bin/jq"

    # Names of currently active (enabled) monitors.
    ACTIVE=$(${hyprlandPkg}/bin/hyprctl monitors -j | "$JQ" -r '.[].name')
    COUNT=$(printf '%s\n' "$ACTIVE" | ${pkgs.gnugrep}/bin/grep -c .)

    if printf '%s\n' "$ACTIVE" | ${pkgs.gnugrep}/bin/grep -qx "$MON"; then
      # eDP-1 is on. Keep it on if it is the only screen left.
      if [ "$COUNT" -le 1 ]; then
        ${pkgs.libnotify}/bin/notify-send -t 2000 "Laptop screen" "Only active screen, kept on" -i "video-display"
        exit 0
      fi
      ${hyprlandPkg}/bin/hyprctl eval "hl.monitor({ output = \"$MON\", disabled = true })"
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Laptop screen" "Off (everything on the external)" -i "video-display"
    else
      # eDP-1 is off, restore its normal config (matches monitors.lua).
      ${hyprlandPkg}/bin/hyprctl eval "hl.monitor({ output = \"$MON\", mode = \"1920x1200@60\", position = \"0x1080\", scale = 1 })"
      ${pkgs.libnotify}/bin/notify-send -t 2000 "Laptop screen" "On" -i "video-display"
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
      *) hyprctl eval "hl.dispatch(hl.dsp.window.move({ workspace = $ACTIVE_WS, follow = false, window = 'address:$WIN' }))" >/dev/null 2>&1 || true ;;
    esac

    hyprctl eval "hl.dispatch(hl.dsp.focus({ window = 'address:$WIN' }))" >/dev/null 2>&1 || true
  '';

  ferdium-current-workspace = pkgs.writeShellScriptBin "ferdium-current-workspace" ''
    exec ${hypr-current-workspace-launch}/bin/hypr-current-workspace-launch '^(ferdium|Ferdium)$' ferdium "$@"
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

  # Voice dictation into the focused window - one toggle key.
  # First press starts recording, second press stops and transcribes locally
  # with whisper.cpp (multilingual, auto language), then routes the result:
  #   "send"        -> press Enter
  #   "delete"      -> clear the input line (Ctrl+U)
  #   anything else -> typed into the focused window
  voice-terminal = pkgs.writeShellScriptBin "voice-terminal" ''
    WTYPE="${pkgs.wtype}/bin/wtype"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    WHISPER="${pkgs.whisper-cpp.override { vulkanSupport = true; }}/bin/whisper-cli"
    PW_RECORD="${pkgs.pipewire}/bin/pw-record"
    CURL="${pkgs.curl}/bin/curl"

    RUN_DIR="''${XDG_RUNTIME_DIR:-/tmp}/voice-terminal"
    mkdir -p "$RUN_DIR"
    PIDFILE="$RUN_DIR/record.pid"
    WAV="$RUN_DIR/record.wav"
    STATEFILE="$RUN_DIR/state"

    # Waybar indicator (custom/voice, signal 6)
    set_state() {
      echo "$1" > "$STATEFILE"
      ${pkgs.procps}/bin/pkill -RTMIN+6 waybar 2>/dev/null || true
    }
    clear_state() {
      rm -f "$STATEFILE"
      ${pkgs.procps}/bin/pkill -RTMIN+6 waybar 2>/dev/null || true
    }

    MODEL_DIR="$HOME/.local/share/voice-terminal"
    # large-v3-turbo: same multilingual auto-detection as full v3, smaller and
    # faster to load (the per-dictation cost). q5_0 measured identical to q8_0
    # on French dictation. Earlier French misdetections were traced to a dead
    # headset mic feeding noise, not to the model.
    MODEL="$MODEL_DIR/ggml-large-v3-turbo-q5_0.bin"
    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3-turbo-q5_0.bin"

    if [ -f "$PIDFILE" ]; then
      # ── Stop recording and transcribe ──
      PID=$(cat "$PIDFILE")
      rm -f "$PIDFILE"
      if kill -INT "$PID" 2>/dev/null; then
        for _ in 1 2 3 4 5 6 7 8 9 10; do
          kill -0 "$PID" 2>/dev/null || break
          sleep 0.1
        done
        kill -KILL "$PID" 2>/dev/null || true
      fi

      # < 0.5s of 16kHz s16 mono audio = nothing was said
      if [ ! -s "$WAV" ] || [ "$(stat -c %s "$WAV")" -lt 16000 ]; then
        rm -f "$WAV"
        clear_state
        $NOTIFY -t 2000 "Voice Terminal" "Nothing recorded" -i "audio-input-microphone"
        exit 0
      fi

      set_state "transcribing"
      $NOTIFY -t 1500 "Voice Terminal" "Transcribing..." -i "audio-input-microphone"
      # Language forced via voice-lang (fr/en/...), defaults to auto-detection
      VLANG=$(cat "$MODEL_DIR/lang" 2>/dev/null || echo auto)
      TEXT=$($WHISPER -m "$MODEL" -f "$WAV" -l "$VLANG" -t 8 -np -nt 2>/dev/null \
        | tr '\n' ' ' | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
      rm -f "$WAV"
      clear_state
      if [ -z "$TEXT" ]; then
        $NOTIFY -t 2000 "Voice Terminal" "Heard nothing" -i "audio-input-microphone"
        exit 0
      fi

      # Command matching is case/punctuation-insensitive
      LOWER=$(printf '%s' "$TEXT" | tr '[:upper:]' '[:lower:]' | tr -d '.,!?')
      set -- $LOWER
      CMD="''${1:-}"

      case "$CMD" in
        send)
          $WTYPE -k Return
          ;;
        delete)
          $WTYPE -M ctrl -k u -m ctrl
          ;;
        *)
          printf '%s' "$TEXT" | $WTYPE -
          ;;
      esac
    else
      # ── Start recording ──
      if [ ! -f "$MODEL" ]; then
        mkdir -p "$MODEL_DIR"
        # flock: repeated key presses must not start concurrent downloads
        exec 9> "$MODEL_DIR/.download.lock"
        if ! ${pkgs.util-linux}/bin/flock -n 9; then
          $NOTIFY -t 3000 "Voice Terminal" "Model download already in progress..." -i "audio-input-microphone"
          exit 0
        fi
        set_state "downloading"
        $NOTIFY -t 5000 "Voice Terminal" "Downloading Whisper model (574 MB, one time)..." -i "audio-input-microphone"
        if $CURL -fsSL -o "$MODEL.part" "$MODEL_URL"; then
          mv "$MODEL.part" "$MODEL"
          clear_state
          $NOTIFY -t 4000 "Voice Terminal" "Model ready - press the Copilot key to dictate" -i "audio-input-microphone"
        else
          rm -f "$MODEL.part"
          clear_state
          $NOTIFY -u critical "Voice Terminal" "Model download failed" -i "audio-input-microphone"
        fi
        exit 0
      fi
      rm -f "$WAV"
      $PW_RECORD --rate 16000 --channels 1 --format s16 "$WAV" &
      echo $! > "$PIDFILE"
      set_state "recording"
      $NOTIFY -t 2000 "Voice Terminal" "Recording... press the Copilot key to stop" -i "audio-input-microphone"
    fi
  '';

  # Switch the voice-terminal transcription language: voice-lang fr|en|auto|<code>
  # No argument prints the current setting. "auto" (default) detects per clip.
  voice-lang = pkgs.writeShellScriptBin "voice-lang" ''
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    LANG_FILE="$HOME/.local/share/voice-terminal/lang"

    if [ -z "''${1:-}" ]; then
      echo "voice-lang: $(cat "$LANG_FILE" 2>/dev/null || echo auto)"
      exit 0
    fi

    case "$1" in
      auto|[a-z][a-z]) ;;
      *) echo "usage: voice-lang [auto|fr|en|<iso code>]"; exit 1 ;;
    esac

    mkdir -p "$(dirname "$LANG_FILE")"
    echo "$1" > "$LANG_FILE"
    $NOTIFY -t 2000 "Voice Terminal" "Language: $1" -i "audio-input-microphone"
    echo "voice-lang: $1"
  '';
in
{
  inherit
    youtube-toggle
    twitch-toggle
    youtube-pip-dock-toggle
    twitch-pip-dock-toggle
    pip-dock-toggle
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
    monitor-toggle
    hypr-current-workspace-launch
    ferdium-current-workspace
    vesktop-current-workspace
    spotify-current-workspace
    telegram-current-workspace
    keepassxc-current-workspace
    joplin-current-workspace
    bruno-current-workspace
    rustdesk-current-workspace
    voice-terminal
    voice-lang
    ;
}
