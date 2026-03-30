# Kali Linux headless container for red team operations
# Uses Podman (rootless) with persistent storage and access to local LLM (llama-cpp)
# Container has access to host's llama-cpp API on port 8080 for AI-assisted pentesting
{ pkgs, ... }:

let
  # Containerfile for Kali with red team tools + LLM integration
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
    RUN mkdir -p /workspace /root/.config

    # LLM helper script — sends prompts to host llama-cpp
    RUN cat > /usr/local/bin/llm <<'SCRIPT'
    #!/bin/bash
    # Query local LLM (llama-cpp on host via gateway)
    PROMPT="$*"
    if [ -z "$PROMPT" ]; then
      echo "Usage: llm <prompt>"
      echo "       echo 'prompt' | llm"
      [ -t 0 ] && exit 1
      PROMPT=$(cat)
    fi
    curl -s http://host.containers.internal:8080/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d "{\"messages\":[{\"role\":\"system\",\"content\":\"You are a red team security expert assistant. Provide concise, actionable advice for authorized penetration testing.\"},{\"role\":\"user\",\"content\":$(echo "$PROMPT" | jq -Rs .)}],\"temperature\":0.7,\"max_tokens\":2048}" \
      | jq -r '.choices[0].message.content // .error.message // "Error: no response"'
    SCRIPT
    RUN chmod +x /usr/local/bin/llm

    # Recon helper — AI-assisted reconnaissance
    RUN cat > /usr/local/bin/recon-ai <<'SCRIPT'
    #!/bin/bash
    TARGET="$1"
    if [ -z "$TARGET" ]; then
      echo "Usage: recon-ai <target>"
      exit 1
    fi
    echo "=== AI-Assisted Recon: $TARGET ==="
    echo ""
    echo "[*] Running nmap quick scan..."
    NMAP_RESULT=$(nmap -T4 -F "$TARGET" 2>&1)
    echo "$NMAP_RESULT"
    echo ""
    echo "[*] Asking LLM for analysis..."
    echo "Analyze these nmap results and suggest next steps for authorized penetration testing:\n\n$NMAP_RESULT" | llm
    SCRIPT
    RUN chmod +x /usr/local/bin/recon-ai

    WORKDIR /workspace
    CMD ["/bin/bash"]
  '';

  # Main kali management command
  kali = pkgs.writeShellScriptBin "kali" ''
    CONTAINER_NAME="kali-redteam"
    IMAGE_NAME="kali-redteam:latest"
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
      $PODMAN build -t "$IMAGE_NAME" -f "${kali-containerfile}" .
      echo -e "''${GREEN}Image built successfully''${NC}"
    }

    ensure_dirs() {
      mkdir -p "$DATA_DIR/workspace"
      mkdir -p "$DATA_DIR/wordlists"
      mkdir -p "$DATA_DIR/loot"
      mkdir -p "$DATA_DIR/reports"
    }

    start() {
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

      echo -e "''${GREEN}Starting Kali Red Team container...''${NC}"
      echo -e "  LLM access: ''${CYAN}http://host.containers.internal:8080''${NC}"
      echo -e "  Workspace:  ''${CYAN}$DATA_DIR/workspace''${NC}"
      echo ""

      exec $PODMAN run -it \
        --name "$CONTAINER_NAME" \
        --hostname kali-redteam \
        --network slirp4netns:allow_host_loopback=true \
        -v "$DATA_DIR/workspace:/workspace:Z" \
        -v "$DATA_DIR/wordlists:/usr/share/wordlists:Z" \
        -v "$DATA_DIR/loot:/loot:Z" \
        -v "$DATA_DIR/reports:/reports:Z" \
        --cap-add=NET_RAW \
        --cap-add=NET_ADMIN \
        "$IMAGE_NAME" \
        /bin/bash
    }

    shell() {
      if ! $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
        echo -e "''${RED}Container not running. Use: kali start''${NC}"
        exit 1
      fi
      exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
    }

    stop() {
      echo "Stopping Kali container..."
      $PODMAN stop "$CONTAINER_NAME" 2>/dev/null
      echo -e "''${GREEN}Stopped''${NC}"
    }

    destroy() {
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
      if $PODMAN container exists "$CONTAINER_NAME" 2>/dev/null; then
        STATE=$($PODMAN inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ "$STATE" = "running" ]; then
          echo -e "  Container: ''${GREEN}running''${NC}"
        else
          echo -e "  Container: ''${YELLOW}$STATE''${NC}"
        fi
      else
        echo -e "  Container: ''${RED}not created''${NC}"
      fi

      # Image status
      if $PODMAN image exists "$IMAGE_NAME" 2>/dev/null; then
        SIZE=$($PODMAN image inspect "$IMAGE_NAME" --format '{{.Size}}' 2>/dev/null | awk '{printf "%.1f GB", $1/1024/1024/1024}')
        echo -e "  Image:     ''${GREEN}built ($SIZE)''${NC}"
      else
        echo -e "  Image:     ''${YELLOW}not built (run: kali build)''${NC}"
      fi

      # LLM status
      if curl -s --connect-timeout 2 http://127.0.0.1:8080/health 2>/dev/null | grep -q "ok"; then
        echo -e "  LLM:       ''${GREEN}online (port 8080)''${NC}"
      else
        echo -e "  LLM:       ''${RED}offline (start with: llm-switch 4b)''${NC}"
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
      start       Start container and attach (builds image if needed)
      shell       Attach to running container
      stop        Stop container
      destroy     Remove container (data preserved)
      build       Build/rebuild image
      status      Show container and LLM status

    Inside the container:
      llm "prompt"        Query local LLM for red team advice
      recon-ai <target>   AI-assisted reconnaissance (nmap + LLM analysis)

    Persistent data (~/.local/share/kali-redteam/):
      workspace/    Working directory (mounted at /workspace)
      wordlists/    Custom wordlists (mounted at /usr/share/wordlists)
      loot/         Captured data (mounted at /loot)
      reports/      Pentest reports (mounted at /reports)

    Network:
      Container has full network access + host LLM on port 8080
      Use host.containers.internal:8080 to reach llama-cpp from inside

    EOF
    }

    case "''${1:-}" in
      start|"")   start ;;
      shell|sh|attach) shell ;;
      stop)       stop ;;
      destroy|rm) destroy ;;
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
