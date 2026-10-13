# Gemini CLI - Google's terminal agent (upstream npm bundle via overlay)
# Auth: GEMINI_API_KEY from sops (ask-gemini reads the secret file itself)
# Sessions: ~/.gemini/tmp/<project>/chats (gemini --list-sessions)
{ config, pkgs, ... }:

let
  # Headless plan mode is not read-only on its own: the bundled plan.toml
  # auto-approves exit_plan_mode when non-interactive, and Gemini then
  # switches itself to YOLO (shell + writes). This policy (loaded with
  # --policy, higher tier than the built-ins) removes those tools entirely.
  askGeminiPolicy = pkgs.writeText "ask-gemini-policy.toml" ''
    [[rule]]
    toolName = ["exit_plan_mode", "write_file", "replace", "run_shell_command", "save_memory"]
    decision = "deny"
    priority = 999
    denyMessage = "ask-gemini is a read-only second opinion: answer from the repository, never modify it."
  '';

  # Gemini 4 Argon second opinion for Claude Code, same shape as ask-gpt
  # (codex.nix): one persistent Gemini session per repository, read-only
  # ("plan" approval mode plus the deny policy above), Gemini reads the repo
  # and answers, Claude decides.
  # Session ids live in ~/.cache/ask-gemini/<repo-hash>.session; delete to restart.
  askGemini = pkgs.writeShellScriptBin "ask-gemini" ''
    set -euo pipefail
    if [ $# -eq 0 ]; then
      echo "usage: ask-gemini \"question\"   |   ask-gemini - < prompt.txt" >&2
      exit 1
    fi
    PROMPT="$1"
    [ "$PROMPT" = "-" ] && PROMPT=$(${pkgs.coreutils}/bin/cat)

    KEY_FILE="${config.sops.secrets.gemini_api_key.path}"
    if [ ! -s "$KEY_FILE" ]; then
      echo "ask-gemini: no Gemini API key (add gemini_api_key with the 'secrets' command, then rebuild)" >&2
      exit 1
    fi
    export GEMINI_API_KEY="$(${pkgs.coreutils}/bin/cat "$KEY_FILE")"

    GEMINI=${pkgs.gemini-cli}/bin/gemini
    ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)
    STATE="$HOME/.cache/ask-gemini"
    ${pkgs.coreutils}/bin/mkdir -p "$STATE"
    KEY=$(printf '%s' "$ROOT" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)
    SESSION_FILE="$STATE/$KEY.session"
    OUT=$(${pkgs.coreutils}/bin/mktemp)
    ERR=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$OUT" "$ERR"' EXIT

    # --skip-trust: headless runs refuse untrusted folders
    COMMON=(-m gemini-4-argon --approval-mode plan --policy ${askGeminiPolicy} --skip-trust -o json)

    # Serialize calls per repository: several Claude terminals share one session.
    exec 9>"$STATE/$KEY.lock"
    ${pkgs.util-linux}/bin/flock 9

    cd "$ROOT"
    # </dev/null: -p appends piped stdin to the prompt and blocks for EOF
    ask() {
      "$GEMINI" "''${COMMON[@]}" "$@" -p "$PROMPT" </dev/null >"$OUT" 2>"$ERR"
    }
    if [ -s "$SESSION_FILE" ] && ask --resume "$(${pkgs.coreutils}/bin/cat "$SESSION_FILE")"; then
      :
    else
      # No session yet, or the saved one is gone (chats dir cleaned): start a
      # fresh one. The id is saved only after Gemini created it successfully.
      if [ -s "$SESSION_FILE" ] && ! ${pkgs.gnugrep}/bin/grep -q "Error resuming session" "$ERR"; then
        ${pkgs.coreutils}/bin/cat "$ERR" >&2; exit 1
      fi
      ID=$(${pkgs.util-linux}/bin/uuidgen)
      ask --session-id "$ID" || { ${pkgs.coreutils}/bin/cat "$ERR" >&2; exit 1; }
      echo "$ID" > "$SESSION_FILE"
    fi
    ${pkgs.jq}/bin/jq -r '.response // empty' "$OUT"
  '';
in
{
  home.packages = [
    pkgs.gemini-cli
    askGemini
  ];

  # Default model for interactive `gemini`: resolution order is
  # --model, then GEMINI_MODEL, then settings.json model.name. The env var
  # keeps ~/.gemini/settings.json writable by Gemini (auth, preview flags).
  # ask-gemini passes -m explicitly and is unaffected.
  home.sessionVariables.GEMINI_MODEL = "gemini-4-argon";
}
