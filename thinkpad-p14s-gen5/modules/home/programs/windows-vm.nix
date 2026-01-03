# Windows 11 VM via Docker with RDP integration
# Based on dockurr/windows Docker image
{ pkgs, ... }:

let
  windows-vm = pkgs.writeShellScriptBin "windows-vm" ''
    #!/usr/bin/env bash

    COMPOSE_FILE="$HOME/.config/windows-vm/docker-compose.yml"

    check_prerequisites() {
      local DISK_SIZE_GB=''${1:-64}
      local REQUIRED_SPACE=$((DISK_SIZE_GB + 10))

      if [ ! -e /dev/kvm ]; then
        ${pkgs.gum}/bin/gum style \
          --border normal \
          --padding "1 2" \
          --margin "1" \
          "❌ KVM virtualization not available!" \
          "" \
          "Please enable virtualization in BIOS or check KVM module:" \
          "  lsmod | grep kvm"
        exit 1
      fi

      AVAILABLE_SPACE=$(df "$HOME" | awk 'NR==2 {print int($4/1024/1024)}')
      if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
        echo "❌ Insufficient disk space!"
        echo "   Available: ''${AVAILABLE_SPACE}GB"
        echo "   Required: ''${REQUIRED_SPACE}GB (''${DISK_SIZE_GB}GB disk + 10GB for Windows image)"
        exit 1
      fi
    }

    install_windows() {
      trap "echo ''''; echo 'Installation cancelled by user'; exit 1" INT

      check_prerequisites

      mkdir -p "$HOME/.windows-vm"
      mkdir -p "$HOME/.config/windows-vm"
      mkdir -p "$HOME/Windows"

      TOTAL_RAM=$(${pkgs.procps}/bin/free -h | awk 'NR==2 {print $2}')
      TOTAL_RAM_GB=$(awk 'NR==1 {printf "%d", $2/1024/1024}' /proc/meminfo)
      TOTAL_CORES=$(${pkgs.coreutils}/bin/nproc)

      echo ""
      echo "System Resources Detected:"
      echo "  Total RAM: $TOTAL_RAM"
      echo "  Total CPU Cores: $TOTAL_CORES"
      echo ""

      RAM_OPTIONS=""
      for size in 2 4 8 16 32 64; do
        if [ $size -le $TOTAL_RAM_GB ]; then
          RAM_OPTIONS="$RAM_OPTIONS ''${size}G"
        fi
      done

      SELECTED_RAM=$(echo $RAM_OPTIONS | tr ' ' '\n' | ${pkgs.gum}/bin/gum choose --selected="8G" --header="How much RAM for Windows VM?")

      if [ -z "$SELECTED_RAM" ]; then
        echo "Installation cancelled"
        exit 1
      fi

      SELECTED_CORES=$(${pkgs.gum}/bin/gum input --placeholder="CPU cores (1-$TOTAL_CORES)" --value="4" --header="How many CPU cores?" --char-limit=2)

      if [ -z "$SELECTED_CORES" ]; then
        echo "Installation cancelled"
        exit 1
      fi

      if ! [[ "$SELECTED_CORES" =~ ^[0-9]+$ ]] || [ "$SELECTED_CORES" -lt 1 ] || [ "$SELECTED_CORES" -gt "$TOTAL_CORES" ]; then
        echo "Invalid input. Using default: 4 cores"
        SELECTED_CORES=4
      fi

      AVAILABLE_SPACE=$(df "$HOME" | awk 'NR==2 {print int($4/1024/1024)}')
      MAX_DISK_GB=$((AVAILABLE_SPACE - 10))

      if [ $MAX_DISK_GB -lt 32 ]; then
        echo "❌ Insufficient disk space!"
        echo "   Available: ''${AVAILABLE_SPACE}GB"
        echo "   Minimum required: 42GB (32GB disk + 10GB image)"
        exit 1
      fi

      DISK_OPTIONS=""
      for size in 32 64 128 256 512; do
        if [ $size -le $MAX_DISK_GB ]; then
          DISK_OPTIONS="$DISK_OPTIONS ''${size}G"
        fi
      done

      DEFAULT_DISK="64G"
      if ! echo "$DISK_OPTIONS" | grep -q "64G"; then
        DEFAULT_DISK="32G"
      fi

      SELECTED_DISK=$(echo $DISK_OPTIONS | tr ' ' '\n' | ${pkgs.gum}/bin/gum choose --selected="$DEFAULT_DISK" --header="Disk space for Windows? (64GB+ recommended)")

      if [ -z "$SELECTED_DISK" ]; then
        echo "Installation cancelled"
        exit 1
      fi

      DISK_SIZE_NUM=$(echo "$SELECTED_DISK" | sed 's/G//')
      check_prerequisites "$DISK_SIZE_NUM"

      USERNAME=$(${pkgs.gum}/bin/gum input --placeholder="Username (default: docker)" --header="Windows username:")
      if [ -z "$USERNAME" ]; then
        USERNAME="docker"
      fi

      PASSWORD=$(${pkgs.gum}/bin/gum input --placeholder="Password (default: admin)" --password --header="Windows password:")
      if [ -z "$PASSWORD" ]; then
        PASSWORD="admin"
        PASSWORD_DISPLAY="(default)"
      else
        PASSWORD_DISPLAY="(custom)"
      fi

      ${pkgs.gum}/bin/gum style \
        --border normal \
        --padding "1 2" \
        --margin "1" \
        --align left \
        --bold \
        "Windows VM Configuration" \
        "" \
        "RAM:       $SELECTED_RAM" \
        "CPU:       $SELECTED_CORES cores" \
        "Disk:      $SELECTED_DISK" \
        "Username:  $USERNAME" \
        "Password:  $PASSWORD_DISPLAY"

      echo ""
      if ! ${pkgs.gum}/bin/gum confirm "Proceed with installation?"; then
        echo "Installation cancelled"
        exit 1
      fi

      cat << EOF | tee "$COMPOSE_FILE" > /dev/null
    services:
      windows:
        image: dockurr/windows
        container_name: windows-vm
        environment:
          VERSION: "11"
          RAM_SIZE: "$SELECTED_RAM"
          CPU_CORES: "$SELECTED_CORES"
          DISK_SIZE: "$SELECTED_DISK"
          USERNAME: "$USERNAME"
          PASSWORD: "$PASSWORD"
        devices:
          - /dev/kvm
          - /dev/net/tun
        cap_add:
          - NET_ADMIN
        ports:
          - 8006:8006
          - 3389:3389/tcp
          - 3389:3389/udp
        volumes:
          - $HOME/.windows-vm:/storage
          - $HOME/Windows:/shared
        restart: unless-stopped
        stop_grace_period: 2m
    EOF

      echo ""
      echo "Starting Windows VM installation..."
      echo "Downloading Windows 11 image (10-15 minutes)..."
      echo ""
      echo "Monitor progress: http://127.0.0.1:8006"
      echo ""

      if ! ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" up -d 2>&1; then
        echo "❌ Failed to start Windows VM!"
        echo "   Check Docker: systemctl --user status docker"
        exit 1
      fi

      echo ""
      echo "✅ Windows VM is installing in background!"
      echo ""
      echo "Monitor: http://127.0.0.1:8006"
      echo "Launch when ready: windows-vm launch"
      echo ""
      echo "Shared folder: ~/Windows/ (accessible from Windows)"
      echo ""
      echo "Commands:"
      echo "  windows-vm launch    - Connect via RDP"
      echo "  windows-vm stop      - Shutdown VM"
      echo "  windows-vm status    - Check status"
      echo ""

      sleep 3
      ${pkgs.xdg-utils}/bin/xdg-open "http://127.0.0.1:8006" 2>/dev/null || true
    }

    remove_windows() {
      echo "Removing Windows VM..."

      ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true
      ${pkgs.docker}/bin/docker rmi dockurr/windows 2>/dev/null || echo "Image already removed"

      rm -rf "$HOME/.config/windows-vm"
      rm -rf "$HOME/.windows-vm"

      echo ""
      echo "✅ Windows VM removed!"
      echo ""
      echo "Shared folder ~/Windows/ preserved (delete manually if needed)"
    }

    launch_windows() {
      KEEP_ALIVE=false
      if [ "$1" = "--keep-alive" ] || [ "$1" = "-k" ]; then
        KEEP_ALIVE=true
      fi

      if [ ! -f "$COMPOSE_FILE" ]; then
        echo "Windows VM not configured. Run: windows-vm install"
        exit 1
      fi

      CONTAINER_STATUS=$(${pkgs.docker}/bin/docker inspect --format='{{.State.Status}}' windows-vm 2>/dev/null)

      if [ "$CONTAINER_STATUS" != "running" ]; then
        echo "Starting Windows VM..."
        ${pkgs.libnotify}/bin/notify-send "Windows VM" "Starting... (15-30 seconds)" -t 15000

        if ! ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" up -d 2>&1; then
          echo "❌ Failed to start!"
          ${pkgs.libnotify}/bin/notify-send -u critical "Windows VM" "Failed to start"
          exit 1
        fi

        echo "Waiting for RDP..."
        WAIT_COUNT=0
        while ! ${pkgs.netcat}/bin/nc -z 127.0.0.1 3389 2>/dev/null; do
          sleep 2
          WAIT_COUNT=$((WAIT_COUNT + 1))
          if [ $WAIT_COUNT -gt 60 ]; then
            echo "❌ Timeout! VM might still be installing."
            echo "   Check: http://127.0.0.1:8006"
            exit 1
          fi
        done

        sleep 5
      fi

      WIN_USER=$(grep "USERNAME:" "$COMPOSE_FILE" | sed 's/.*USERNAME: "\(.*\)"/\1/')
      WIN_PASS=$(grep "PASSWORD:" "$COMPOSE_FILE" | sed 's/.*PASSWORD: "\(.*\)"/\1/')

      [ -z "$WIN_USER" ] && WIN_USER="docker"
      [ -z "$WIN_PASS" ] && WIN_PASS="admin"

      if [ "$KEEP_ALIVE" = true ]; then
        LIFECYCLE="VM keeps running after disconnect"
      else
        LIFECYCLE="VM auto-stops on disconnect"
      fi

      ${pkgs.gum}/bin/gum style \
        --border normal \
        --padding "1 2" \
        --margin "1" \
        --align center \
        "Connecting to Windows VM" \
        "" \
        "$LIFECYCLE"

      # Detect Hyprland scaling
      HYPR_SCALE=$(${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.[0].scale // 1')
      SCALE_PERCENT=$(echo "$HYPR_SCALE" | awk '{print int($1 * 100)}')

      RDP_SCALE=""
      if [ "$SCALE_PERCENT" -ge 170 ]; then
        RDP_SCALE="/scale:180"
      elif [ "$SCALE_PERCENT" -ge 130 ]; then
        RDP_SCALE="/scale:140"
      fi

      ${pkgs.freerdp}/bin/xfreerdp \
        /u:"$WIN_USER" \
        /p:"$WIN_PASS" \
        /v:127.0.0.1:3389 \
        /kbd:layout:0x0000040c \
        /sound \
        /microphone \
        /clipboard \
        /cert:ignore \
        /title:"Windows 11" \
        /dynamic-resolution \
        /gfx:AVC444 \
        /floatbar:sticky:off,default:visible,show:fullscreen \
        $RDP_SCALE

      if [ "$KEEP_ALIVE" = false ]; then
        echo ""
        echo "Stopping Windows VM..."
        ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" down
        echo "✅ Windows VM stopped"
      else
        echo ""
        echo "VM still running. Stop with: windows-vm stop"
      fi
    }

    stop_windows() {
      if [ ! -f "$COMPOSE_FILE" ]; then
        echo "Windows VM not configured"
        exit 1
      fi

      echo "Stopping Windows VM..."
      ${pkgs.docker}/bin/docker compose -f "$COMPOSE_FILE" down
      echo "✅ Stopped"
    }

    status_windows() {
      if [ ! -f "$COMPOSE_FILE" ]; then
        echo "Windows VM not configured"
        echo "To install: windows-vm install"
        exit 1
      fi

      CONTAINER_STATUS=$(${pkgs.docker}/bin/docker inspect --format='{{.State.Status}}' windows-vm 2>/dev/null)

      if [ -z "$CONTAINER_STATUS" ]; then
        echo "Container not found. Start with: windows-vm launch"
      elif [ "$CONTAINER_STATUS" = "running" ]; then
        ${pkgs.gum}/bin/gum style \
          --border normal \
          --padding "1 2" \
          --margin "1" \
          --align left \
          "✅ Windows VM: RUNNING" \
          "" \
          "Web UI:  http://127.0.0.1:8006" \
          "RDP:     localhost:3389" \
          "Shared:  ~/Windows/" \
          "" \
          "Connect: windows-vm launch" \
          "Stop:    windows-vm stop"
      else
        echo "Windows VM stopped (status: $CONTAINER_STATUS)"
        echo "Start with: windows-vm launch"
      fi
    }

    show_usage() {
      cat << EOF
    Windows VM Manager - Docker-based Windows 11 virtualization

    Usage: windows-vm [command] [options]

    Commands:
      install              Install and configure Windows 11 VM
      launch [options]     Start VM and connect via RDP
                           -k, --keep-alive   Keep running after disconnect
      stop                 Shutdown Windows VM
      status               Show VM status
      remove               Remove VM (preserves ~/Windows/ folder)
      help                 Show this help

    Examples:
      windows-vm install           # First-time setup
      windows-vm launch            # Connect (auto-stop on exit)
      windows-vm launch -k         # Connect (keep running)
      windows-vm status            # Check if running

    Files:
      ~/.config/windows-vm/        Configuration
      ~/.windows-vm/               VM storage
      ~/Windows/                   Shared folder (visible in Windows)

    Web UI: http://127.0.0.1:8006
    EOF
    }

    case "$1" in
      install)
        install_windows
        ;;
      remove)
        remove_windows
        ;;
      launch|start)
        launch_windows "$2"
        ;;
      stop|down)
        stop_windows
        ;;
      status)
        status_windows
        ;;
      help|--help|-h|"")
        show_usage
        ;;
      *)
        echo "Unknown command: $1" >&2
        echo "" >&2
        show_usage >&2
        exit 1
        ;;
    esac
  '';
in
{
  # Install Windows VM script
  # Desktop entry is defined in desktop-apps.nix
  home.packages = [ windows-vm ];
}
