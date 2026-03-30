# Kali Linux headless container for red team operations
# Uses Podman (rootless) with persistent storage and access to local LLM (llama-cpp)
# Container has access to host's llama-cpp API on port 8080 for AI-assisted pentesting
{ pkgs, ... }:

let
  # LLM helper script — sends prompts to host llama-cpp
  llm-script = pkgs.writeText "kali-llm" ''
    #!/bin/bash
    # Query local LLM (llama-cpp on host via gateway)
    PROMPT="$*"
    if [ -z "$PROMPT" ]; then
      echo "Usage: llm <prompt>"
      echo "       echo 'prompt' | llm"
      [ -t 0 ] && exit 1
      PROMPT=$(cat)
    fi
    curl -s http://10.0.2.2:8080/v1/chat/completions \
      -H "Content-Type: application/json" \
      -d "{\"messages\":[{\"role\":\"system\",\"content\":\"You are a red team security expert assistant. Provide concise, actionable advice for authorized penetration testing.\"},{\"role\":\"user\",\"content\":$(echo "$PROMPT" | jq -Rs .)}],\"temperature\":0.7,\"max_tokens\":2048}" \
      | jq -r '.choices[0].message.content // .error.message // "Error: no response"'
  '';

  # Recon helper — AI-assisted reconnaissance
  recon-script = pkgs.writeText "kali-recon-ai" ''
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
    printf "Analyze these nmap results and suggest next steps for authorized penetration testing:\n\n%s" "$NMAP_RESULT" | llm
  '';

  # AI agent — autonomous red team loop with user confirmation
  agent-script = pkgs.writeText "kali-ai-agent" ''
    #!/bin/bash
    # AI Red Team Agent — LLM-driven autonomous pentesting
    # The LLM plans and executes commands in a loop with user approval

    LLM_URL="http://10.0.2.2:8080/v1/chat/completions"
    LOG_FILE="/workspace/ai-agent.log"
    MSGS_FILE=$(mktemp /tmp/ai-agent-msgs.XXXXXX.json)
    trap 'rm -f "$MSGS_FILE" /tmp/ai-agent-out.*' EXIT

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    OBJECTIVE="$*"
    if [ -z "$OBJECTIVE" ]; then
      echo -e "''${CYAN}AI Red Team Agent''${NC}"
      echo "Usage: ai-agent <objective>"
      echo ""
      echo "Examples:"
      echo "  ai-agent 'enumerate services on 192.168.1.0/24'"
      echo "  ai-agent 'find web vulnerabilities on target.com'"
      echo "  ai-agent 'test authentication on 10.0.0.5:8080'"
      exit 1
    fi

    # Build initial messages using jq (no manual JSON escaping)
    SYSTEM_PROMPT='You are an autonomous red team AI agent inside Kali Linux. You have all Kali tools (nmap, sqlmap, nikto, hydra, metasploit, gobuster, etc.).

    Accomplish the objective through shell commands. RESPOND WITH ONLY A JSON OBJECT:
    {"thought": "your reasoning", "command": "the shell command"}

    Rules:
    - One command at a time, wait for output
    - When done: {"thought": "objective complete", "command": "DONE"}
    - Recon/enumeration first, non-destructive
    - Pipe long outputs through head -50
    - Save findings to /loot/
    - This is an authorized pentest'

    jq -n --arg sys "$SYSTEM_PROMPT" --arg obj "Objective: $OBJECTIVE" \
      '[{"role":"system","content":$sys},{"role":"user","content":$obj}]' > "$MSGS_FILE"

    echo -e "''${CYAN}═══════════════════════════════════════''${NC}"
    echo -e "''${CYAN}  AI Red Team Agent''${NC}"
    echo -e "''${CYAN}═══════════════════════════════════════''${NC}"
    echo -e "  Objective: ''${GREEN}$OBJECTIVE''${NC}"
    echo -e "  Mode: ''${YELLOW}supervised (confirm each command)''${NC}"
    echo ""
    echo "$(date): Started - $OBJECTIVE" >> "$LOG_FILE"

    STEP=0
    while true; do
      STEP=$((STEP + 1))
      echo -e "''${CYAN}--- Step $STEP ---''${NC}"

      # Build request payload using jq
      REQUEST=$(jq -n --slurpfile msgs "$MSGS_FILE" \
        '{"messages":$msgs[0],"temperature":0.3,"max_tokens":512}')

      # Ask LLM for next command
      RAW=$(curl -s "$LLM_URL" -H "Content-Type: application/json" -d "$REQUEST")
      RESPONSE=$(echo "$RAW" | jq -r '.choices[0].message.content // "ERROR"')

      if [ "$RESPONSE" = "ERROR" ]; then
        echo -e "''${RED}LLM error. Is llama-cpp running? (llm-switch 9b on host)''${NC}"
        echo "Raw: $RAW"
        exit 1
      fi

      # Try to extract JSON from response (may be wrapped in markdown)
      JSON_BLOCK=$(echo "$RESPONSE" | sed -n 's/.*\({.*"command".*}\).*/\1/p' | head -1)
      [ -z "$JSON_BLOCK" ] && JSON_BLOCK="$RESPONSE"

      THOUGHT=$(echo "$JSON_BLOCK" | jq -r '.thought // empty' 2>/dev/null)
      COMMAND=$(echo "$JSON_BLOCK" | jq -r '.command // empty' 2>/dev/null)

      if [ -z "$COMMAND" ]; then
        echo -e "''${YELLOW}LLM:''${NC} $RESPONSE"
        echo -e "''${RED}Could not parse command. Retrying...''${NC}"
        # Ask to retry with proper format
        jq --arg resp "$RESPONSE" \
          '. + [{"role":"assistant","content":$resp},{"role":"user","content":"Respond with ONLY a JSON object: {\"thought\": \"...\", \"command\": \"...\"}"}]' \
          "$MSGS_FILE" > "''${MSGS_FILE}.tmp" && mv "''${MSGS_FILE}.tmp" "$MSGS_FILE"
        continue
      fi

      # Check if done
      if [ "$COMMAND" = "DONE" ]; then
        echo -e "''${GREEN}Objective complete!''${NC}"
        echo -e "  Reason: $THOUGHT"
        echo "$(date): Completed - $THOUGHT" >> "$LOG_FILE"
        break
      fi

      echo -e "  ''${YELLOW}Thought:''${NC} $THOUGHT"
      echo -e "  ''${CYAN}Command:''${NC} $COMMAND"
      echo ""

      # Ask user for confirmation
      echo -ne "  ''${GREEN}[R]un''${NC} / ''${YELLOW}[S]kip''${NC} / ''${RED}[Q]uit''${NC} / [E]dit? "
      read -r CHOICE

      OUT_FILE=$(mktemp /tmp/ai-agent-out.XXXXXX)

      # Run command — output streams live, Ctrl+C kills only the command
      run_cmd() {
        eval "$1" 2>&1 | head -200 | tee "$OUT_FILE"
      }

      case "$CHOICE" in
        r|R|"")
          echo -e "  ''${GREEN}Executing...''${NC} (Ctrl+C to cancel command)"
          echo ""
          echo "$(date): RUN: $COMMAND" >> "$LOG_FILE"
          run_cmd "$COMMAND"
          OUTPUT=$(cat "$OUT_FILE")
          echo ""
          ;;
        s|S)
          OUTPUT="[User skipped this command]"
          echo -e "  ''${YELLOW}Skipped''${NC}"
          ;;
        e|E)
          echo -n "  Enter modified command: "
          read -r COMMAND
          echo -e "  ''${GREEN}Executing: $COMMAND''${NC} (Ctrl+C to cancel)"
          echo ""
          echo "$(date): EDIT+RUN: $COMMAND" >> "$LOG_FILE"
          run_cmd "$COMMAND"
          OUTPUT=$(cat "$OUT_FILE")
          echo ""
          ;;
        q|Q)
          echo -e "''${RED}Aborted by user''${NC}"
          echo "$(date): Aborted by user at step $STEP" >> "$LOG_FILE"
          exit 0
          ;;
        *)
          OUTPUT="[User skipped this command]"
          ;;
      esac

      # Add to conversation history using jq (safe escaping)
      jq --arg resp "$JSON_BLOCK" --arg out "Command output:\n$OUTPUT\n\nWhat is the next step?" \
        '. + [{"role":"assistant","content":$resp},{"role":"user","content":$out}]' \
        "$MSGS_FILE" > "''${MSGS_FILE}.tmp" && mv "''${MSGS_FILE}.tmp" "$MSGS_FILE"

      # Keep conversation manageable (system + user + last 20)
      MSG_COUNT=$(jq 'length' "$MSGS_FILE")
      if [ "$MSG_COUNT" -gt 22 ]; then
        jq '.[0:2] + .[-20:]' "$MSGS_FILE" > "''${MSGS_FILE}.tmp" && mv "''${MSGS_FILE}.tmp" "$MSGS_FILE"
      fi
    done
  '';

  # Containerfile for Kali with red team tools + LLM integration
  # Scripts are COPY'd from nix store paths to avoid Nix string escaping issues
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

    # Install LLM scripts into a running container
    install_scripts() {
      $PODMAN cp "${llm-script}" "$CONTAINER_NAME:/usr/local/bin/llm"
      $PODMAN exec "$CONTAINER_NAME" chmod +x /usr/local/bin/llm
      $PODMAN cp "${recon-script}" "$CONTAINER_NAME:/usr/local/bin/recon-ai"
      $PODMAN exec "$CONTAINER_NAME" chmod +x /usr/local/bin/recon-ai
      $PODMAN cp "${agent-script}" "$CONTAINER_NAME:/usr/local/bin/ai-agent"
      $PODMAN exec "$CONTAINER_NAME" chmod +x /usr/local/bin/ai-agent
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
          install_scripts
          exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
        else
          echo "Starting existing container..."
          $PODMAN start "$CONTAINER_NAME"
          install_scripts
          exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
        fi
      fi

      echo -e "''${GREEN}Starting Kali Red Team container...''${NC}"
      echo -e "  LLM access: ''${CYAN}http://10.0.2.2:8080''${NC}"
      echo -e "  Workspace:  ''${CYAN}$DATA_DIR/workspace''${NC}"
      echo ""

      $PODMAN run -d \
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
        sleep infinity

      install_scripts
      exec $PODMAN exec -it "$CONTAINER_NAME" /bin/bash
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
      llm "prompt"              Query local LLM for red team advice
      recon-ai <target>         AI-assisted recon (nmap + LLM analysis)
      ai-agent <objective>      Autonomous AI agent (LLM plans + executes)

    AI Agent mode:
      The LLM receives your objective, plans commands, and executes them
      in a loop. You confirm each command before execution.
      Options: [R]un / [S]kip / [Q]uit / [E]dit

    Persistent data (~/.local/share/kali-redteam/):
      workspace/    Working directory (mounted at /workspace)
      wordlists/    Custom wordlists (mounted at /usr/share/wordlists)
      loot/         Captured data (mounted at /loot)
      reports/      Pentest reports (mounted at /reports)

    Network:
      Container has full network access + host LLM on port 8080
      Use 10.0.2.2:8080 to reach llama-cpp from inside

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
