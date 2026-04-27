# Kali Linux headless container for red team operations
# Uses Podman (rootless) with persistent storage
# AI-assisted pentesting via Hermes Agent skill (supports local + cloud models)
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
        && apt-get clean && rm -rf /var/lib/apt/lists/*

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

    start() {
      MODE="''${1:-safe}"
      CONTAINER_NAME=$(container_name "$MODE")

      # Check if image exists
      if ! $PODMAN image exists "$IMAGE_NAME" 2>/dev/null; then
        echo -e "''${YELLOW}Image not found. Building...''${NC}"
        build_image
      fi

      ensure_dirs

      # Check if container already running
      if $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
        STATE=$($PODMAN inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ "$STATE" = "running" ]; then
          echo -e "''${GREEN}Container already running. Attaching...''${NC}"
          exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
        else
          echo "Starting existing container..."
          $PODMAN start "$CONTAINER_NAME"
          exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
        fi
      fi

      echo -e "''${GREEN}Starting Kali Red Team container ($(mode_label "$MODE"))...''${NC}"
      echo -e "  Workspace:  ''${CYAN}$DATA_DIR/workspace''${NC}"
      echo ""

      if [ "$MODE" = "net" ]; then
        $PODMAN run -d \
          --name "$CONTAINER_NAME" \
          --hostname kali-redteam-net \
          --network slirp4netns:allow_host_loopback=true \
          -v "$DATA_DIR/workspace:/workspace:Z" \
          -v "$DATA_DIR/wordlists:/usr/share/wordlists:Z" \
          -v "$DATA_DIR/loot:/loot:Z" \
          -v "$DATA_DIR/reports:/reports:Z" \
          --security-opt=no-new-privileges \
          --cap-add=NET_RAW \
          --cap-add=NET_ADMIN \
          "$IMAGE_NAME" \
          sleep infinity
      else
        $PODMAN run -d \
          --name "$CONTAINER_NAME" \
          --hostname kali-redteam-safe \
          --network slirp4netns \
          -v "$DATA_DIR/workspace:/workspace:Z" \
          -v "$DATA_DIR/wordlists:/usr/share/wordlists:Z" \
          -v "$DATA_DIR/loot:/loot:Z" \
          -v "$DATA_DIR/reports:/reports:Z" \
          --security-opt=no-new-privileges \
          --cap-drop=ALL \
          "$IMAGE_NAME" \
          sleep infinity
      fi

      exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
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
      shell [mode] Attach to running container (mode: safe|net)
      stop [mode] Stop container (mode: safe|net)
      destroy [mode] Remove container (data preserved)
      build       Build/rebuild image
      status      Show container status

    AI-assisted pentesting (via Hermes Agent):
      kali-ai                 Hermes + Kali (local model)
      kali-ai-coder           Hermes + Kali (GLM-5.1)
      kali-ai-minimax         Hermes + Kali (MiniMax M1)

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
in
{
  home.packages = [ kali ];
}
