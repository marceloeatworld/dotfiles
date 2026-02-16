# Waybar configuration - Ristretto theme
# Scripts are in waybar-scripts/ directory
{ pkgs, config, ... }:

let
  theme = config.theme;
in
{
  # Systemd user service for VPN status refresh (triggered by VPN-DNS-SWITCH)
  systemd.user.services.waybar-vpn-refresh = {
    Unit = {
      Description = "Refresh Waybar VPN module";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.procps}/bin/pkill -RTMIN+8 waybar";
    };
  };
  # Deploy scripts from waybar-scripts/ directory
  home.file.".config/waybar/scripts/bitcoin.sh" = {
    source = ./waybar-scripts/bitcoin.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/removable-disks.sh" = {
    source = ./waybar-scripts/removable-disks.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/brightness-sync.sh" = {
    source = ./waybar-scripts/brightness-sync.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/vpn-status.sh" = {
    source = ./waybar-scripts/vpn-status.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/nix-updates.sh" = {
    source = ./waybar-scripts/nix-updates.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/systemd-failed.sh" = {
    source = ./waybar-scripts/systemd-failed.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/mako.sh" = {
    source = ./waybar-scripts/mako.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/monitor-rotation.sh" = {
    source = ./waybar-scripts/monitor-rotation.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/monitor-rotate-action.sh" = {
    source = ./waybar-scripts/monitor-rotate-action.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/wallets.py" = {
    source = ./waybar-scripts/wallets.py;
    executable = true;
  };

  home.file.".config/waybar/scripts/weather.py" = {
    source = ./waybar-scripts/weather.py;
    executable = true;
  };

  home.file.".config/waybar/scripts/polymarket.py" = {
    source = ./waybar-scripts/polymarket.py;
    executable = true;
  };

  home.file.".config/waybar/scripts/audio-switch.sh" = {
    source = ./waybar-scripts/audio-switch.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/mic-switch.sh" = {
    source = ./waybar-scripts/mic-switch.sh;
    executable = true;
  };

  home.file.".config/waybar/.env.example" = {
    source = ./waybar-scripts/.env.example;
  };

  # Bitcoin price alerts configuration example
  home.file.".config/waybar/bitcoin-alerts.conf.example" = {
    text = ''
      # Bitcoin Price Alerts Configuration
      #
      # Format: threshold_type=value
      #
      # Types:
      #   above=PRICE   - Alert when price goes ABOVE this value
      #   below=PRICE   - Alert when price goes BELOW this value
      #
      # Examples:

      # Alert when Bitcoin goes above $120,000
      #above=120000

      # Alert when Bitcoin drops below $100,000
      #below=100000

      # Multiple alerts are supported
      #above=125000
      #below=95000

      # To activate alerts:
      # 1. Copy this file: cp bitcoin-alerts.conf.example bitcoin-alerts.conf
      # 2. Uncomment and modify the alert thresholds above
      # 3. Waybar will check prices every 5 minutes and notify you
    '';
  };

  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        spacing = 2;  # Compact spacing between modules

        modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
        modules-center = [ ];
        modules-right = [
          # Finance (leftmost - less critical)
          "custom/polymarket"
          "custom/bitcoin"
          "custom/wallets"
          # System alerts (visible when issues)
          "custom/systemd-failed"
          "custom/mako"
          # Hardware (frequently checked)
          "custom/removable-disks"
          "pulseaudio"
          "pulseaudio#source"
          "backlight"
          # System stats
          "cpu"
          "memory"
          "temperature"
          "disk"
          # Connectivity
          "bluetooth"
          "network"
          "custom/vpn"
          # Environment
          "custom/weather"
          "battery"
          "custom/monitor-rotation"
          # Time & status (rightmost - always visible)
          "clock"
          "custom/nix-updates"
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
              months = "<span color='${theme.colors.yellow}'><b>{}</b></span>";
              days = "<span color='${theme.colors.foreground}'>{}</span>";
              weeks = "<span color='${theme.colors.yellow}'><b>W{}</b></span>";
              weekdays = "<span color='${theme.colors.yellow}'><b>{}</b></span>";
              today = "<span color='${theme.colors.red}'><b><u>{}</u></b></span>";
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
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-alt = "{icon} {time}";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
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
          # Waybar will auto-detect the default route interface
          # When VPN is active, it switches to the tunnel interface
          interface-types = [ "wifi" "ethernet" "bridge" "wireguard" "tun" ];  # Include WireGuard & VPN tunnels
          format = "󰌘 {ifname}";  # Generic format for VPN/tunnel interfaces
          format-wifi = "󰖩 {essid}";
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-linked = "󰌘 {ifname}";  # Interface up but no IP (shouldn't happen)
          format-disconnected = "󰖪";
          tooltip-format = "{ifname}\nIP: {ipaddr}\nGateway: {gwaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";  # Generic format for VPN/tunnel
          tooltip-format-wifi = "WiFi: {essid} ({signalStrength}%)\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-linked = "{ifname} (No IP)\nGateway: {gwaddr}";
          tooltip-format-disconnected = "No network connection";
          on-click = "nm-connection-editor";
          interval = 5;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰖁 ";
          format-icons = {
            headphone = "󰋋";
            hands-free = "󱡏";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰦢";
            car = "󰄋";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          tooltip-format = "Volume: {volume}%\nDevice: {desc}\n\nLeft: Switch output | Right: Switch mic | Middle: Hyprpwcenter | Scroll: Volume";
          on-click = "$HOME/.config/waybar/scripts/audio-switch.sh";
          on-click-right = "$HOME/.config/waybar/scripts/mic-switch.sh";
          on-click-middle = "hyprpwcenter";
          on-scroll-up = "swayosd-client --output-volume raise";
          on-scroll-down = "swayosd-client --output-volume lower";
        };

        "pulseaudio#source" = {
          format = "{format_source}";
          format-source = "󰍬 {volume}%";
          format-source-muted = "󰍭";
          tooltip-format = "Mic: {source_volume}%\nDevice: {source_desc}\n\nLeft: Mute | Right: Switch mic | Middle: Hyprpwcenter";
          on-click = "swayosd-client --input-volume mute-toggle";
          on-click-right = "$HOME/.config/waybar/scripts/mic-switch.sh";
          on-click-middle = "hyprpwcenter";
          on-scroll-up = "swayosd-client --input-volume raise";
          on-scroll-down = "swayosd-client --input-volume lower";
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
          on-click = "ghostty -e btop";
          interval = 2;
        };

        "memory" = {
          format = "󰍛 {percentage}%";
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nAvailable: {avail:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          on-click = "ghostty -e btop";
          interval = 5;
        };

        "temperature" = {
          thermal-zone = 0;  # AMD Ryzen 7 PRO 8840HS thermal zone
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-icons = [ "󰔏" "󱃃" "󰸁" ];
          tooltip-format = "Temperature: {temperatureC}°C";
          on-click = "ghostty -e btop";
        };

        "backlight" = {
          device = "amdgpu_bl1";  # AMD Radeon 780M backlight (was intel_backlight)
          format = "{icon} {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" "󱩎" "󱩏" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󰛨" ];
          tooltip-format = "Brightness: {percent}%\nScroll to adjust (syncs both screens)";
          on-scroll-up = "~/.config/waybar/scripts/brightness-sync.sh 5%+";
          on-scroll-down = "~/.config/waybar/scripts/brightness-sync.sh 5%-";
          # on-click removed to prevent system freeze
        };

        "custom/weather" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/weather.py";
          return-type = "json";
          interval = 600;  # Update every 10 minutes (600 seconds) - cached
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://open-meteo.com";
          signal = 4;  # Use SIGRTMIN+4 for manual refresh
          on-scroll-up = "pkill -RTMIN+4 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+4 waybar";  # Force refresh on scroll
        };

        "custom/polymarket" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/polymarket.py";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds) - cached
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://polymarket.com";
          signal = 2;  # Use SIGRTMIN+2 for manual refresh
          on-scroll-up = "pkill -RTMIN+2 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+2 waybar";  # Force refresh on scroll
        };

        "custom/bitcoin" = {
          exec = "~/.config/waybar/scripts/bitcoin.sh";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds)
          format = "₿ {}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://mempool.space/";
          signal = 1;  # Use SIGRTMIN+1 for manual refresh
          on-scroll-up = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
        };

        "custom/wallets" = {
          exec = "${pkgs.python313}/bin/python3 ~/.config/waybar/scripts/wallets.py";
          return-type = "json";
          interval = 300;  # Update every 5 minutes (300 seconds) - updates price only, balances cached
          format = "{}";  # Shows balance - blurred by CSS, clear on hover
          tooltip = true;
          signal = 3;  # Use SIGRTMIN+3 for manual refresh
          on-scroll-up = "pkill -RTMIN+3 waybar";  # Force price refresh (EUR/USD only, balances stay cached)
          on-scroll-down = "pkill -RTMIN+3 waybar";  # Force price refresh (EUR/USD only, balances stay cached)
        };

        # System Monitoring Modules
        "custom/vpn" = {
          exec = "~/.config/waybar/scripts/vpn-status.sh";
          return-type = "json";
          interval = 1;  # Update every 1 second for instant detection
          format = "{}";
          tooltip = true;
          on-click = "protonvpn-app";  # Open Proton VPN GUI
          signal = 8;  # Use SIGRTMIN+8 for manual refresh
        };

        "custom/nix-updates" = {
          exec = "~/.config/waybar/scripts/nix-updates.sh";
          return-type = "json";
          interval = 3600;  # Update every hour
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.hyprland}/bin/hyprctl dispatch exec '[float;size 800 600;center]' 'ghostty --wait-after-command -e sh -c \"cd ~/dotfiles/thinkpad-p14s-gen5 && nix flake update\"'";
        };

        "custom/systemd-failed" = {
          exec = "~/.config/waybar/scripts/systemd-failed.sh";
          return-type = "json";
          interval = 60;  # Update every minute
          format = "{}";
          tooltip = true;
          on-click = "ghostty --wait-after-command -e systemctl --failed";
        };

        "custom/mako" = {
          exec = "~/.config/waybar/scripts/mako.sh";
          return-type = "json";
          interval = 5;  # Update every 5 seconds
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.mako}/bin/makoctl invoke";
          on-click-right = "${pkgs.mako}/bin/makoctl dismiss --all";
        };

        "custom/removable-disks" = {
          exec = "~/.config/waybar/scripts/removable-disks.sh";
          return-type = "json";
          interval = 5;  # Update every 5 seconds to detect new devices
          format = "{}";
          tooltip = true;
          on-click = "nemo";  # Open file manager
        };

        "custom/monitor-rotation" = {
          exec = "~/.config/waybar/scripts/monitor-rotation.sh";
          return-type = "json";
          interval = 10;  # Update every 10 seconds
          format = "{}";
          tooltip = true;
          on-click = "~/.config/waybar/scripts/monitor-rotate-action.sh && pkill -RTMIN+9 waybar";
          signal = 9;  # Use SIGRTMIN+9 for manual refresh
        };

        "tray" = {
          spacing = 10;
          icon-size = 18;
        };
      };
    };

    style = ''
      /* Ultra-minimal old-school style */
      @define-color bg ${theme.colors.background};
      @define-color fg ${theme.colors.foreground};
      @define-color dim ${theme.colors.comment};
      @define-color accent ${theme.colors.yellow};

      * {
        border: none;
        border-radius: 0;
        font-family: "${theme.fonts.mono}", monospace;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background: @bg;
        color: @fg;
      }

      /* Workspaces - minimal */
      #workspaces { margin: 0 4px; }
      #workspaces button {
        padding: 0 6px;
        color: @dim;
        background: transparent;
      }
      #workspaces button.active {
        color: @accent;
      }
      #workspaces button.urgent {
        color: @fg;
      }
      #workspaces button.empty { color: @dim; opacity: 0.4; }

      /* Window title */
      #window {
        margin: 0 8px;
        color: @dim;
      }

      /* Clock */
      #clock {
        padding: 0 8px;
        color: @fg;
      }

      /* All modules - pure text, no backgrounds */
      #custom-bitcoin, #custom-wallets, #custom-vpn, #custom-nix-updates,
      #custom-systemd-failed, #custom-mako, #custom-monitor-rotation,
      #custom-weather, #custom-polymarket, #custom-removable-disks,
      #pulseaudio, #pulseaudio.source, #bluetooth, #network, #disk, #cpu, #memory,
      #temperature, #backlight, #battery, #tray {
        padding: 0 6px;
        background: transparent;
        color: @dim;
      }

      /* Accent for important */
      #custom-bitcoin { color: @accent; }

      /* Wallets - blurred */
      #custom-wallets {
        color: transparent;
        text-shadow: 0 0 6px @dim;
      }
      #custom-wallets:hover {
        color: @fg;
        text-shadow: none;
      }

      /* States */
      #battery.charging { color: @fg; }
      #battery.warning:not(.charging) { color: @accent; }
      #battery.critical:not(.charging) { color: @fg; }
      #pulseaudio.muted { opacity: 0.3; }
      #pulseaudio.source.muted { opacity: 0.3; }
      #bluetooth.connected { color: @fg; }
      #bluetooth.off, #bluetooth.disabled { opacity: 0.3; }
      #temperature.critical { color: @fg; }

      /* VPN */
      #custom-vpn.connected { color: @fg; }
      #custom-vpn.disconnected { color: @dim; opacity: 0.5; }

      /* Updates & alerts */
      #custom-nix-updates.updates { color: @accent; }
      #custom-systemd-failed.warning { color: @fg; }
      #custom-mako.notification { color: @fg; }

      /* Tooltip - minimal */
      tooltip {
        background: @bg;
        border: 1px solid @dim;
        color: @fg;
      }
    '';
  };

  # Waybar dependencies (other tools installed elsewhere)
  # - brightnessctl: in hyprland.nix (for hypridle)
  # - btop: in btop.nix (with Ristretto theme)
  # - blueman: in home.nix
  # - hyprpwcenter: in system/sound.nix (replaced pavucontrol)
  home.packages = with pkgs; [
    networkmanagerapplet    # Network manager tray applet
  ];
}