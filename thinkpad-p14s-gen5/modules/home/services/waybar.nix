# Waybar configuration
{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" "hyprland/submap" ];
        modules-center = [ "hyprland/window" ];
        modules-right = [
          "pulseaudio"
          "bluetooth"
          "network"
          "cpu"
          "memory"
          "temperature"
          "battery"
          "clock"
          "tray"
        ];

        # Modules configuration
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
          };
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
        };

        "clock" = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        "battery" = {
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-icons = [ "" "" "" "" "" ];
          tooltip-format = "Power: {power}W";
        };

        "bluetooth" = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };

        "network" = {
          format-wifi = "{icon} {signalStrength}%";
          format-ethernet = " {bandwidthDownBytes}";
          format-disconnected = "⚠ Disconnected";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
          tooltip-format = "{essid}\n⇣{bandwidthDownBytes} ⇡{bandwidthUpBytes}";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        "cpu" = {
          format = "{usage}% ";
          tooltip = true;
        };

        "memory" = {
          format = "{}% ";
        };

        "temperature" = {
          critical-threshold = 80;
          format = "{temperatureC}°C {icon}";
          format-icons = [ "" "" "" ];
        };

        "tray" = {
          spacing = 10;
        };
      };
    };

    style = ''
      /* Ristretto theme */
      @define-color foreground #e6d9db;
      @define-color background #2c2525;

      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(44, 37, 37, 0.95);
        color: @foreground;
      }

      #workspaces button {
        padding: 0 8px;
        color: @foreground;
        background: transparent;
      }

      #workspaces button.active {
        background: #f9cc6c;
        color: @background;
      }

      #workspaces button.urgent {
        background: #fd6883;
        color: @background;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #temperature,
      #network,
      #bluetooth,
      #pulseaudio,
      #tray {
        padding: 0 10px;
        margin: 0 2px;
        background: rgba(64, 62, 65, 0.8);
        border-radius: 8px;
        color: @foreground;
      }

      #battery.charging {
        background: #adda78;
        color: @background;
      }

      #battery.warning:not(.charging) {
        background: #f9cc6c;
        color: @background;
      }

      #battery.critical:not(.charging) {
        background: #fd6883;
        color: @background;
      }

      #temperature.critical {
        background: #fd6883;
        color: @background;
      }
    '';
  };
}
