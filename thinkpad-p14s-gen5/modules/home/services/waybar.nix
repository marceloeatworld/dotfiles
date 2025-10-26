# Waybar - Simple colors (Ristretto theme)
{ pkgs, config, ... }:

let
  removableDisksScript = pkgs.writeShellScriptBin "removable-disks-waybar" ''
    #!/usr/bin/env bash
    # List removable USB/external disks and allow ejecting

    # Get list of removable devices (excluding loop devices)
    devices=$(lsblk -nrpo "name,type,rm,size,mountpoint,label" | awk '$2=="part" && $3=="1" {print $0}')

    if [ -z "$devices" ]; then
      echo '{"text": "", "tooltip": "No removable disks"}'
      exit 0
    fi

    # Count mounted devices
    count=$(echo "$devices" | wc -l)

    # Build tooltip with device list
    tooltip="Removable Disks ($count):\n"
    while IFS= read -r line; do
      name=$(echo "$line" | awk '{print $1}')
      size=$(echo "$line" | awk '{print $4}')
      mount=$(echo "$line" | awk '{print $5}')
      label=$(echo "$line" | awk '{print $6}')

      if [ -n "$mount" ] && [ "$mount" != "" ]; then
        tooltip="$tooltip\n● $(basename $name) - $size - $label"
        tooltip="$tooltip\n  Mounted: $mount"
      else
        tooltip="$tooltip\n○ $(basename $name) - $size - $label (not mounted)"
      fi
    done <<< "$devices"

    tooltip="$tooltip\n\nClick to open file manager"

    echo "{\"text\": \"󰋊 $count\", \"tooltip\": \"$tooltip\"}"
  '';

  bitcoinScript = pkgs.writeShellScriptBin "bitcoin-waybar" ''
    #!/usr/bin/env bash
    # Fetch Bitcoin price in USD and EUR from Coinbase API

    # Fetch USD price from Coinbase
    usd_response=$(${pkgs.curl}/bin/curl -s "https://api.coinbase.com/v2/prices/BTC-USD/spot")
    eur_response=$(${pkgs.curl}/bin/curl -s "https://api.coinbase.com/v2/prices/BTC-EUR/spot")

    if [ $? -ne 0 ] || [ -z "$usd_response" ] || [ -z "$eur_response" ]; then
      echo '{"text": "BTC: N/A", "tooltip": "Failed to fetch Bitcoin price"}'
      exit 0
    fi

    # Parse JSON using jq
    usd=$(echo "$usd_response" | ${pkgs.jq}/bin/jq -r '.data.amount // "N/A"')
    eur=$(echo "$eur_response" | ${pkgs.jq}/bin/jq -r '.data.amount // "N/A"')

    if [ "$usd" = "N/A" ] || [ "$eur" = "N/A" ]; then
      echo '{"text": "BTC: N/A", "tooltip": "Failed to parse Bitcoin price"}'
      exit 0
    fi

    # Format prices (example: 100k USD)
    usd_formatted=$(printf "%.0fk" $(echo "$usd / 1000" | ${pkgs.bc}/bin/bc))
    eur_formatted=$(printf "%.0fk" $(echo "$eur / 1000" | ${pkgs.bc}/bin/bc))

    # Format full prices with thousands separator
    usd_full=$(printf "%'.0f" "$usd" 2>/dev/null || echo "$usd")
    eur_full=$(printf "%'.0f" "$eur" 2>/dev/null || echo "$eur")

    # Output JSON for Waybar - show only USD in text, both in tooltip
    echo "{\"text\": \"$usd_formatted\", \"tooltip\": \"Bitcoin Price\nUSD: \$$usd_full ($usd_formatted)\nEUR: €$eur_full ($eur_formatted)\"}"
  '';
in
{
  # Create scripts in waybar config directory
  home.file.".config/waybar/scripts/bitcoin.sh" = {
    source = "${bitcoinScript}/bin/bitcoin-waybar";
    executable = true;
  };

  home.file.".config/waybar/scripts/removable-disks.sh" = {
    source = "${removableDisksScript}/bin/removable-disks-waybar";
    executable = true;
  };

  # Bitcoin wallet balance monitor (privacy-focused zpub derivation)
  home.file.".config/waybar/scripts/wallets.py" = {
    source = ./waybar-scripts/wallets.py;
    executable = true;
  };

  # Wallet configuration template
  home.file.".config/waybar/.env.example" = {
    source = ./waybar-scripts/.env.example;
  };

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 2;

        modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/bitcoin"
          "custom/wallets"
          "custom/removable-disks"
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
          format = "{name}";  # Show workspace number/name
          on-click = "activate";
          sort-by-number = true;
          all-outputs = true;  # Show workspaces from all monitors
          active-only = false;

          # Show workspaces 1-10
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
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
          thermal-zone = 0;  # AMD Ryzen 7 PRO 8840HS thermal zone
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "󰔏" "󱃃" "󰸁" ];
          tooltip-format = "Temperature: {temperatureC}°C";
          on-click = "kitty --class btop -e btop";
        };

        "backlight" = {
          device = "amdgpu_bl1";  # AMD Radeon 780M backlight (was intel_backlight)
          format = "{icon} {percent}%";
          format-icons = [ "" "" "" "" "" "" "" "" "" ];
          tooltip-format = "Brightness: {percent}%\nScroll to adjust";
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
          # on-click removed to prevent system freeze
        };

        "custom/bitcoin" = {
          exec = "~/.config/waybar/scripts/bitcoin.sh";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds)
          format = "₿ {}";
          tooltip = true;
          on-scroll-up = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
        };

        "custom/wallets" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/wallets.py";
          return-type = "json";
          interval = 1200;  # Update every 20 minutes (1200 seconds) - uses cache, very fast
          format = "₿ {}";
          tooltip = true;
          on-click = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/wallets.py --force";  # Force refresh on click
        };

        "custom/removable-disks" = {
          exec = "~/.config/waybar/scripts/removable-disks.sh";
          return-type = "json";
          interval = 5;  # Update every 5 seconds to detect new devices
          format = "{}";
          tooltip = true;
          on-click = "nemo";  # Open file manager
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
        min-width: 30px;
        color: #e6d9db;
        background: transparent;
        border-bottom: 2px solid transparent;
        border-radius: 0;
        transition: all 0.2s ease;
      }

      #workspaces button:hover {
        background: rgba(230, 217, 219, 0.1);
        border-bottom: 2px solid rgba(230, 217, 219, 0.3);
      }

      #workspaces button.active {
        background: #f9cc6c;
        color: #2c2525;
        border-bottom: 2px solid #f9cc6c;
        font-weight: bold;
      }

      #workspaces button.urgent {
        background: #fd6883;
        color: #2c2525;
        border-bottom: 2px solid #fd6883;
      }

      #workspaces button.visible {
        color: #f9cc6c;
      }

      #workspaces button.empty {
        opacity: 0.5;
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

      #custom-bitcoin,
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
        padding: 0 10px;
        margin: 0 2px;
        background: rgba(64, 62, 65, 0.85);
        border-radius: 6px;
        color: #e6d9db;
      }

      #custom-bitcoin {
        padding: 0 8px;
        font-size: 12px;
        background: rgba(249, 204, 108, 0.2);
        color: #f9cc6c;
      }

      #custom-removable-disks {
        padding: 0 10px;
        background: rgba(173, 218, 120, 0.2);
        color: #adda78;
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