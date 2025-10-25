# Hyprland - FIXED gestures
{ pkgs, ... }:

let
  bluelight-toggle = pkgs.writeShellScriptBin "bluelight-toggle" ''
    #!/usr/bin/env bash
    if pgrep -x hyprsunset > /dev/null; then
      current=$(pgrep -af hyprsunset | grep -oP '\-t \K[0-9]+' || echo "0")
      case "$current" in
        6500|0)
          pkill hyprsunset
          hyprsunset -t 5500 &
          notify-send -t 2000 "Blue Light Filter" "Low (5500K)" -i weather-clear-night
          ;;
        5500)
          pkill hyprsunset
          hyprsunset -t 4500 &
          notify-send -t 2000 "Blue Light Filter" "Medium (4500K)" -i weather-clear-night
          ;;
        4500)
          pkill hyprsunset
          hyprsunset -t 3500 &
          notify-send -t 2000 "Blue Light Filter" "High (3500K)" -i weather-clear-night
          ;;
        3500)
          pkill hyprsunset
          hyprsunset -t 2500 &
          notify-send -t 2000 "Blue Light Filter" "Very High (2500K)" -i weather-clear-night
          ;;
        *)
          pkill hyprsunset
          notify-send -t 2000 "Blue Light Filter" "Off" -i weather-clear
          ;;
      esac
    else
      hyprsunset -t 5500 &
      notify-send -t 2000 "Blue Light Filter" "Low (5500K)" -i weather-clear-night
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
        numlock_by_default = true;
        repeat_rate = 45;
        repeat_delay = 300;
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
          clickfinger_behavior = true;
          scroll_factor = 0.5;
          middle_button_emulation = true;
        };

        sensitivity = 0;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
        resize_on_border = true;
        allow_tearing = false;
      };

      decoration = {
        rounding = 10;

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
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy && notify-send 'Screenshot' 'Copié dans le presse-papier'"
        "$mod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send 'Screenshot' 'Sauvegardé dans Pictures/Screenshots'"
        "SHIFT, Print, exec, grim - | wl-copy && notify-send 'Screenshot' 'Écran complet copié'"
        "$mod SHIFT, Print, exec, grim ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && notify-send 'Screenshot' 'Écran complet sauvegardé'"
        "$mod SHIFT, R, exec, killall waybar && waybar"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bindl = [
        ", XF86AudioMute, exec, pamixer -t && notify-send -t 1000 'Audio' \"$(pamixer --get-mute &> /dev/null && echo 'Muet' || echo 'Son activé')\""
        ", XF86AudioMicMute, exec, pamixer --default-source -t && notify-send -t 1000 'Microphone' \"$(pamixer --default-source --get-mute &> /dev/null && echo 'Muet' || echo 'Activé')\""
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 5 && notify-send -t 500 'Volume' \"$(pamixer --get-volume)%\""
        ", XF86AudioLowerVolume, exec, pamixer -d 5 && notify-send -t 500 'Volume' \"$(pamixer --get-volume)%\""
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+ && notify-send -t 500 'Luminosité' \"$(brightnessctl get)\""
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%- && notify-send -t 500 'Luminosité' \"$(brightnessctl get)\""
      ];

      windowrule = [
        "float, class:^(pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(blueman-manager)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
      ];

      windowrulev2 = [
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
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
        "size 640 360,title:^(Picture-in-Picture)$"
        "move 100%-650 100%-370,title:^(Picture-in-Picture)$"
        "float,class:^(walker)$"
        "center,class:^(walker)$"
        "size 800 600,class:^(walker)$"
        "stayfocused,class:^(walker)$"
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
    hyprsunset
    bluelight-toggle
  ];
}