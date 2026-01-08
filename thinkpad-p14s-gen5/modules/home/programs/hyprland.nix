# Hyprland - Using nixpkgs-unstable for latest version
{ config, pkgs, pkgs-unstable, ... }:

let
  theme = config.theme;

  # Hyprland plugins from unstable
  hyprlandPlugins = pkgs-unstable.hyprlandPlugins;
  # Helper to strip # from hex colors for Hyprland rgb() format
  stripHash = color: builtins.substring 1 6 color;
in

let
  # Blue light filter toggle - cycles through temperature levels
  bluelight-toggle = pkgs.writeShellScriptBin "bluelight-toggle" ''
    #!/usr/bin/env bash
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
    pkill -TERM hyprsunset 2>/dev/null && sleep 0.2 || true
    pkill -KILL hyprsunset 2>/dev/null || true

    # Start with new temperature (if not off)
    if [ "$NEXT" != "off" ]; then
      ${pkgs-unstable.hyprsunset}/bin/hyprsunset -t $TEMP &
      disown
    fi

    echo "$NEXT" > "$STATE_FILE"
    notify-send -t 2000 "Blue Light Filter" "$DESC" -i "weather-clear-night"
  '';

  # Quick off - instantly disable blue light filter
  bluelight-off = pkgs.writeShellScriptBin "bluelight-off" ''
    #!/usr/bin/env bash
    pkill hyprsunset 2>/dev/null || true
    echo "off" > "$HOME/.config/bluelight-state"
    notify-send -t 1500 "Blue Light Filter" "󰖙  Disabled" -i "weather-clear"
  '';

  # Auto-enable blue light filter at boot based on time of day
  # Night hours: 20:00-07:00 → auto-enable at 2000K
  bluelight-auto = pkgs.writeShellScriptBin "bluelight-auto" ''
    #!/usr/bin/env bash
    STATE_FILE="$HOME/.config/bluelight-state"
    HOUR=$(date +%H)

    # Night hours: 20:00 (8pm) to 07:00 (7am)
    if [ "$HOUR" -ge 20 ] || [ "$HOUR" -lt 7 ]; then
      # Check if already running
      if pgrep -x hyprsunset > /dev/null; then
        exit 0
      fi

      # Set to 2000K for night mode
      TEMP=2000
      echo "2000" > "$STATE_FILE"
      ${pkgs-unstable.hyprsunset}/bin/hyprsunset -t $TEMP &
      disown
    fi
  '';

  # Toggle performance mode (blur/shadows/animations)
  perf-mode = pkgs.writeShellScriptBin "perf-mode" ''
    #!/usr/bin/env bash
    set -euo pipefail

    STATE_FILE="$HOME/.config/perf-mode-state"

    # Read current state
    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(cat "$STATE_FILE")
    else
      CURRENT="quality"
    fi

    if [ "$CURRENT" = "quality" ]; then
      # Switch to performance mode (disable effects)
      hyprctl keyword decoration:blur:enabled false
      hyprctl keyword decoration:shadow:enabled false
      hyprctl keyword animations:enabled false
      echo "performance" > "$STATE_FILE"
      notify-send -t 2000 "Performance Mode" "Effects disabled for battery/GPU savings" -i "battery-good"
    else
      # Switch to quality mode (enable effects)
      hyprctl keyword decoration:blur:enabled true
      hyprctl keyword decoration:shadow:enabled true
      hyprctl keyword animations:enabled true
      echo "quality" > "$STATE_FILE"
      notify-send -t 2000 "Quality Mode" "Visual effects enabled" -i "video-display"
    fi
  '';

  # Quick notes - Open floating terminal with nvim for quick note-taking
  quick-notes = pkgs.writeShellScriptBin "quick-notes" ''
    #!/usr/bin/env bash
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

  # System info panel - Shows system stats in a notification or floating window
  sysinfo-panel = pkgs.writeShellScriptBin "sysinfo-panel" ''
    #!/usr/bin/env bash
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
    NET_IFACE=$(ip route | ${pkgs.gawk}/bin/awk '/default/{print $5; exit}')
    if [ -n "$NET_IFACE" ]; then
      NET_IP=$(ip -4 addr show "$NET_IFACE" | ${pkgs.gawk}/bin/awk '/inet /{print $2}' | cut -d'/' -f1)
      # Check for VPN
      if ip link show | grep -q "proton"; then
        VPN_STATUS="🔒 ProtonVPN"
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
    OLLAMA_STATUS=$(systemctl is-active ollama 2>/dev/null || echo "inactive")
    DOCKER_STATUS=$(systemctl is-active docker 2>/dev/null || echo "inactive")

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
  Ollama: $OLLAMA_STATUS
  Docker: $DOCKER_STATUS"

    # Show notification with longer timeout
    notify-send -t 10000 "System Info" "$INFO" -i "utilities-system-monitor"
  '';

  battery-mode = pkgs.writeShellScriptBin "battery-mode" ''
    #!/usr/bin/env bash
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
        notify-send -t 3000 "$TITLE" "$DESC" -i "$ICON"
      else
        notify-send -t 3000 "Battery Error" "Failed to change mode" -i "dialog-error"
      fi
    else
      notify-send -t 3000 "Error" "TLP is not installed" -i "dialog-error"
    fi
  '';

