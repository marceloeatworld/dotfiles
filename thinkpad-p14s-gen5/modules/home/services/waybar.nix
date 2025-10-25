# Waybar - Simple colors (Ristretto theme)
{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 6;

        modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "bluetooth"
          "network"
          "disk"
          "cpu"
          "memory"
          "temperature"
          "backlight"
          "battery"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            "10" = "10";
            active = "";
            default = "";
          };
          all-outputs = false;
          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
          format = "{}";
        };

        "clock" = {
          format = " {:%H:%M}";
          format-alt = " {:%A, %d %B %Y - %H:%M:%S}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#f9cc6c'><b>{}</b></span>";
              days = "<span color='#e6d9db'>{}</span>";
              weeks = "<span color='#f9cc6c'><b>W{}</b></span>";
              weekdays = "<span color='#f9cc6c'><b>{}</b></span>";
              today = "<span color='#fd6883'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [ "" "" "" "" "" ];
          tooltip-format = "{timeTo}\nPower: {power}W";
        };

        "bluetooth" = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          format-disabled = "";
          format-off = "";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        "network" = {
          format-wifi = "󰖩 {essid}";
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-disconnected = "󰖪";
          tooltip-format-wifi = "WiFi: {essid} ({signalStrength}%)\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-disconnected = "No network connection";
          on-click = "nm-connection-editor";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰖁";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          tooltip-format = "Volume: {volume}%\nDevice: {desc}";
          on-click = "pavucontrol";
          on-click-right = "pamixer -t";
          on-scroll-up = "pamixer -i 5";
          on-scroll-down = "pamixer -d 5";
        };

        "disk" = {
          format = "󰋊 {percentage_used}%";
          path = "/";
          tooltip-format = "Disk Usage: {used} / {total}\nAvailable: {free}";
          on-click = "nemo /";
        };

        "cpu" = {
          format = "󰻠 {usage}%";
          tooltip-format = "CPU Usage: {usage}%\nLoad: {load}";
          on-click = "kitty --class btop -e btop";
          interval = 2;
        };

        "memory" = {
          format = "󰍛 {percentage}%";
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nAvailable: {avail:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          on-click = "kitty --class btop -e btop";
          interval = 5;
        };

        "temperature" = {
          thermal-zone = 2;
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "󰔏" "󱃃" "󰸁" ];
          tooltip-format = "Temperature: {temperatureC}°C";
          on-click = "kitty --class btop -e btop";
        };

        "backlight" = {
          device = "intel_backlight";
          format = "{icon} {percent}%";
          format-icons = [ "" "" "" "" "" "" "" "" "" ];
          tooltip-format = "Brightness: {percent}%";
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
        };

        "tray" = {
          spacing = 10;
          icon-size = 18;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(44, 37, 37, 0.93);
        color: #e6d9db;
      }

      #workspaces {
        margin: 0 6px;
      }

      #workspaces button {
        padding: 0 10px;
        color: #e6d9db;
        background: transparent;
        border-bottom: 2px solid transparent;
      }

      #workspaces button:hover {
        background: rgba(230, 217, 219, 0.1);
      }

      #workspaces button.active {
        background: #f9cc6c;
        color: #2c2525;
        border-bottom: 2px solid #f9cc6c;
      }

      #workspaces button.urgent {
        background: #fd6883;
        color: #2c2525;
        border-bottom: 2px solid #fd6883;
      }

      #window {
        margin: 0 12px;
        padding: 0 10px;
        color: #f9cc6c;
      }

      #clock {
        padding: 0 16px;
        margin: 0 8px;
        background: rgba(249, 204, 108, 0.15);
        color: #f9cc6c;
        border-radius: 10px;
      }

      #pulseaudio,
      #bluetooth,
      #network,
      #disk,
      #cpu,
      #memory,
      #temperature,
      #backlight,
      #battery,
      #tray {
        padding: 0 12px;
        margin: 0 3px;
        background: rgba(64, 62, 65, 0.85);
        border-radius: 10px;
        color: #e6d9db;
      }

      #pulseaudio.muted {
        color: #fd6883;
      }

      #battery.charging,
      #battery.plugged {
        color: #adda78;
      }

      #battery.warning:not(.charging) {
        color: #f9cc6c;
      }

      #battery.critical:not(.charging) {
        color: #fd6883;
      }

      #temperature.critical {
        color: #fd6883;
      }

      tooltip {
        background: rgba(44, 37, 37, 0.95);
        border: 2px solid rgba(249, 204, 108, 0.5);
        border-radius: 10px;
        color: #e6d9db;
      }
    '';
  };

  home.packages = with pkgs; [
    pavucontrol
    blueman
    networkmanagerapplet
    brightnessctl
    btop
  ];
}