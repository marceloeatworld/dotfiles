# Hyprland - FIXED gestures
{ pkgs, pkgs-unstable, ... }:

let
  bluelight-toggle = pkgs.writeShellScriptBin "bluelight-toggle" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # State file to track current temperature
    STATE_FILE="$HOME/.config/bluelight-state"

    # Read current state (default to off if file doesn't exist)
    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(cat "$STATE_FILE")
    else
      CURRENT="off"
    fi

    # Determine next state and temperature (8 levels total)
    case "$CURRENT" in
      off|6500)
        NEXT="5500"
        TEMP=5500
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 1 (5500K)"
        ;;
      5500)
        NEXT="4500"
        TEMP=4500
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 2 (4500K)"
        ;;
      4500)
        NEXT="3500"
        TEMP=3500
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 3 (3500K)"
        ;;
      3500)
        NEXT="2500"
        TEMP=2500
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 4 (2500K)"
        ;;
      2500)
        NEXT="2000"
        TEMP=2000
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 5 (2000K - Warm)"
        ;;
      2000)
        NEXT="1500"
        TEMP=1500
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 6 (1500K - Very Warm)"
        ;;
      1500)
        NEXT="1200"
        TEMP=1200
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 7 (1200K - Ultra Warm)"
        ;;
      1200)
        NEXT="off"
        TEMP=0
        ICON="weather-clear"
        TITLE="Blue Light Filter"
        DESC="Off"
        ;;
      *)
        NEXT="5500"
        TEMP=5500
        ICON="weather-clear-night"
        TITLE="Blue Light Filter"
        DESC="Level 1 (5500K)"
        ;;
    esac

    # Kill existing hyprsunset process and wait for it to terminate
    if pgrep -x hyprsunset > /dev/null; then
      pkill -TERM hyprsunset
      # Wait up to 2 seconds for process to terminate
      for i in {1..20}; do
        if ! pgrep -x hyprsunset > /dev/null; then
          break
        fi
        sleep 0.1
      done
      # Force kill if still running
      if pgrep -x hyprsunset > /dev/null; then
        pkill -KILL hyprsunset
        sleep 0.2
      fi
    fi

    # Start hyprsunset with new temperature (if not turning off)
    if [ "$NEXT" != "off" ]; then
      ${pkgs-unstable.hyprsunset}/bin/hyprsunset -t $TEMP &
      disown
    fi

    # Save state and notify
    echo "$NEXT" > "$STATE_FILE"
    notify-send -t 2000 "$TITLE" "$DESC" -i "$ICON"
  '';

  battery-mode = pkgs.writeShellScriptBin "battery-mode" ''
    #!/usr/bin/env bash
    # Battery charge mode selector for ThinkPad (requires sudo privileges)
    # Cycles through: Conservation -> Balanced -> Full -> Conservation

    STATE_FILE="$HOME/.config/battery-mode-state"

    # Read current mode (default to balanced if file doesn't exist)
    if [ -f "$STATE_FILE" ]; then
      CURRENT_MODE=$(cat "$STATE_FILE")
    else
      CURRENT_MODE="balanced"
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
      pkexec tlp setcharge $START $STOP BAT0

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
    package = pkgs.hyprland;

    settings = {
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
        "walker --gapplication-service"
        "hypridle"
      ];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      input = {
        kb_layout = "fr";
        kb_options = "compose:ralt";  # Right Alt as compose key
        numlock_by_default = true;
        repeat_rate = 40;   # Slightly slower for comfort
        repeat_delay = 600; # Longer delay before repeat
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;  # Natural scrolling enabled
          disable_while_typing = true;
          tap-to-click = true;
          clickfinger_behavior = true;
          scroll_factor = 0.4;  # Slower, more precise scrolling
          middle_button_emulation = true;
        };

        sensitivity = 0;
      };

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;

        # Ristretto theme colors
        "col.active_border" = "rgb(e6d9db)";
        "col.inactive_border" = "rgba(44252580)";
      };

      decoration = {
        rounding = 3;

        blur = {
          enabled = true;
          size = 5;
          passes = 2;
          new_optimizations = true;
          xray = true;
          ignore_opacity = true;
        };

        shadow = {
          enabled = true;
          range = 15;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        active_opacity = 1.0;
        inactive_opacity = 0.96;
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
        smart_split = true;
        smart_resizing = true;
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
        vrr = 2;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
        force_default_wallpaper = 0;
        vfr = true;
        focus_on_activate = true;
      };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, kitty"
        "$mod, B, exec, brave"
        "$mod, E, exec, nemo"
        "$mod, D, exec, pkill walker || walker"
        "$mod SHIFT, D, exec, walker"
        "$mod, Q, killactive"
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"
        "$mod, Space, togglefloating"
        "$mod, P, pseudo"
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
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
        "$mod, V, exec, cliphist list | walker --dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, V, exec, cliphist wipe"
        "$mod, Escape, exec, hyprlock"
        "$mod SHIFT, Escape, exec, systemctl poweroff"
        "$mod CTRL, Escape, exec, systemctl reboot"
        "$mod, C, exec, hyprpicker -a"
        "$mod, N, exec, ${bluelight-toggle}/bin/bluelight-toggle"
        "$mod, M, exec, ${battery-mode}/bin/battery-mode"
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

      bindl = [
        ", XF86AudioMute, exec, pamixer -t && notify-send -t 1000 'Audio' \"$(pamixer --get-mute &> /dev/null && echo 'Muted' || echo 'Unmuted')\""
        ", XF86AudioMicMute, exec, pamixer --default-source -t && notify-send -t 1000 'Microphone' \"$(pamixer --default-source --get-mute &> /dev/null && echo 'Muted' || echo 'Unmuted')\""
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 5 && notify-send -t 500 'Volume' \"$(pamixer --get-volume)%\""
        ", XF86AudioLowerVolume, exec, pamixer -d 5 && notify-send -t 500 'Volume' \"$(pamixer --get-volume)%\""
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+ && notify-send -t 500 'Brightness' \"$(brightnessctl get)\""
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%- && notify-send -t 500 'Brightness' \"$(brightnessctl get)\""
      ];

      windowrule = [
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(blueman-manager)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
      ];

      windowrulev2 = [
        # Opacity rules
        "opacity 0.95 0.95,class:^(kitty)$"
        "opacity 0.95 0.95,class:^(thunar)$"
        "opacity 0.95 0.95,class:^(nemo)$"
        "suppressevent maximize, class:.*"
        "opacity 0.97 0.92,class:.*"
        "tile,class:^(Brave-browser)$"
        "opacity 1.0 0.97,class:^(Brave-browser)$"
        "opacity 1.0 1.0,title:^.*(YouTube|Netflix|Twitch|Zoom|Meet|Discord).*$"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "opacity 1.0 0.95,class:^(code-url-handler)$"
        "opacity 1.0 0.95,class:^(jetbrains-.*)$"

        # Picture-in-Picture
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
        "size 640 360,title:^(Picture-in-Picture)$"
        "move 100%-650 100%-370,title:^(Picture-in-Picture)$"

        # Walker launcher
        "float,class:^(walker)$"
        "center(1),class:^(walker)$"
        "size 800 600,class:^(walker)$"
        "stayfocused,class:^(walker)$"

        # Touchpad scroll adjustments
        "scrolltouchpad 1.5,class:^(kitty)$"
        "scrolltouchpad 1.5,class:^(Alacritty)$"
      ];
    };
  };

  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprlock
    brightnessctl
    cliphist
    wl-clipboard
    grim
    slurp
    libnotify
    pamixer
    pkgs-unstable.hyprsunset  # v0.3.3+ with SIGTERM/SIGINT fixes
    bluelight-toggle
    battery-mode
  ];
}