in
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = pkgs-unstable.hyprland;  # Latest from unstable
    # Disable home-manager systemd integration - conflicts with UWSM
    systemd.enable = false;

    # Hyprland plugins
    plugins = [
      hyprlandPlugins.hyprexpo    # Workspace overview (SUPER+TAB)
      hyprlandPlugins.hyprbars    # Window title bars
    ];

    settings = {
      "debug:disable_logs" = true;

      # === PLUGIN CONFIGURATIONS ===

      # Hyprexpo - Workspace overview (like macOS Mission Control)
      "plugin:hyprexpo" = {
        columns = 3;
        gap_size = 5;
        bg_col = "rgb(${stripHash theme.colors.background})";
        workspace_method = "first 1";  # Start from workspace 1
        enable_gesture = true;  # 3-finger swipe up to trigger
        gesture_fingers = 3;
        gesture_distance = 300;
        gesture_positive = false;  # Swipe up
      };

      # Hyprbars - Window title bars
      "plugin:hyprbars" = {
        bar_height = 24;
        bar_color = "rgb(${stripHash theme.colors.background})";
        "col.text" = "rgb(${stripHash theme.colors.foreground})";
        bar_text_size = 10;
        bar_text_font = "JetBrains Mono";
        bar_part_of_window = true;
        bar_precedence_over_border = true;

        # Window buttons (close, maximize, minimize)
        hyprbars-button = [
          # color, size, icon, action
          "rgb(${stripHash theme.colors.red}), 14, 󰖭, hyprctl dispatch killactive"
          "rgb(${stripHash theme.colors.yellow}), 14, 󰖯, hyprctl dispatch fullscreen 1"
          "rgb(${stripHash theme.colors.green}), 14, 󰖰, hyprctl dispatch movetoworkspacesilent special:minimized"
        ];
      };

      monitor = [
        "HDMI-A-1,1920x1080@60,0x0,1"
        "DP-1,1920x1080@60,0x0,1"
        "eDP-1,1920x1200@60,0x1080,1"
        ",preferred,auto,1"
      ];

      exec-once = [
        "waybar"
        "mako"
        "swayosd-server"  # OSD daemon for volume/brightness notifications
        "hyprpaper"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "hyprlauncher -d"  # Start hyprlauncher daemon
        "hypridle"
        "${bluelight-auto}/bin/bluelight-auto"  # Auto-enable blue light filter at night
        "sleep 2 && nm-applet"  # Delay tray applet to avoid "no icon" errors
        "sleep 3 && opensnitch-ui"  # Application firewall GUI (tray icon)
      ];

      # Cursor and GDK settings (system-level has the rest via environment.sessionVariables)
      # Hyprcursor uses XCursor themes as fallback - Bibata works natively
      env = [
        "XCURSOR_THEME,Bibata-Modern-Classic"
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Bibata-Modern-Classic"
        "HYPRCURSOR_SIZE,24"
        "GDK_BACKEND,wayland,x11,*"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
      ];

      input = {
        kb_layout = "fr";
        kb_variant = "";
        numlock_by_default = true;
        repeat_rate = 40;   # Slightly slower for comfort
        repeat_delay = 600; # Longer delay before repeat
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;  # Natural scrolling enabled
          disable_while_typing = true;
          tap-to-click = true;  # Fixed: use hyphens instead of underscores
          clickfinger_behavior = true;
          scroll_factor = 0.4;  # Slower, more precise scrolling
          middle_button_emulation = true;
        };

        sensitivity = 0;
      };

      # Hyprland 0.51+ uses new gesture syntax
      gestures = {
        gesture = "3, horizontal, workspace";  # 3-finger horizontal swipe for workspace switching
      };

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 1;
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;

        # Border colors from theme
        "col.active_border" = "rgb(${stripHash theme.colors.foreground})";
        "col.inactive_border" = "rgba(${stripHash theme.colors.border}80)";
      };

      decoration = {
        # Neobrutalist: sharp corners - no rounding
        rounding = 0;

        # No blur - saves GPU resources
        blur = {
          enabled = false;
        };

        # No shadows - saves resources, cleaner neobrutalist look
        shadow = {
          enabled = false;
        };

        # No transparency - saves resources
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        fullscreen_opacity = 1.0;
      };

      animations = {
        enabled = true;
        bezier = [
          "fluent_decel, 0.0, 0.2, 0.4, 1.0"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "easeInOutQuart, 0.76, 0, 0.24, 1"
        ];

        animation = [
          "windows, 1, 5, easeOutCubic, popin 80%"
          "windowsOut, 1, 4, fluent_decel, popin 80%"
          "windowsMove, 1, 4, easeOutCubic, slide"
          "fade, 1, 5, easeOutCubic"
          "fadeIn, 1, 5, easeOutCubic"
          "fadeOut, 1, 5, easeOutCubic"
          "border, 1, 4, easeOutCubic"
          "workspaces, 1, 5, easeOutCubic, slide"
          "specialWorkspace, 1, 5, easeInOutQuart, slidevert"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;  # Disable auto split direction
        force_split = 2;  # Always split to the right (horizontal/landscape)
        split_width_multiplier = 1.5;  # Prefer horizontal splits
      };

      master = {
        new_status = "master";
        new_on_top = true;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 2;  # Variable refresh rate (0=off, 1=on, 2=fullscreen only)
        enable_swallow = true;
        swallow_regex = "^(com.mitchellh.ghostty|Alacritty)$";
        force_default_wallpaper = 0;
        vfr = true;  # Variable frame rate - reduces GPU usage when idle
        focus_on_activate = false;  # Prevent windows from stealing focus
        new_window_takes_over_fullscreen = 2;  # 0=behind, 1=over, 2=unfullscreen
      };

      # Render optimizations
      render = {
        direct_scanout = true;  # Better fullscreen performance
      };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, Tab, hyprexpo:expo, toggle"  # Workspace overview (like macOS Mission Control)
        "$mod, B, exec, brave"
        "$mod, E, exec, nemo"
        "$mod, A, exec, hyprpwcenter"  # Audio control (Official Hyprland)
        "$mod, D, exec, hyprlauncher"  # Toggle hyprlauncher (instant with daemon)
        "$mod SHIFT, D, exec, hyprlauncher"
        "$mod, Q, killactive"
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"
        "$mod, Space, togglefloating"
        "$mod, P, pin"  # Pin window (stays visible on all workspaces)
        "$mod, T, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        "$mod CTRL, left, resizeactive, -40 0"
        "$mod CTRL, right, resizeactive, 40 0"
        "$mod CTRL, up, resizeactive, 0 -40"
        "$mod CTRL, down, resizeactive, 0 40"
        "$mod CTRL, H, resizeactive, -40 0"
        "$mod CTRL, L, resizeactive, 40 0"
        "$mod CTRL, K, resizeactive, 0 -40"
        "$mod CTRL, J, resizeactive, 0 40"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        # Move window to workspace with arrow keys (easy for AZERTY)
        "$mod ALT, left, movetoworkspace, -1"
        "$mod ALT, right, movetoworkspace, +1"
        "$mod ALT, H, movetoworkspace, -1"
        "$mod ALT, L, movetoworkspace, +1"
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
        "$mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, V, exec, cliphist wipe"
        "$mod, Escape, exec, hyprlock"
        "$mod SHIFT, Escape, exec, systemctl poweroff"
        "$mod CTRL, Escape, exec, systemctl reboot"
        "$mod, C, exec, hyprpicker -a"
        "$mod, N, exec, ${bluelight-toggle}/bin/bluelight-toggle"
        "$mod SHIFT, N, exec, ${bluelight-off}/bin/bluelight-off"
        "$mod, M, exec, ${battery-mode}/bin/battery-mode"
        "$mod SHIFT, M, exec, ${perf-mode}/bin/perf-mode"
        "$mod, O, exec, ${quick-notes}/bin/quick-notes"  # Quick note-taking
        "$mod, I, exec, ${sysinfo-panel}/bin/sysinfo-panel"  # System info panel
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy && notify-send 'Screenshot' 'Copied to clipboard'"
        "$mod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send 'Screenshot' 'Saved to Pictures/Screenshots'"
        "SHIFT, Print, exec, grim - | wl-copy && notify-send 'Screenshot' 'Full screen copied'"
        "$mod SHIFT, Print, exec, grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send 'Screenshot' 'Full screen saved'"
        "$mod SHIFT, R, exec, killall waybar && waybar"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Audio/Brightness controls using SwayOSD (native OSD)
      bindl = [
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        # Media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      # Window rules - Hyprland 0.52 inline syntax
      windowrule = [
        # === GENERIC RULES ===
        "suppressevent maximize, class:.*"

        # === FLOAT WINDOWS ===
        # System tools & dialogs
        "float, class:^(hyprpwcenter)$"
        "float, class:^(hyprsysteminfo)$"
        "float, class:^(hyprpolkitagent)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(blueman-manager)$"
        "float, class:^(pavucontrol)$"
        "float, class:^(org.gnome.Calculator)$"
        "float, class:^(file-roller)$"
        "float, class:^(xdg-desktop-portal-gtk)$"
        "float, class:^(org.gnome.FileRoller)$"
        "float, class:^(confirm)$"
        "float, class:^(dialog)$"
        "float, class:^(download)$"
        "float, class:^(notification)$"
        "float, class:^(error)$"
        "float, class:^(splash)$"
        "float, title:^(Open File)$"
        "float, title:^(Save File)$"
        "float, title:^(Open Folder)$"
        "float, title:^(Confirm)$"
        "float, title:^(File Operation Progress)$"

        # === OPACITY RULES ===
        # Terminals - slight transparency
        "opacity 0.95, class:^(com.mitchellh.ghostty)$"
        "opacity 0.95, class:^(Alacritty)$"

        # File managers - slight transparency
        "opacity 0.95, class:^(thunar)$"
        "opacity 0.95, class:^(nemo)$"

        # Browsers - full opacity (important for video)
        "tile, class:^(Brave-browser)$"
        "opacity 1.0 override, class:^(Brave-browser)$"
        "opacity 1.0 override, class:^(firefox)$"
        "opacity 1.0 override, class:^(chromium)$"

        # Media content - full opacity
        "opacity 1.0 override, title:^.*(YouTube|Netflix|Twitch|Zoom|Meet|Discord).*$"

        # IDEs - full opacity
        "opacity 1.0 override, class:^(code-url-handler)$"
        "opacity 1.0 override, class:^(Code)$"
        "opacity 1.0 override, class:^(jetbrains-.*)$"

        # === SPECIAL WINDOWS ===
        # Picture-in-Picture
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "size 640 360, title:^(Picture-in-Picture)$"
        "move 100%-650 100%-370, title:^(Picture-in-Picture)$"
        "opacity 1.0 override, title:^(Picture-in-Picture)$"

        # YouTube webapp - floating on the right
        "float, class:^(brave-youtube\\.com__-Default)$"
        "size 960 720, class:^(brave-youtube\\.com__-Default)$"
        "move 100%-970 10, class:^(brave-youtube\\.com__-Default)$"

        # Hyprlauncher
        "float, class:^(hyprlauncher)$"
        "center, class:^(hyprlauncher)$"
        "stayfocused, class:^(hyprlauncher)$"

        # Quick notes - floating centered window
        "float, class:^(quick-notes)$"
        "size 800 600, class:^(quick-notes)$"
        "center, class:^(quick-notes)$"

        # Prevent idle when watching video
        "idleinhibit fullscreen, class:.*"
        "idleinhibit focus, class:^(mpv|vlc)$"
      ];

    };

  };

  # Hyprland-specific packages (core Wayland tools are in system/hyprland.nix)
  home.packages = with pkgs; [
    hyprpaper                 # Wallpaper daemon
    hypridle                  # Idle daemon
    hyprlock                  # Screen locker
    pkgs-unstable.hyprcursor  # Native Hyprland cursor library
    cliphist                  # Clipboard history manager
    brightnessctl             # Brightness control (for hypridle dim)
    pamixer                   # Volume control CLI (for scripts)
    pkgs-unstable.hyprsunset  # Blue light filter (v0.3.3+ with SIGTERM/SIGINT fixes)
    bluelight-toggle          # Custom toggle script (SUPER+N)
    bluelight-off             # Quick disable (SUPER+SHIFT+N)
    bluelight-auto            # Auto-enable at night (runs on boot)
    battery-mode              # Battery charge mode script
    perf-mode                 # Performance mode toggle
    quick-notes               # Quick note-taking (SUPER+O)
    sysinfo-panel             # System info panel (SUPER+I)
    wofi                      # dmenu-like picker for clipboard history
  ];
}