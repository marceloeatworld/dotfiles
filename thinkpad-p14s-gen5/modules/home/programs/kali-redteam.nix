# Kali Linux headless container for red team operations
# Uses Podman (rootless) with persistent storage
{ pkgs, ... }:

let
  # Containerfile for Kali with red team tools
  kali-containerfile = pkgs.writeText "Containerfile.kali-redteam" ''
    FROM docker.io/kalilinux/kali-rolling:latest

    ENV DEBIAN_FRONTEND=noninteractive

    # Install headless tools (no GUI)
    RUN apt-get update && apt-get install -y --no-install-recommends \
        kali-linux-headless \
        curl \
        jq \
        python3-pip \
        python3-venv \
        tmux \
        vim \
        git \
        net-tools \
        iputils-ping \
        dnsutils \
        proxychains4 \
        tor \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

    # torsocks for `kali-run --tor`. Own layer so the multi-GB layer above
    # stays cached when the image is rebuilt.
    RUN apt-get update && apt-get install -y --no-install-recommends torsocks \
        && apt-get clean && rm -rf /var/lib/apt/lists/*

    # Point proxychains at the container-local Tor SOCKS (127.0.0.1:9050).
    # Tor runs inside the container, started on demand by `kali-run --px`,
    # `--tor` or `--socks 127.0.0.1:9050`.
    # proxy_dns resolves names through Tor to avoid DNS leaks.
    RUN printf '%s\n' \
        "strict_chain" \
        "proxy_dns" \
        "tcp_read_time_out 15000" \
        "tcp_connect_time_out 8000" \
        "[ProxyList]" \
        "socks5 127.0.0.1 9050" \
        > /etc/proxychains4.conf

    # Create workspace
    RUN mkdir -p /workspace /root/.config /loot /reports

    WORKDIR /workspace
    CMD ["/bin/bash"]
  '';

  # Main kali management command
  kali = pkgs.writeShellScriptBin "kali" ''
    BASE_CONTAINER_NAME="kali-redteam"
    IMAGE_NAME="localhost/kali-redteam:latest"
    DATA_DIR="$HOME/.local/share/kali-redteam"
    PODMAN="${pkgs.podman}/bin/podman"

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    build_image() {
      echo -e "''${CYAN}Building Kali Red Team image...''${NC}"
      echo -e "''${YELLOW}This will download ~2GB on first build''${NC}"
      if ! $PODMAN build -t "$IMAGE_NAME" -f "${kali-containerfile}" .; then
        echo -e "''${RED}Image build failed''${NC}"
        exit 1
      fi
      echo -e "''${GREEN}Image built successfully''${NC}"
    }

    ensure_dirs() {
      mkdir -p "$DATA_DIR/workspace"
      mkdir -p "$DATA_DIR/wordlists"
      mkdir -p "$DATA_DIR/loot"
      mkdir -p "$DATA_DIR/reports"
    }

    container_name() {
      case "$1" in
        safe) echo "$BASE_CONTAINER_NAME-safe" ;;
        net)  echo "$BASE_CONTAINER_NAME-net" ;;
        *)    echo "$BASE_CONTAINER_NAME-safe" ;;
      esac
    }

    mode_label() {
      case "$1" in
        net)  echo "network tools (NET_RAW/NET_ADMIN + host loopback)" ;;
        safe) echo "safe (no extra network capabilities)" ;;
      esac
    }

    ensure_running() {
      MODE="''${1:-safe}"
      CONTAINER_NAME=$(container_name "$MODE")

      if ! $PODMAN image exists "$IMAGE_NAME" 2>/dev/null; then
        echo -e "''${YELLOW}Image not found. Building...''${NC}"
        build_image
      fi

      ensure_dirs

      if $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
        STATE=$($PODMAN inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        [ "$STATE" = "running" ] || $PODMAN start "$CONTAINER_NAME" >/dev/null
        return 0
      fi

      if [ "$MODE" = "net" ]; then
        $PODMAN run -d \
          --name "$CONTAINER_NAME" \
          --hostname kali-redteam-net \
          --network pasta \
          -v "$DATA_DIR/workspace:/workspace:Z" \
          -v "$DATA_DIR/wordlists:/usr/share/wordlists:Z" \
          -v "$DATA_DIR/loot:/loot:Z" \
          -v "$DATA_DIR/reports:/reports:Z" \
          --security-opt=no-new-privileges \
          --cap-add=NET_RAW \
          --cap-add=NET_ADMIN \
          "$IMAGE_NAME" \
          sleep infinity >/dev/null
      else
        $PODMAN run -d \
          --name "$CONTAINER_NAME" \
          --hostname kali-redteam-safe \
          --network pasta \
          -v "$DATA_DIR/workspace:/workspace:Z" \
          -v "$DATA_DIR/wordlists:/usr/share/wordlists:Z" \
          -v "$DATA_DIR/loot:/loot:Z" \
          -v "$DATA_DIR/reports:/reports:Z" \
          --security-opt=no-new-privileges \
          --cap-drop=ALL \
          "$IMAGE_NAME" \
          sleep infinity >/dev/null
      fi
    }

    start() {
      MODE="''${1:-safe}"
      CONTAINER_NAME=$(container_name "$MODE")

      if $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
        STATE=$($PODMAN inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ "$STATE" = "running" ]; then
          echo -e "''${GREEN}Container already running. Attaching...''${NC}"
          exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
        fi
      fi

      echo -e "''${GREEN}Starting Kali Red Team container ($(mode_label "$MODE"))...''${NC}"
      echo -e "  Workspace:  ''${CYAN}$DATA_DIR/workspace''${NC}"
      echo ""

      ensure_running "$MODE"
      exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
    }

    # Start Tor inside the container on first Tor-mode use, wait for bootstrap.
    ensure_tor() {
      CN="$1"
      if $PODMAN exec "$CN" pgrep -x tor >/dev/null 2>&1; then
        return 0
      fi
      echo -e "''${YELLOW}Starting Tor (first run bootstraps circuits, ~20-40s)...''${NC}" >&2
      $PODMAN exec -d "$CN" tor >/dev/null 2>&1
      for _ in $(seq 1 45); do
        if $PODMAN exec "$CN" curl -s --max-time 5 \
            --socks5-hostname 127.0.0.1:9050 \
            https://check.torproject.org/api/ip >/dev/null 2>&1; then
          echo -e "''${GREEN}Tor ready''${NC}" >&2
          return 0
        fi
        sleep 2
      done
      echo -e "''${RED}Tor failed to bootstrap''${NC}" >&2
      return 1
    }

    # Non-interactive exec for headless agents (no TTY), e.g. claude-mac --bare.
    # Usage: kali-run [--net] [--px|--tor|--socks <host:port>|--no-px] <command...>
    #   --net    network-tools container (NET_RAW/NET_ADMIN)
    #   --px     route the command through proxychains4 (Tor SOCKS, TCP connect only)
    #   --tor    route the command through torsocks (Tor SOCKS, TCP only)
    #   --socks  export ALL_PROXY=socks5h://<host:port>, no LD_PRELOAD. Only
    #            proxy-aware tools (curl, git) honor it; anything else, nmap
    #            included, connects DIRECT. Use --px or --tor for those.
    #   --no-px  force direct (clearnet) even when KALI_TOR defaults to Tor
    # KALI_TOR=1 in the env makes --px the default (set by the claude-mac-tor alias).
    run() {
      MODE=safe
      # Tor by default when KALI_TOR is set (claude-mac-tor), otherwise direct.
      if [ -n "''${KALI_TOR:-}" ]; then VIA=px; else VIA=direct; fi
      SOCKS_ADDR=
      while [ "$#" -gt 0 ]; do
        case "$1" in
          --net)   MODE=net; shift ;;
          --px)    VIA=px; shift ;;
          --tor)   VIA=tor; shift ;;
          --socks)
            [ "$#" -ge 2 ] || { echo "--socks needs <host:port>" >&2; exit 2; }
            VIA=socks; SOCKS_ADDR="$2"; shift 2 ;;
          --no-px) VIA=direct; shift ;;
          --)      shift; break ;;
          --*)     echo "Unknown flag: $1" >&2; exit 2 ;;
          *)       break ;;
        esac
      done

      if [ "$#" -eq 0 ]; then
        echo "Usage: kali-run [--net] [--px|--tor|--socks <host:port>] <command...>" >&2
        exit 2
      fi

      CONTAINER_NAME=$(container_name "$MODE")
      ensure_running "$MODE" || { echo "Failed to start $CONTAINER_NAME" >&2; exit 1; }

      # The container Tor is needed by --px, --tor, and --socks aimed at it.
      if [ "$VIA" = px ] || [ "$VIA" = tor ] || [ "$SOCKS_ADDR" = "127.0.0.1:9050" ]; then
        ensure_tor "$CONTAINER_NAME" || { echo "Tor unavailable; aborting --$VIA run" >&2; exit 1; }
      fi

      case "$VIA" in
        px)    exec $PODMAN exec "$CONTAINER_NAME" proxychains4 -q "$@" ;;
        tor)   exec $PODMAN exec "$CONTAINER_NAME" torsocks "$@" ;;
        socks) exec $PODMAN exec \
                 -e ALL_PROXY="socks5h://$SOCKS_ADDR" -e all_proxy="socks5h://$SOCKS_ADDR" \
                 "$CONTAINER_NAME" "$@" ;;
        *)     exec $PODMAN exec "$CONTAINER_NAME" "$@" ;;
      esac
    }

    shell() {
      MODE="''${1:-safe}"
      CONTAINER_NAME=$(container_name "$MODE")
      if ! $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
        echo -e "''${RED}Container not running. Use: kali start''${NC}"
        exit 1
      fi
      exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
    }

    stop() {
      MODE="''${1:-safe}"
      CONTAINER_NAME=$(container_name "$MODE")
      echo "Stopping Kali container ($MODE)..."
      $PODMAN stop "$CONTAINER_NAME" 2>/dev/null
      echo -e "''${GREEN}Stopped''${NC}"
    }

    destroy() {
      MODE="''${1:-safe}"
      CONTAINER_NAME=$(container_name "$MODE")
      echo -e "''${RED}This will remove the container (data in $DATA_DIR is preserved)''${NC}"
      read -p "Continue? (y/N): " CONFIRM
      [ "$CONFIRM" = "y" ] || exit 0
      $PODMAN rm -f "$CONTAINER_NAME" 2>/dev/null
      echo -e "''${GREEN}Container removed. Data preserved in $DATA_DIR''${NC}"
    }

    status() {
      echo ""
      echo -e "''${CYAN}═══════════════════════════════════════''${NC}"
      echo -e "''${CYAN}  Kali Red Team Status''${NC}"
      echo -e "''${CYAN}═══════════════════════════════════════''${NC}"
      echo ""

      # Container status
      for MODE in safe net; do
        CONTAINER_NAME=$(container_name "$MODE")
        if $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
          STATE=$($PODMAN inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
          if [ "$STATE" = "running" ]; then
            echo -e "  $MODE:      ''${GREEN}running''${NC} ($(mode_label "$MODE"))"
          else
            echo -e "  $MODE:      ''${YELLOW}$STATE''${NC} ($(mode_label "$MODE"))"
          fi
        else
          echo -e "  $MODE:      ''${RED}not created''${NC} ($(mode_label "$MODE"))"
        fi
      done
      if $PODMAN container exists "$BASE_CONTAINER_NAME" 2>/dev/null; then
        echo -e "  legacy:   ''${YELLOW}$BASE_CONTAINER_NAME exists; remove manually after checking data''${NC}"
      fi

      # Image status
      if $PODMAN image exists "$IMAGE_NAME" 2>/dev/null; then
        SIZE=$($PODMAN image inspect "$IMAGE_NAME" --format '{{.Size}}' 2>/dev/null | awk '{printf "%.1f GB", $1/1024/1024/1024}')
        echo -e "  Image:     ''${GREEN}built ($SIZE)''${NC}"
      else
        echo -e "  Image:     ''${YELLOW}not built (run: kali build)''${NC}"
      fi

      # Data dirs
      echo ""
      echo "  Data: $DATA_DIR/"
      [ -d "$DATA_DIR/workspace" ] && echo "    workspace/  $(ls "$DATA_DIR/workspace" 2>/dev/null | wc -l) items"
      [ -d "$DATA_DIR/loot" ] && echo "    loot/       $(ls "$DATA_DIR/loot" 2>/dev/null | wc -l) items"
      [ -d "$DATA_DIR/reports" ] && echo "    reports/    $(ls "$DATA_DIR/reports" 2>/dev/null | wc -l) items"
      [ -d "$DATA_DIR/wordlists" ] && echo "    wordlists/  $(ls "$DATA_DIR/wordlists" 2>/dev/null | wc -l) items"
      echo ""
    }

    show_help() {
      cat << 'EOF'
    Kali Linux Red Team Container

    Usage: kali <command>

    Commands:
      start       Start safe container and attach (default, no extra net caps)
      net         Start network-tools container (NET_RAW/NET_ADMIN + host loopback)
      run [flags] <cmd>  Non-interactive exec for agents
                         (flags: --net --px --tor --socks <host:port> --no-px)
      shell [mode] Attach to running container (mode: safe|net)
      stop [mode] Stop container (mode: safe|net)
      destroy [mode] Remove container (data preserved)
      build       Build/rebuild image
      status      Show container status

    Persistent data (~/.local/share/kali-redteam/):
      workspace/    Working directory (mounted at /workspace)
      wordlists/    Custom wordlists (mounted at /usr/share/wordlists)
      loot/         Captured data (mounted at /loot)
      reports/      Pentest reports (mounted at /reports)

    EOF
    }

    case "''${1:-}" in
      start|"")   start safe ;;
      net|start-net) start net ;;
      run)        shift; run "$@" ;;
      shell|sh|attach) shell "''${2:-safe}" ;;
      stop)       stop "''${2:-safe}" ;;
      destroy|rm) destroy "''${2:-safe}" ;;
      build)      build_image ;;
      status|s)   status ;;
      help|--help|-h) show_help ;;
      *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
    esac
  '';
  # Thin wrapper so headless agents can call `kali-run ...` directly.
  kali-run = pkgs.writeShellScriptBin "kali-run" ''
    exec ${kali}/bin/kali run "$@"
  '';
in
{
  home.packages = [ kali kali-run ];

  # Operator card for the bare claude-mac-tor agent. Appended to its system
  # prompt via --append-system-prompt-file so the nano model always routes
  # through kali-run (hence Tor) instead of leaking via direct host commands.
  home.file.".local/share/kali-redteam/CARD.md".text = ''
    KALI OPERATOR RULES (Tor-only mode)

    Rule 0: Only test hosts you are authorized to test.
    Rule 1: Route EVERY network action through kali-run. Never run curl, nmap,
    wget, or any network tool directly on the host: that bypasses Tor and leaks
    the real IP. In this mode kali-run sends traffic through Tor by default.

    Commands:
      kali-run <cmd>           through Tor (default in this mode)
      kali-run --no-px <cmd>   direct clearnet, only when you deliberately want it
      kali-run --net <cmd>     raw sockets / SYN scan; this is clearnet, avoid here

    Tor limit: proxychains carries TCP connect only. Under Tor use nmap -sT, never
    -sS. The first kali-run of a session bootstraps Tor (about 20 to 40 seconds);
    later calls are instant.

    Verify Tor before scanning:
      kali-run curl -s https://check.torproject.org/api/ip      expect "IsTor":true

    Keep output small (limited context): save long output to a file, read the tail:
      kali-run nmap -sT -Pn -oN /reports/scan.txt <target>
      kali-run tail -n 40 /reports/scan.txt

    Persistent dirs (host ~/.local/share/kali-redteam/): /workspace /loot /reports
    Container control (host shell): kali status | kali build | kali stop | kali destroy
  '';
}
