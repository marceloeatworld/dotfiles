# Antigravity CLI - Google's terminal agent `agy` (static binary via overlay),
# successor of Gemini CLI.
# Auth: paid GEMINI_API_KEY from sops. agy ignores the key unless
# modelProvider = "gemini" is set (activation below; ask-gemini passes it itself).
# State: ~/.gemini/antigravity-cli (settings.json, conversations, cli.log)
{ config, pkgs, ... }:

let
  # Session-only settings for ask-gemini (--settings, never saved to disk).
  # Deny rules win over every execution mode, so the agent can read and search
  # the repository but its write_file and run_command calls fail with
  # "Matches user-configured deny rule" (checked against agy 1.5.17).
  askGeminiSettings = pkgs.writeText "ask-gemini-settings.json" (builtins.toJSON {
    modelProvider = "gemini";
    permissions.deny = [ "write_file(*)" "command(*)" ];
  });

  # Gemini 4 Neon second opinion for Claude Code, same shape as ask-gpt
  # (codex.nix): one persistent agy conversation per repository, read-only
  # (deny rules above), Gemini reads the repo and answers, Claude decides.
  # Neon instead of Carbon for cost: one question is 100 to 290 agent turns of
  # mostly input tokens. Carbon input lists at $4 per 1M from 2026-12-01 and
  # this billing account was already charged that rate in 2026-11 (the $2
  # promo price never showed on the bill); Neon input is $3.
  # Conversation ids live in ~/.cache/ask-gemini/<repo-hash>.session; delete to restart.
  # Token usage of every call is appended to ~/.cache/ask-gemini/usage.log.
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

    ROOT=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || pwd)
    STATE="$HOME/.cache/ask-gemini"
    ${pkgs.coreutils}/bin/mkdir -p "$STATE"
    KEY=$(printf '%s' "$ROOT" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)
    SESSION_FILE="$STATE/$KEY.session"
    OUT=$(${pkgs.coreutils}/bin/mktemp)
    ERR=$(${pkgs.coreutils}/bin/mktemp)
    trap '${pkgs.coreutils}/bin/rm -f "$OUT" "$ERR"' EXIT

    ARGS=(--model gemini-4-neon-high --settings ${askGeminiSettings} --output-format json)

    # Serialize calls per repository: several Claude terminals share one conversation.
    exec 9>"$STATE/$KEY.lock"
    ${pkgs.util-linux}/bin/flock 9

    cd "$ROOT"
    # An unknown id is not an error: agy warns and starts a new conversation,
    # so the id it reports is saved after every successful run.
    [ -s "$SESSION_FILE" ] && ARGS+=(--conversation "$(${pkgs.coreutils}/bin/cat "$SESSION_FILE")")
    ${pkgs.antigravity-cli}/bin/agy "''${ARGS[@]}" -p "$PROMPT" </dev/null >"$OUT" 2>"$ERR" \
      || { ${pkgs.coreutils}/bin/cat "$ERR" >&2; exit 1; }
    ${pkgs.jq}/bin/jq -r '.conversation_id // empty' "$OUT" > "$SESSION_FILE"
    ${pkgs.jq}/bin/jq -c --arg at "$(${pkgs.coreutils}/bin/date -Is)" --arg repo "$ROOT" \
      '{at: $at, repo: $repo, duration_seconds, usage}' "$OUT" >> "$STATE/usage.log" || true
    ${pkgs.jq}/bin/jq -r '.response // empty' "$OUT"
  '';
in
{
  home.packages = [
    pkgs.antigravity-cli
    askGemini
  ];

  # agy rewrites settings.json on every start (normalized, 0600), so it cannot
  # be a Home Manager symlink. Merge the Nix-owned keys into the live file:
  # modelProvider is forced (API key auth), the default model only when unset,
  # so a later /model choice survives rebuilds. Without a model agy falls back
  # to Gemini 3.1 Pro (Low). ask-gemini passes --model and is unaffected.
  home.activation.antigravityCliSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS="$HOME/.gemini/antigravity-cli/settings.json"

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.gemini/antigravity-cli"
    TMP=$(${pkgs.coreutils}/bin/mktemp "$HOME/.gemini/antigravity-cli/settings.json.tmp.XXXXXX")

    if [ -f "$SETTINGS" ] && ${pkgs.jq}/bin/jq -e . "$SETTINGS" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq '.modelProvider = "gemini" | .model //= "Gemini 4 Carbon (High)"' "$SETTINGS" > "$TMP"
    else
      echo '{"modelProvider":"gemini","model":"Gemini 4 Carbon (High)"}' > "$TMP"
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$SETTINGS"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$SETTINGS"
  '';
}
