# Waybar configuration
# Scripts are in waybar-scripts/ directory
{ pkgs, config, lib, inputs, ... }:

let
  theme = config.theme;
  hyprshutdown = inputs.hyprshutdown.packages.${pkgs.stdenv.hostPlatform.system}.default;
  walletPython = pkgs.python313.withPackages (ps: with ps; [
    embit
    requests
  ]);

  # Gamemode toggle: status probe + click handler (extracted from inline shell)
  gamemodeStatus = pkgs.writeShellScript "waybar-gamemode-status" ''
    PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/waybar-gamemode.pid"
    if [ -s "$PID_FILE" ] && kill -0 "$(${pkgs.coreutils}/bin/cat "$PID_FILE")" 2>/dev/null; then
      echo '{"text":"󰊗","tooltip":"GameMode: ON\nClick to disable","class":"active"}'
    else
      ${pkgs.coreutils}/bin/rm -f "$PID_FILE"
      echo '{"text":"󰊗","tooltip":"GameMode: off\nClick to enable","class":"inactive"}'
    fi
  '';

  gamemodeToggle = pkgs.writeShellScript "waybar-gamemode-toggle" ''
    PID_FILE="''${XDG_RUNTIME_DIR:-/tmp}/waybar-gamemode.pid"
    if [ -s "$PID_FILE" ] && kill -0 "$(${pkgs.coreutils}/bin/cat "$PID_FILE")" 2>/dev/null; then
      kill -TERM "$(${pkgs.coreutils}/bin/cat "$PID_FILE")" 2>/dev/null || true
      ${pkgs.coreutils}/bin/rm -f "$PID_FILE"
      ${pkgs.libnotify}/bin/notify-send 'GameMode' '󰊗 Disabled'
    else
      ${pkgs.gamemode}/bin/gamemoderun ${pkgs.coreutils}/bin/sleep infinity &
      echo "$!" > "$PID_FILE"
      ${pkgs.libnotify}/bin/notify-send 'GameMode' '󰊗 Enabled'
    fi
    ${pkgs.procps}/bin/pkill -RTMIN+11 waybar 2>/dev/null || true
  '';

  themeStatus = pkgs.writeShellScript "waybar-theme-status" ''
    state_file="$HOME/.config/theme/current-name"
    theme="auto"
    if [ -f "$state_file" ]; then
      theme="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < "$state_file")"
    fi

    case "$theme" in
      neobrutalist-light)
        text="󰖨"
        class="light"
        tooltip="Theme: light | Left: dark | Right: auto"
        ;;
      neobrutalist)
        text="󰖔"
        class="dark"
        tooltip="Theme: dark | Left: light | Right: auto"
        ;;
      *)
        text="󰔎"
        class="auto"
        tooltip="Theme: auto | Left: toggle | Right: auto"
        ;;
    esac

    printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class"
  '';

  themeToggle = pkgs.writeShellScript "waybar-theme-toggle" ''
    state_file="$HOME/.config/theme/current-name"
    theme=""
    if [ -f "$state_file" ]; then
      theme="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < "$state_file")"
    fi

    if [ "$theme" = "neobrutalist-light" ]; then
      ${pkgs.systemd}/bin/systemctl --user start runtime-theme-night.service
    else
      ${pkgs.systemd}/bin/systemctl --user start runtime-theme-day.service
    fi
    ${pkgs.procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  '';

  themeAuto = pkgs.writeShellScript "waybar-theme-auto" ''
    ${pkgs.systemd}/bin/systemctl --user start runtime-theme-sync.service
    ${pkgs.procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  '';

  themeDay = pkgs.writeShellScript "waybar-theme-day" ''
    ${pkgs.systemd}/bin/systemctl --user start runtime-theme-day.service
    ${pkgs.procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  '';

  # Voice dictation indicator - reads the state file written by voice-terminal
  voiceStatus = pkgs.writeShellScript "waybar-voice-status" ''
    state=""
    f="''${XDG_RUNTIME_DIR:-/tmp}/voice-terminal/state"
    [ -f "$f" ] && state="$(cat "$f")"
    case "$state" in
      recording)    printf '{"text":"󰍬 REC","tooltip":"Voice: recording - press the Copilot key to stop","class":"recording"}\n' ;;
      transcribing) printf '{"text":"󰍬 ...","tooltip":"Voice: transcribing...","class":"transcribing"}\n' ;;
      downloading)  printf '{"text":"󰍬 DL","tooltip":"Voice: downloading Whisper model (874 MB, one time)","class":"downloading"}\n' ;;
      *)            printf '{"text":""}\n' ;;
    esac
  '';

  themeNight = pkgs.writeShellScript "waybar-theme-night" ''
    ${pkgs.systemd}/bin/systemctl --user start runtime-theme-night.service
    ${pkgs.procps}/bin/pkill -RTMIN+9 waybar 2>/dev/null || true
  '';

  # USB disk ejection handler (extracted from inline shell)
  ejectUsb = pkgs.writeShellScript "waybar-eject-usb" ''
    USB=$(${pkgs.util-linux}/bin/lsblk -nrpo name,type,tran | ${pkgs.gawk}/bin/awk '$2=="disk" && $3=="usb" {print $1}' | ${pkgs.coreutils}/bin/head -1)
    if [ -z "$USB" ]; then
      ${pkgs.libnotify}/bin/notify-send 'USB' 'No USB to eject'
      exit 0
    fi
    while IFS= read -r PART; do
      ${pkgs.udisks2}/bin/udisksctl unmount -b "$PART" 2>/dev/null || true
    done < <(${pkgs.util-linux}/bin/lsblk -nrpo name,type "$USB" | ${pkgs.gawk}/bin/awk '$2=="part" {print $1}')
    ${pkgs.udisks2}/bin/udisksctl power-off -b "$USB" 2>/dev/null && \
      ${pkgs.libnotify}/bin/notify-send 'USB' '󰕓 Safe to remove' || \
      ${pkgs.libnotify}/bin/notify-send 'USB' 'No USB to eject'
  '';

  # Bluetooth power toggle (extracted from inline shell)
  bluetoothToggle = pkgs.writeShellScript "waybar-bluetooth-toggle" ''
    if ${pkgs.bluez}/bin/bluetoothctl show | ${pkgs.gnugrep}/bin/grep -q 'Powered: yes'; then
      ${pkgs.bluez}/bin/bluetoothctl power off
    else
      ${pkgs.bluez}/bin/bluetoothctl power on
    fi
  '';

  # Both scripts append to a click log: the waybar drawer buttons were reported
  # dead (click produced no visible effect and no journal trace), so the log
  # proves whether waybar spawned the script at all vs hyprshutdown failing.
  poweroffWithConfirm = pkgs.writeShellScript "waybar-poweroff-with-confirm" ''
    LOG="$HOME/.local/state/waybar-power.log"
    echo "$(${pkgs.coreutils}/bin/date '+%F %T') poweroff button clicked" >> "$LOG"
    exec ${pkgs.util-linux}/bin/setsid ${hyprshutdown}/bin/hyprshutdown \
      -t 'Shutting down...' --verbose \
      --post-cmd '${pkgs.systemd}/bin/systemctl poweroff' >> "$LOG" 2>&1
  '';

  rebootWithConfirm = pkgs.writeShellScript "waybar-reboot-with-confirm" ''
    LOG="$HOME/.local/state/waybar-power.log"
    echo "$(${pkgs.coreutils}/bin/date '+%F %T') reboot button clicked" >> "$LOG"
    exec ${pkgs.util-linux}/bin/setsid ${hyprshutdown}/bin/hyprshutdown \
      -t 'Restarting...' --verbose \
      --post-cmd '${pkgs.systemd}/bin/systemctl reboot' >> "$LOG" 2>&1
  '';

