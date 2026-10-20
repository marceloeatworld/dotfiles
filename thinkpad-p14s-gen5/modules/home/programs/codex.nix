# Codex - OpenAI's lightweight coding agent for terminal
# Installed via overlay (prebuilt musl binary from GitHub releases)
# Config: ~/.codex/config.toml (not managed by Nix; codex creates it as needed)
# Auth: codex login (oauth tokens stored in ~/.codex/auth.json)
# Sandbox: codex uses bubblewrap (bwrap) to sandbox shell/tool calls
{ pkgs, ... }:

let
  # GPT-6 second opinion for Claude Code (enabled per session with CLAUDE_GPT=1,
  # alias claude-gpt). One persistent Codex thread per repository, so GPT keeps
  # context across questions and across Claude terminals. Read-only sandbox:
  # GPT reads the repo and answers, Claude verifies and decides.
  # Thread ids live in ~/.cache/ask-gpt/<repo-hash>.thread; delete to restart.
  askGpt = pkgs.writeShellScriptBin "ask-gpt" ''
    set -euo pipefail
    if [ $# -eq 0 ]; then
      echo "usage: ask-gpt \"question\"   |   ask-gpt - < prompt.txt" >&2
      exit 1
    fi
    PROMPT="$1"
    [ "$PROMPT" = "-" ] && PROMPT=$(${pkgs.coreutils}/bin/cat)

    CODEX=${pkgs.codex}/bin/codex
    ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)
    STATE="$HOME/.cache/ask-gpt"
    ${pkgs.coreutils}/bin/mkdir -p "$STATE"
    KEY=$(printf '%s' "$ROOT" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)
    THREAD_FILE="$STATE/$KEY.thread"
    OUT=$(${pkgs.coreutils}/bin/mktemp)
    ERR=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$OUT" "$ERR"' EXIT

    COMMON=(-m gpt-6-astra -c model_reasoning_effort=high -c 'sandbox_mode="read-only"' --skip-git-repo-check -o "$OUT")

    # Serialize calls per repository: several Claude terminals share one thread.
    exec 9>"$STATE/$KEY.lock"
    ${pkgs.util-linux}/bin/flock 9

    if [ -s "$THREAD_FILE" ]; then
      # </dev/null: codex exec appends piped stdin to the prompt and blocks for EOF
      "$CODEX" exec resume "''${COMMON[@]}" "$(${pkgs.coreutils}/bin/cat "$THREAD_FILE")" "$PROMPT" </dev/null >/dev/null 2>"$ERR" \
        || { ${pkgs.coreutils}/bin/cat "$ERR" >&2; exit 1; }
    else
      "$CODEX" exec --json "''${COMMON[@]}" -C "$ROOT" "$PROMPT" </dev/null 2>"$ERR" \
        | ${pkgs.jq}/bin/jq -r 'select(.type == "thread.started") | .thread_id' > "$THREAD_FILE" \
        || { ${pkgs.coreutils}/bin/cat "$ERR" >&2; exit 1; }
    fi
    ${pkgs.coreutils}/bin/cat "$OUT"
  '';
in
{
  home.packages = [
    pkgs.codex
    pkgs.bubblewrap  # Required by codex for tool sandboxing
    askGpt
  ];
}