in
{
  # Systemd user service for VPN status refresh (triggered by VPN-DNS-SWITCH)
  systemd.user.services.waybar-vpn-refresh = {
    Unit = {
      Description = "Refresh Waybar VPN module";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.runtimeShell} -c '${pkgs.procps}/bin/pkill -RTMIN+8 waybar || true'";
    };
  };

  # Harden the waybar service against the recurring glibmm SIGSEGV
  # Home-manager already sets Restart=on-failure; override to "always" with backoff
  systemd.user.services.waybar = {
    Unit = {
      StartLimitBurst = 20;
      StartLimitIntervalSec = "5min";
    };
    Service = {
      Restart = lib.mkForce "always";
      RestartSec = "2s";
    };
  };
  # Theme colors for scripts (sourced by waybar scripts for Pango markup)
  home.file.".config/waybar/scripts/theme-colors.sh".text = ''
    # Auto-generated from Home Manager. Runtime theme switcher updates
    # ~/.config/theme/current without requiring a rebuild.
    if [ -r "$HOME/.config/theme/current/colors.sh" ]; then
      . "$HOME/.config/theme/current/colors.sh"
    else
      C_FG="${theme.colors.foreground}"
      C_DIM="${theme.colors.foregroundDim}"
      C_MUTED="${theme.colors.comment}"
      C_ACCENT="${theme.colors.accent}"
      C_RED="${theme.colors.red}"
      C_GREEN="${theme.colors.green}"
      C_BLUE="${theme.colors.blue}"
      C_ORANGE="${theme.colors.orange}"
      C_CYAN="${theme.colors.cyan}"
      C_MAGENTA="${theme.colors.magenta}"
    fi
  '';

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

  home.file.".config/waybar/scripts/vpn-selector.sh" = {
    source = ./waybar-scripts/vpn-selector.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/nix-updates.sh" = {
    source = ./waybar-scripts/nix-updates.sh;
    executable = true;
  };

  home.file.".config/waybar/scripts/nix-quick-update.sh" = {
    source = ./waybar-scripts/nix-quick-update.sh;
    executable = true;
  };

  # NOTE: systemd-failed.sh removed — replaced by built-in systemd-failed-units module

  home.file.".config/waybar/scripts/mako.sh" = {
    source = ./waybar-scripts/mako.sh;
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

  home.file.".config/waybar/scripts/audio-status.sh" = {
    source = ./waybar-scripts/audio-status.sh;
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
      # 3. Waybar will check prices every 10 minutes and notify you
    '';
  };

  programs.waybar = {
    enable = true;

    # Auto-restart on crash (recurring glibmm SIGSEGV; first seen on 0.14.0, still occurs on the 0.15 master pin)
    # Home-manager generates a systemd user unit tied to graphical-session.target
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 33;
        spacing = 2;
        reload_style_on_change = true;  # Auto-reload CSS on theme change (no waybar restart)

        modules-left = [ "hyprland/workspaces" "hyprland/submap" "hyprland/window" ];
        modules-center = [ "mpris" ];  # Just the media title — double-click MPRIS to dock YouTube
        modules-right = [
          # ── Alerts ──
          "custom/voice"              # Voice dictation state (recording/transcribing)
          "privacy"                   # Mic/screenshare indicator
          "systemd-failed-units"      # Built-in, event-driven
          "custom/sep"
          # ── Glanceable info ──
          "group/finance"             # Bitcoin (leader) → wallets, polymarket
          "custom/weather"
          "custom/sep"
          # ── Audio & display ──
          "group/audio"               # Output (leader) → mic, brightness
          "custom/sep"
          # ── Connectivity ──
          "group/connectivity"        # Network (leader) → VPN, Bluetooth
          "custom/sep"
          # ── Hardware drawer ──
          "group/hardware"            # CPU (leader) → memory, temps, disk
          "custom/removable-disks"
          "custom/sep"
          # ── Session ──
          "battery"
          "custom/theme"
          "clock"
          "custom/sep"
          # ── Tools & power ──
          "group/tools"               # Nix (leader) → notifications, layout, idle, gamemode
          "group/power"              # Lock (leader) → shutdown, reboot
          "tray"
        ];

        # ── Drawer groups (collapse modules to save space) ──
        "group/finance" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            hide-delay = 10000; # Drawer stays open 10s after the pointer leaves (upstream since 0.15)
            children-class = "drawer-child";
            transition-left-to-right = true;
          };
          modules = [
            "custom/bitcoin"    # Always visible (group leader)
            "custom/wallets"    # Hidden in drawer
            "custom/polymarket"
          ];
        };

        "group/audio" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            hide-delay = 10000; # Drawer stays open 10s after the pointer leaves (upstream since 0.15)
            children-class = "drawer-child";
            transition-left-to-right = false;
          };
          modules = [
            "custom/audio"       # Always visible (group leader)
            "pulseaudio#source"
            "backlight"
          ];
        };

        "group/connectivity" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            hide-delay = 10000; # Drawer stays open 10s after the pointer leaves (upstream since 0.15)
            children-class = "drawer-child";
            transition-left-to-right = false;
          };
          modules = [
            "network"            # Always visible (group leader)
            "custom/vpn"
            "bluetooth"
          ];
        };

        "group/hardware" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            hide-delay = 10000; # Drawer stays open 10s after the pointer leaves (upstream since 0.15)
            children-class = "drawer-child";
            transition-left-to-right = true;
          };
          modules = [
            "cpu"               # Always visible (group leader)
            "memory"
            "temperature"
            "temperature#gpu"
            "disk"
          ];
        };

        "group/tools" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            hide-delay = 10000; # Drawer stays open 10s after the pointer leaves (upstream since 0.15)
            children-class = "drawer-child";
            transition-left-to-right = false;
          };
          modules = [
            "custom/nix-updates"       # Always visible (group leader)
            "custom/mako"
            "hyprland/language"
            "idle_inhibitor"
            "gamemode"
            "custom/gamemode-toggle"
            "custom/monitor-rotation"
          ];
        };

        "hyprland/workspaces" = {
          format = "{name} {windows}";  # Workspace number + app icons
          format-window-separator = " ";
          window-rewrite-default = "";  # Unknown apps: no icon
          window-rewrite = {
            "class<brave-browser>" = "󰖟";
            "class<com.mitchellh.ghostty>" = "";
            "class<Alacritty>" = "";
            "class<code-url-handler>" = "󰨞";
            "class<Code>" = "󰨞";
            "class<nemo>" = "";
            "class<spotify>" = "";
            "class<vlc>" = "󰕼";
            "class<vesktop>" = "󰙯";
            "class<Ferdium>" = "";
            "class<ferdium>" = "";
            "class<telegram-desktop>" = "";
            "class<org.keepassxc.KeePassXC>" = "󰌾";
            "class<obsidian>" = "󰠗";
            "class<blender>" = "󰂫";
            "title<.*YouTube.*>" = "";
            "title<.*GitHub.*>" = "";
          };
          sort-by-number = true;
          all-outputs = true;
          show-special = true;  # Show special workspaces (scratchpad, minimized)

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
          icon = true;          # Show app icon next to title
          icon-size = 16;
          rewrite = {
            "(.*) - Brave" = "$1";         # Strip " - Brave" suffix
            "(.*) - Visual Studio Code" = "󰨞 $1";
            "(.*) - Ghostty" = " $1";
          };
        };

        "clock" = {
          format = " {:%H:%M  %a %e}";
          format-alt = " {:%H:%M:%S %Z  %A, %e %B %Y}";
          timezones = [ "Europe/Lisbon" "America/New_York" "Asia/Tokyo" "Etc/UTC" ];
          # tz_list removed: it printed unlabeled times; the labeled world
          # clocks live in the weather tooltip. Scroll still cycles timezones.
          tooltip-format = "<span color='${theme.colors.accent}'><b>󰃭  CALENDAR</b></span>\n\n<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<b>{}</b>";
              days = "{}";
              weeks = "<b>W{}</b>";
              weekdays = "<b>{}</b>";
              today = "<span color='${theme.colors.accent}'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "tz_up";      # Scroll cycles through timezones
            on-scroll-down = "tz_down";
          };
        };

        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          design-capacity = false;  # Use current full charge, not original design capacity
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-full = "󰁹 Full";
          format-alt = "{icon} {time} ({power:.1f}W)";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          tooltip-format = "{timeTo}\nPower: {power:.1f}W\nHealth: {health}%\nCycles: {cycles}";
          on-click = "battery-mode";  # Cycle charge mode (Conservation → Balanced → Full)
        };

        "bluetooth" = {
          format = " {status}";
          format-connected = " {device_alias}";
          format-connected-battery = " {device_alias} {device_battery_percentage}%";
          format-disabled = "";
          format-off = "󰂲";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
          on-click-right = "${bluetoothToggle}";  # Toggle BT power
        };

        "network" = {
          interface-types = [ "wifi" "ethernet" "bridge" "wireguard" "tun" ];
          format = "󰌘 {ifname}";
          format-wifi = "{icon} {signalStrength}%";
          format-ethernet = "󰈀 {bandwidthDownBytes}";
          format-linked = "󰌘 {ifname}";
          format-disconnected = "󰖪";
          format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];  # Signal strength tiers (low → high)
          tooltip-format = "{ifname}\nIP: {ipaddr}\nGateway: {gwaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-wifi = "WiFi: {essid} ({signalStrength}%)\nFreq: {frequency}GHz\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-ethernet = "Ethernet: {ifname}\nIP: {ipaddr}\n⇣ {bandwidthDownBytes}  ⇡ {bandwidthUpBytes}";
          tooltip-format-linked = "{ifname} (No IP)\nGateway: {gwaddr}";
          tooltip-format-disconnected = "No network connection";
          on-click = "nm-connection-editor";
          on-click-right = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.networkmanager}/bin/nmtui";  # Quick TUI network manager
          interval = 60;
        };

        "custom/audio" = {
          exec = "$HOME/.config/waybar/scripts/audio-status.sh";
          return-type = "json";
          interval = 60;  # Slow poll; clicks, scrolls and XF86 volume keys all send RTMIN+10
          signal = 10;
          on-click = "$HOME/.config/waybar/scripts/audio-switch.sh";
          on-click-right = "swayosd-client --output-volume mute-toggle && pkill -RTMIN+10 waybar";
          on-click-middle = "hyprpwcenter";
          on-scroll-up = "swayosd-client --output-volume=+2 && pkill -RTMIN+10 waybar";
          on-scroll-down = "swayosd-client --output-volume=-2 && pkill -RTMIN+10 waybar";
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
          paths = [ "/" ];
          tooltip-format = "Disk: {used} / {total}\nFree: {free} ({percentage_free}%)";
          on-click = "nemo /";
          on-click-right = "ghostty -e dust /";  # Visual disk usage
        };

        "cpu" = {
          format = "󰻠 {usage}%";
          tooltip-format = "CPU Usage: {usage}%\nLoad: {load}";
          on-click = "ghostty -e btop";
          interval = 10;
        };

        "memory" = {
          format = "󰍛 {percentage}%";
          tooltip-format = "RAM: {used:0.1f}GB / {total:0.1f}GB\nAvailable: {avail:0.1f}GB\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB";
          on-click = "ghostty -e btop";
          interval = 10;
        };

        "temperature" = {
          # Use PCI device path (stable across reboots, hwmon# indices are NOT stable)
          hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
          input-filename = "temp1_input";  # k10temp Tctl
          critical-threshold = 90;
          format = " {temperatureC}°C";
          tooltip-format = "CPU: {temperatureC}°C (k10temp Tctl)";
          on-click = "ghostty -e btop";
        };

        "temperature#gpu" = {
          # Use PCI device path (stable across reboots)
          hwmon-path-abs = "/sys/devices/pci0000:00/0000:00:08.1/0000:c4:00.0/hwmon";
          input-filename = "temp1_input";  # amdgpu edge
          critical-threshold = 90;
          format = "󰢮 {temperatureC}°C";
          tooltip-format = "GPU: {temperatureC}°C (Radeon 780M)";
          on-click = "ghostty -e btop";
        };

        "backlight" = {
          device = "amdgpu_bl1";  # AMD Radeon 780M backlight
          format = "{icon} {percent}%";
          format-icons = [ "󰃞" "󰃟" "󰃠" "󱩎" "󱩏" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󰛨" ];
          tooltip-format = "Brightness: {percent}%\nScroll: adjust | Right: reset 50%\n(syncs both screens)";
          on-scroll-up = "$HOME/.config/waybar/scripts/brightness-sync.sh 5%+";
          on-scroll-down = "$HOME/.config/waybar/scripts/brightness-sync.sh 5%-";
          on-click-right = "$HOME/.config/waybar/scripts/brightness-sync.sh 50%";  # Reset to 50%
        };

        "custom/weather" = {
          exec = "${pkgs.python313}/bin/python3 $HOME/.config/waybar/scripts/weather.py";
          return-type = "json";
          interval = 600;  # Update every 10 minutes (600 seconds) - cached
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://open-meteo.com";
          signal = 4;  # Use SIGRTMIN+4 for manual refresh
          on-scroll-up = "rm -f $HOME/.cache/weather-waybar.json; pkill -RTMIN+4 waybar";  # Force refresh on scroll (drop cache first)
          on-scroll-down = "rm -f $HOME/.cache/weather-waybar.json; pkill -RTMIN+4 waybar";  # Force refresh on scroll (drop cache first)
        };

        "custom/polymarket" = {
          exec = "${pkgs.python313}/bin/python3 $HOME/.config/waybar/scripts/polymarket.py";
          return-type = "json";
          interval = 600;  # Update every 10 minutes - cached
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://polymarket.com";
          signal = 2;  # Use SIGRTMIN+2 for manual refresh
          on-scroll-up = "rm -f $HOME/.cache/polymarket-waybar.json; pkill -RTMIN+2 waybar";  # Force refresh on scroll (drop cache first)
          on-scroll-down = "rm -f $HOME/.cache/polymarket-waybar.json; pkill -RTMIN+2 waybar";  # Force refresh on scroll (drop cache first)
        };

        "custom/bitcoin" = {
          exec = "$HOME/.config/waybar/scripts/bitcoin.sh";
          return-type = "json";
          interval = 600;  # Update every 10 minutes
          format = "₿ {}";
          tooltip = true;
          on-click = "${pkgs.xdg-utils}/bin/xdg-open https://mempool.space/";
          signal = 1;  # Use SIGRTMIN+1 for manual refresh
          on-scroll-up = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
          on-scroll-down = "pkill -RTMIN+1 waybar";  # Force refresh on scroll
        };

        "custom/wallets" = {
          exec = "${walletPython}/bin/python3 $HOME/.config/waybar/scripts/wallets.py";
          return-type = "json";
          interval = 600;  # Update every 10 minutes - updates price only, balances cached
          format = "{}";  # Shows balance - blurred by CSS, clear on hover
          tooltip = true;
          signal = 3;  # Use SIGRTMIN+3 for manual refresh
          on-scroll-up = "pkill -RTMIN+3 waybar";  # Force price refresh (EUR/USD only, balances stay cached)
          on-scroll-down = "pkill -RTMIN+3 waybar";  # Force price refresh (EUR/USD only, balances stay cached)
        };

        # System Monitoring Modules
        "custom/vpn" = {
          exec = "$HOME/.config/waybar/scripts/vpn-status.sh";
          return-type = "json";
          interval = 60;  # VPN-DNS-SWITCH sends RTMIN+8 on connect/disconnect
          format = "{}";
          tooltip = true;
          on-click = "$HOME/.config/waybar/scripts/vpn-selector.sh";   # Wofi country picker
          on-click-right = "vpn off";                               # Quick disconnect
          on-click-middle = "vpn status";                           # Show status notification
          signal = 8;
        };

        "custom/nix-updates" = {
          exec = "$HOME/.config/waybar/scripts/nix-updates.sh";
          return-type = "json";
          interval = 3600;
          format = "{}";
          tooltip = true;
          on-click = "$HOME/.config/waybar/scripts/nix-quick-update.sh";  # Background update + notification
          signal = 5;
          on-scroll-up = "pkill -RTMIN+5 waybar";    # Force cache check
          on-scroll-down = "pkill -RTMIN+5 waybar";  # Force cache check
        };

        "custom/voice" = {
          exec = "${voiceStatus}";
          return-type = "json";
          interval = "once";  # Event-driven: voice-terminal sends RTMIN+6 on state change
          format = "{}";
          tooltip = true;
          signal = 6;
          on-click = "voice-terminal";  # Toggle recording from the bar
        };

        "custom/theme" = {
          exec = "${themeStatus}";
          return-type = "json";
          # No poll: toggles send RTMIN+9 and theme-switch reloads waybar (SIGUSR2)
          interval = "once";
          format = "{}";
          tooltip = true;
          on-click = "${themeToggle}";
          on-click-right = "${themeAuto}";
          on-scroll-up = "${themeDay}";
          on-scroll-down = "${themeNight}";
          signal = 9;
        };

        # ── Built-in modules (no scripts needed) ──

        "systemd-failed-units" = {
          format = "  {nr_failed}";
          format-ok = "";  # Hidden when no failures
          system = true;
          user = true;
          hide-on-ok = true;
          on-click = "ghostty --wait-after-command -e systemctl --failed";
        };

        "privacy" = {
          icon-spacing = 4;
          icon-size = 16;
          transition-duration = 250;
          modules = [
            { type = "screenshare"; }
            { type = "audio-in"; }
          ];
        };

        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
          tooltip-format-activated = "Idle inhibitor: ON (no auto-lock)";
          tooltip-format-deactivated = "Idle inhibitor: off";
        };

        "mpris" = {
          format = "{status_icon} {dynamic}";
          format-paused = "{status_icon} {dynamic}";
          format-stopped = "";
          dynamic-len = 30;
          dynamic-order = [ "title" "artist" ];
          dynamic-separator = " — ";
          status-icons = {
            playing = "▶";
            paused = "";
            stopped = "";
          };
          player-icons = {
            spotify = "";
            vlc = "󰕼";
            default = "🎵";
          };
          tooltip-format = "{player}\n{position}/{length}\n\nLeft-click: dock/undock YouTube/Twitch PiP";
          on-click = "pip-dock-toggle"; # Left-click: attach/detach the on-screen PiP (YouTube or Twitch)
          on-click-right = "${pkgs.playerctl}/bin/playerctl play-pause";      # Right-click: play/pause
          on-click-middle = "${pkgs.playerctl}/bin/playerctl next";           # Middle-click: next track
        };

        "gamemode" = {
          format = "{glyph}";
          glyph = "󰊗";
          hide-not-running = true;
          tooltip-format = "GameMode active ({count} games)";
        };

        # GameMode manual toggle (click to start/stop)
        "custom/gamemode-toggle" = {
          exec = "${gamemodeStatus}";
          return-type = "json";
          interval = 300;  # Safety net for stale PID file; toggle sends RTMIN+11
          signal = 11;
          on-click = "${gamemodeToggle}";
        };

        # Keyboard layout indicator (built-in hyprland module)
        "hyprland/language" = {
          format = "{}";
          format-fr = "FR";
          format-en = "US";
          on-click = "hyprctl switchxkblayout all next";
          tooltip-format = "Keyboard: {long}";
        };

        "custom/mako" = {
          exec = "$HOME/.config/waybar/scripts/mako.sh";
          return-type = "json";
          interval = 60;
          format = "{}";
          tooltip = true;
          on-click = "${pkgs.mako}/bin/makoctl invoke";
          on-click-right = "${pkgs.mako}/bin/makoctl dismiss --all";
        };

        "custom/removable-disks" = {
          exec = "$HOME/.config/waybar/scripts/removable-disks.sh";
          return-type = "json";
          interval = 60;
          format = "{}";
          tooltip = true;
          on-click = "nemo";
          on-click-right = "${ejectUsb}";
        };

        "custom/sep" = {
          format = "│";
          tooltip = false;
        };

        "custom/monitor-rotation" = {
          format = "󰹑";
          tooltip-format = "Monitor settings";
          on-click = "ghostty -e hyprmon";           # TUI native (Hyprland)
          on-click-right = "nwg-displays";            # GUI fallback
        };

        # ── Power drawer (lock visible, shutdown/reboot in drawer) ──
        "group/power" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 300;
            children-class = "power-child";
            transition-left-to-right = false;  # Opens left (towards bar center)
          };
          modules = [
            "custom/lock"       # Always visible (group leader)
            "custom/shutdown"   # Hidden in drawer
            "custom/reboot"
          ];
        };

        "custom/lock" = {
          format = "󰌾";
          tooltip-format = "Lock screen";
          on-click = "hyprlock";
        };

        "custom/shutdown" = {
          format = "󰐥";
          tooltip-format = "Shutdown (hyprshutdown confirmation)";
          on-click = "${poweroffWithConfirm}";
        };

        "custom/reboot" = {
          format = "󰜉";
          tooltip-format = "Reboot (hyprshutdown confirmation)";
          on-click = "${rebootWithConfirm}";
        };

        "tray" = {
          spacing = 10;
          icon-size = 18;
        };
      };
    };

    style = ''
      /* Minimal bar with subtle visual hierarchy — themed via config.theme */
      @import url("${config.home.homeDirectory}/.config/theme/current/waybar.css");

      * {
        border: none;
        border-radius: 0;
        font-family: "${theme.fonts.mono}", monospace;
        font-size: 13px;
        min-height: 0;
        font-feature-settings: "tnum";
        transition-property: color, background, opacity, border-color, text-shadow;
        transition-duration: 200ms;
        transition-timing-function: ease-out;
      }

      window#waybar {
        background: alpha(@bg, 0.96);
        color: @fg;
        border-bottom: 1px solid alpha(@border_color, 0.35);
        box-shadow: inset 0 -1px alpha(@accent, 0.08);
      }

      /* ── Workspaces ── */
      #workspaces { margin: 0 5px 0 4px; }
      #workspaces button {
        min-width: 20px;
        padding: 0 7px;
        margin: 0 1px;
        color: @muted;
        background: transparent;
        border-bottom: 2px solid transparent;
      }
      #workspaces button.active {
        color: @accent;
        border-bottom: 2px solid @accent;
        background: alpha(@accent, 0.10);
        text-shadow: 0 0 6px alpha(@accent, 0.28);
      }
      #workspaces button.urgent {
        color: @red;
        border-bottom: 2px solid @red;
        background: alpha(@red, 0.10);
        animation: pulse 1.5s ease-in-out infinite alternate;
      }
      #workspaces button.empty { color: @muted; opacity: 0.28; }
      #workspaces button.special {
        color: @accent_secondary;
        border-bottom: 2px solid @accent_secondary;
      }
      #workspaces button:hover {
        color: @fg;
        background: alpha(@fg, 0.06);
      }

      @keyframes pulse {
        from { opacity: 0.6; }
        to { opacity: 1.0; }
      }

      /* ── Window title ── */
      #window {
        margin: 0 8px;
        color: @muted;
        font-size: 12px;
      }
      window#waybar.empty #window { opacity: 0.3; }

      /* ── Submap (active mode indicator) ── */
      #submap {
        padding: 0 10px;
        color: @bg;
        background: @accent;
        font-weight: bold;
      }

      /* ── Clock (tabular numbers prevent width jitter) ── */
      #clock {
        padding: 0 10px;
        color: @fg;
        font-weight: bold;
        min-width: 98px;
      }

      /* ── All modules — text-first, subtle state accents ── */
      #custom-bitcoin, #custom-wallets, #custom-vpn, #custom-nix-updates,
      #custom-mako, #custom-monitor-rotation, #custom-theme,
      #custom-weather, #custom-polymarket, #custom-removable-disks,
      #custom-audio, #pulseaudio.source, #bluetooth, #network, #disk, #cpu, #memory,
      #temperature, #temperature.gpu, #backlight, #battery, #tray,
      #systemd-failed-units, #privacy, #idle_inhibitor, #mpris,
      #gamemode,
      #custom-gamemode-toggle, #language,
      #custom-lock, #custom-shutdown, #custom-reboot {
        padding: 0 6px;
        margin: 0 1px;
        background: transparent;
        color: @dim;
        border-radius: 4px;
        border-bottom: 2px solid transparent;
      }

      /* ── Separator ── */
      #custom-sep {
        color: @muted;
        opacity: 0.32;
        padding: 0 1px;
        font-size: 11px;
      }

      /* ── Drawer children (collapsed modules) ── */
      .drawer-child {
        color: @muted;
        opacity: 0.78;
      }
      .drawer-child:hover {
        color: @fg;
        opacity: 1;
      }

      /* ── Finance ── */
      #custom-bitcoin {
        color: @accent;
        font-weight: bold;
        text-shadow: 0 0 8px alpha(@accent, 0.18);
      }
      #custom-wallets {
        color: transparent;
        opacity: 0.78;
        text-shadow: 0 0 6px @dim;
      }
      #custom-wallets:hover {
        color: @fg;
        opacity: 1;
        text-shadow: none;
      }
      #custom-polymarket { color: @magenta; }

      /* ── Weather ── */
      #custom-weather.weather { color: @cyan; }
      #custom-weather.weather-error {
        color: @red;
        font-weight: bold;
      }

      /* ── Privacy (mic/screenshare indicators) ── */
      #privacy {
        color: @red;
        animation: pulse 1s ease-in-out infinite alternate;
      }

      /* ── Idle inhibitor ── */
      #idle_inhibitor.activated {
        color: @accent;
        background: alpha(@accent, 0.08);
        border-bottom-color: @accent;
      }
      #idle_inhibitor.deactivated { opacity: 0.35; }

      /* ── Theme switch ── */
      #custom-theme {
        color: @accent;
        background: alpha(@accent, 0.08);
        border-bottom-color: alpha(@accent, 0.55);
        min-width: 22px;
      }
      #custom-theme.light {
        color: @orange;
        background: alpha(@orange, 0.10);
        border-bottom-color: alpha(@orange, 0.55);
      }
      #custom-theme.dark {
        color: @accent_secondary;
        background: alpha(@accent_secondary, 0.10);
        border-bottom-color: alpha(@accent_secondary, 0.55);
      }

      /* ── Media (MPRIS) ── */
      #mpris {
        color: @muted;
        padding: 0 12px;
      }
      #mpris.playing {
        color: @green;
        border-bottom-color: alpha(@green, 0.65);
      }
      #mpris.paused { color: @dim; opacity: 0.6; }

      /* ── GameMode ── */
      #gamemode {
        color: @accent;
        border-bottom-color: alpha(@accent, 0.65);
      }
      #custom-gamemode-toggle.active {
        color: @accent;
        background: alpha(@accent, 0.08);
      }
      #custom-gamemode-toggle.inactive { color: @dim; opacity: 0.4; }

      /* ── Keyboard layout ── */
      #language { color: @dim; }
      #language:hover { color: @fg; }

      /* ── Battery states ── */
      #battery { min-width: 58px; }
      #battery.charging {
        color: @green;
        border-bottom-color: alpha(@green, 0.7);
      }
      #battery.full { color: @dim; opacity: 0.5; }
      #battery.warning:not(.charging) {
        color: @orange;
        background: alpha(@orange, 0.08);
        border-bottom-color: @orange;
      }
      #battery.critical:not(.charging) {
        color: @red;
        font-weight: bold;
        background: alpha(@red, 0.10);
        border-bottom-color: @red;
        animation: blink 1s steps(6) infinite alternate;
      }
      @keyframes blink {
        to { color: @fg; }
      }

      /* ── Audio ── */
      #custom-audio { min-width: 52px; }
      #pulseaudio.source { min-width: 44px; }
      #custom-audio.muted { opacity: 0.3; }
      #custom-audio.hdmi { color: @cyan; }
      #custom-audio.speakers { color: @fg; }
      #pulseaudio.source.muted { opacity: 0.3; }

      /* ── Glanceable numeric modules ── */
      #cpu, #memory { min-width: 48px; }
      #temperature, #temperature.gpu { min-width: 42px; }
      #backlight { min-width: 58px; }

      /* ── Connectivity ── */
      #bluetooth.connected { color: @blue; }
      #bluetooth.off, #bluetooth.disabled { opacity: 0.3; }
      #network { min-width: 54px; }
      #network.disconnected {
        color: @red;
        border-bottom-color: @red;
      }
      #network.wifi { color: @dim; }

      /* ── Removable media ── */
      #custom-removable-disks.empty { opacity: 0.35; }
      #custom-removable-disks.attached {
        color: @green;
        border-bottom-color: alpha(@green, 0.65);
      }

      /* ── Temperature ── */
      #temperature.critical,
      #temperature.gpu.critical {
        color: @red;
        font-weight: bold;
        background: alpha(@red, 0.08);
        border-bottom-color: @red;
      }

      /* ── Voice dictation ── */
      #custom-voice.recording {
        color: @red;
        font-weight: bold;
        background: alpha(@red, 0.10);
        border-bottom-color: @red;
        animation: blink 1s steps(6) infinite alternate;
      }
      #custom-voice.transcribing { color: @cyan; }
      #custom-voice.downloading { color: @blue; }

      /* ── VPN ── */
      #custom-vpn.connected {
        color: @green;
        border-bottom-color: alpha(@green, 0.65);
      }
      #custom-vpn.disconnected { color: @dim; opacity: 0.4; }

      /* ── Alerts ── */
      #custom-nix-updates.ok { opacity: 0.55; }
      #custom-nix-updates.updates {
        color: @accent;
        background: alpha(@accent, 0.08);
        border-bottom-color: @accent;
      }
      #systemd-failed-units.degraded {
        color: @red;
        font-weight: bold;
        background: alpha(@red, 0.10);
        border-bottom-color: @red;
      }
      #custom-mako.notification {
        color: @fg;
        border-bottom-color: alpha(@accent, 0.65);
      }

      /* ── Power ── */
      #custom-lock:hover {
        color: @accent;
        background: alpha(@accent, 0.1);
        border-bottom-color: @accent;
      }
      #custom-shutdown:hover {
        color: @red;
        background: alpha(@red, 0.1);
        border-bottom-color: @red;
      }
      #custom-reboot:hover {
        color: @accent;
        background: alpha(@accent, 0.1);
        border-bottom-color: @accent;
      }
      .power-child { color: @dim; }

      /* ── Hover (brighten interactive modules) ── */
      #custom-bitcoin:hover, #custom-wallets:hover, #custom-vpn:hover, #custom-audio:hover,
      #network:hover, #bluetooth:hover, #battery:hover, #clock:hover,
      #cpu:hover, #memory:hover, #temperature:hover, #backlight:hover,
      #idle_inhibitor:hover, #mpris:hover,
      #gamemode:hover,
      #custom-weather:hover, #custom-polymarket:hover,
      #custom-nix-updates:hover, #custom-removable-disks:hover,
      #custom-mako:hover, #custom-monitor-rotation:hover, #custom-theme:hover,
      #custom-gamemode-toggle:hover, #language:hover {
        color: @fg;
        background: alpha(@fg, 0.055);
      }

      /* ── Tooltip ── */
      tooltip {
        background: alpha(@surface, 0.98);
        border: 1px solid alpha(@border_color, 0.70);
        border-radius: 5px;
        color: @fg;
        padding: 6px 10px;
        box-shadow: 0 6px 18px alpha(@border_color, 0.18);
      }
      tooltip label {
        color: @fg;
        font-family: "${theme.fonts.mono}", monospace;
        font-size: 12px;
        text-shadow: none;
      }
    '';
  };

  # Waybar script/runtime dependencies.
  # Keep these here so the systemd-launched bar has the same tools as an
  # interactive shell.
  # - btop: in btop.nix (themed)
  # - blueman: in home.nix
  # - hyprpwcenter: in system/sound.nix (replaced pavucontrol)
  home.packages = with pkgs; [
    networkmanagerapplet    # Network manager tray applet
    alsa-utils              # amixer for audio output detection/toggling
    bc
    binutils                # strings for Bitcoin block coinbase decoding
    bluez                   # bluetoothctl for right-click BT toggle
    brightnessctl
    coreutils
    curl
    ddcutil
    gawk
    gnugrep
    gnused
    iproute2
    iputils
    jq
    libnotify
    mako
    networkmanager
    procps
    udisks2
    unixtools.xxd           # xxd for Bitcoin coinbase pool decoding (bitcoin.sh)
    util-linux              # lsblk + flock
    wireplumber             # wpctl
    wofi
    xdg-utils
  ];
}
