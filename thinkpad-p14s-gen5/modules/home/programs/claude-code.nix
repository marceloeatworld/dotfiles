# Claude Code - AI-powered CLI assistant
# Installed via nixpkgs with declarative configuration management
{ config, lib, pkgs, ... }:

let
  # Hooks follow the official Claude Code hooks documentation:
  # https://code.claude.com/docs/en/hooks

  # PostToolUse hook: auto-inject core principles into any CLAUDE.md created by Claude
  ensureClaudeMdPrincipleHook = pkgs.writeText "ensure_claudemd_principle.py" ''
    #!/usr/bin/env python3
    """
    Claude Code PostToolUse Hook — Ensure Core Principles in CLAUDE.md

    After any Write or Edit on a CLAUDE.md file, checks if the
    "Think before coding" principles block is present.
    If missing, prepends it automatically.
    """
    import sys
    import json
    import os

    PRINCIPLE_MARKER = "Think before coding"
    PRINCIPLE_BLOCK = """## Principles

    ### 1. Think before coding
    Don't assume. Don't hide confusion. State ambiguity explicitly. Present multiple interpretations rather than silently picking one. Push back if a simpler approach exists. Stop and ask rather than guess.

    ### 2. Simplicity first
    No features beyond what was asked. No abstractions for single-use code. No "flexibility" that wasn't requested. No error handling for impossible scenarios. The test: would a senior engineer say this is overcomplicated? If yes, rewrite it.
    Before new code, climb: not needed > already in repo > stdlib > native platform > installed dep > one line > minimal new code.
    Bug fix: grep every caller of the function, fix the shared function once, not the one path the report names.

    ### 3. Surgical changes
    Don't "improve" adjacent code. Don't refactor things that aren't broken. Match the existing style even if you'd do it differently. If you notice unrelated dead code, mention it, don't delete it. Every changed line should trace directly to the request.

    ### 4. Goal-driven execution
    Transform "fix the bug" into "write a test that reproduces it, then make it pass." Transform "add validation" into "write tests for invalid inputs, then make them pass." Give it success criteria and watch it loop until done.

    """

    def main():
        try:
            data = json.load(sys.stdin)
        except (json.JSONDecodeError, EOFError):
            sys.exit(0)

        tool = data.get("tool_name", "")
        inp = data.get("tool_input", {})

        if tool not in ("Write", "Edit"):
            sys.exit(0)

        file_path = inp.get("file_path", "")
        if not os.path.basename(file_path) == "CLAUDE.md":
            sys.exit(0)

        if not os.path.isfile(file_path):
            sys.exit(0)

        # The global ~/.claude/CLAUDE.md already carries the block for every project.
        try:
            with open(os.path.expanduser("~/.claude/CLAUDE.md")) as g:
                if PRINCIPLE_MARKER in g.read():
                    sys.exit(0)
        except OSError:
            pass

        try:
            with open(file_path, "r") as f:
                content = f.read()
        except OSError:
            sys.exit(0)

        if PRINCIPLE_MARKER in content:
            sys.exit(0)

        # Find insertion point: after the first heading, or at the top
        lines = content.split("\n")
        insert_idx = 0
        for i, line in enumerate(lines):
            if line.startswith("# ") and i == 0:
                # Skip the title line + any blank lines after it
                insert_idx = i + 1
                while insert_idx < len(lines) and lines[insert_idx].strip() == "":
                    insert_idx += 1
                break

        lines.insert(insert_idx, PRINCIPLE_BLOCK)

        with open(file_path, "w") as f:
            f.write("\n".join(lines))

        sys.exit(0)

    if __name__ == "__main__":
        main()
  '';

  protectSensitiveFilesHook = pkgs.writeText "protect_sensitive_files.py" ''
    #!/usr/bin/env python3
    """
    Claude Code PreToolUse Security Hook — Defense in Depth

    Complements permissions.deny (gitignore-style path rules, which also cover
    recognized Bash file commands) with name/extension heuristics for paths
    the deny rules don't enumerate.
    Uses the recommended JSON output format (exit 0 + permissionDecision: deny)
    instead of exit code 2, giving Claude a structured reason for the block.

    Exit codes per official docs:
      0 — Success. stdout parsed as JSON for hookSpecificOutput.
      1 — Non-blocking error (logged in verbose mode only).
      2 — Hard block (stderr shown to Claude, stdout/JSON ignored).
    """
    import sys
    import json
    import os
    from pathlib import Path

    # Code extensions that are never sensitive (bypass prefix rules)
    SAFE_EXTENSIONS = frozenset({
        'js', 'jsx', 'ts', 'tsx', 'mjs', 'cjs',
        'html', 'css', 'scss', 'sass', 'less', 'vue', 'svelte',
        'py', 'rb', 'php', 'go', 'rs', 'java', 'kt', 'scala', 'cs',
        'c', 'cpp', 'cc', 'h', 'hpp',
        'yaml', 'yml', 'toml', 'xml', 'json',
        'md', 'rst', 'txt',
        'sh', 'bash', 'zsh', 'fish',
        'nix', 'dart', 'sql', 'graphql', 'proto',
    })

    # Crypto/key extensions (private material only; crt/cer/der/asc are
    # public certificates/signatures and produced false positives)
    SENSITIVE_EXTENSIONS = frozenset({
        'pem', 'key', 'p12', 'pfx',
        'keystore', 'jks', 'gpg', 'pgp',
    })

    # Exact file names (case-insensitive)
    SENSITIVE_NAMES = frozenset({
        '.env', '.env.local', '.env.production', '.env.development',
        '.env.staging', '.env.test', '.envrc',
        'id_rsa', 'id_ed25519', 'id_dsa', 'id_ecdsa',
        'id_rsa.pub', 'id_ed25519.pub', 'id_dsa.pub', 'id_ecdsa.pub',
        'known_hosts', 'authorized_keys',
        'credentials.json', 'service-account.json', 'secrets.json',
        'credentials', '.credentials', 'client_secret.json',
        '.netrc', '.npmrc', '.pypirc', '.gemrc', '.yarnrc',
        'htpasswd', 'shadow', 'sudoers',
        '.bash_history', '.zsh_history', '.python_history',
        '.node_repl_history', '.psql_history', '.mysql_history',
    })

    # File name prefixes (only checked for non-code files)
    SENSITIVE_PREFIXES = (
        '.env', 'secret', 'credential', 'token',
        'password', 'apikey', 'api_key', 'private',
    )

    # .env-prefixed names that are templates by convention (never hold real secrets).
    SAFE_ENV_TEMPLATES = frozenset({
        '.env.example', '.env.sample', '.env.template',
        '.env.dist', '.env.defaults',
        'env.example', 'env.sample', 'env.template',
    })

    # Directory names (single path component match).
    # 'sops' removed: the repo's sops/ dir only holds age-encrypted YAML that is
    # safe to read; the real key lives under ~/.config/sops (SENSITIVE_PATHS).
    SENSITIVE_DIRS = frozenset({
        '.ssh', '.gnupg', '.pgp',
        '.aws', '.azure', '.gcloud',
        '.kube', '.docker', '.helm',
        '.password-store',
        'secrets', 'credentials',
    })

    # Multi-component directory paths (matched as substrings of full path)
    SENSITIVE_PATHS = (
        '/.config/gcloud/',
        '/.config/containers/',
        '/.config/sops/',
        '/.local/share/keyrings/',
        '/.config/waybar/.env',
    )

    # Dangerous bash patterns. Kept minimal on purpose (patterns must be
    # lowercase, they are matched against a lowercased command):
    # - rm -rf / and ~ are circuit-broken by Claude Code itself in every mode
    # - cat/head/tail/sed on protected paths are blocked natively by the
    #   permissions.deny Read rules (they extend to Bash file commands)
    # The old substring list blocked legitimate commands such as
    # "rm -rf /tmp/build" ('rm -rf /' substring) and any cat of a path
    # containing "secrets".
    DANGEROUS_COMMANDS = (
        'mkfs.', ':(){:|:&};:',
        'chmod 777', 'chmod -r 777',
        'dd of=/dev/',
    )

    def deny(reason):
        """Output JSON deny decision and exit 0 (per official docs)."""
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": f"Security policy: {reason}",
            }
        }))
        sys.exit(0)

    def check_file(file_path_str):
        """Check if a file path is sensitive."""
        path = Path(file_path_str)
        full = str(path).lower()
        name = path.name.lower()
        suffix = path.suffix.lstrip('.').lower()
        parts = {p.lower() for p in path.parts}

        # Path traversal
        if '..' in os.path.normpath(file_path_str):
            deny("path traversal detected")

        # Multi-component path match (handles .config/gcloud etc.)
        for sp in SENSITIVE_PATHS:
            if sp in full or full.endswith(sp.rstrip('/')):
                deny(f"sensitive path '{sp}'")

        # Single-component directory match
        for d in SENSITIVE_DIRS:
            if d in parts:
                deny(f"sensitive directory '{d}'")

        # Exact file name
        if name in SENSITIVE_NAMES:
            deny(f"sensitive file '{path.name}'")

        # Sensitive extensions
        if suffix in SENSITIVE_EXTENSIONS:
            deny(f"sensitive extension '.{suffix}'")

        # Code files bypass prefix checks
        if suffix in SAFE_EXTENSIONS:
            return

        # Allow well-known .env templates (e.g. .env.example) — never contain secrets.
        if name in SAFE_ENV_TEMPLATES:
            return

        # Prefix match (non-code files only)
        for prefix in SENSITIVE_PREFIXES:
            if name.startswith(prefix):
                deny(f"sensitive name pattern '{name}'")

    def check_command(command):
        """Check if a bash command is dangerous."""
        cmd = ' '.join(command.lower().split())
        for pattern in DANGEROUS_COMMANDS:
            if pattern in cmd:
                deny(f"dangerous command '{pattern}'")

    def main():
        try:
            data = json.load(sys.stdin)
        except (json.JSONDecodeError, EOFError):
            sys.exit(0)  # Fail open

        tool = data.get('tool_name', "")
        inp = data.get('tool_input', {})

        if tool in ('Read', 'Edit', 'Write', 'Glob', 'Grep') and inp.get('file_path'):
            check_file(inp['file_path'])

        if tool in ('Glob', 'Grep') and inp.get('path'):
            check_file(inp['path'])

        if tool == 'Bash' and inp.get('command'):
            check_command(inp['command'])

        sys.exit(0)  # Allow

    if __name__ == '__main__':
        main()
  '';

  # Statusline: shows model | effort | branch | ctx% (colored) | cache hit% | cost
  statuslineScript = pkgs.writeText "claude-statusline.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail
    INPUT=$(${pkgs.coreutils}/bin/cat)
    MODEL=$(${pkgs.jq}/bin/jq -r '.model.display_name // "?"' <<< "$INPUT")
    EFFORT=$(${pkgs.jq}/bin/jq -r '.effort.level // "?"' <<< "$INPUT")
    # Main-conversation prompt cache: read share of all input tokens this
    # session, and whether the cached prefix is still inside its TTL. A low
    # share means the cache keeps breaking (model/effort switch, long gap).
    CACHE=$(${pkgs.jq}/bin/jq -r 'if .prompt_cache.hit_ratio == null then "-" else ((.prompt_cache.hit_ratio * 100 | floor | tostring) + "%" + (if .prompt_cache.warm then "" else " cold" end)) end' <<< "$INPUT")
    PCT_RAW=$(${pkgs.jq}/bin/jq -r '.context_window.used_percentage // 0' <<< "$INPUT")
    PCT=$(${pkgs.coreutils}/bin/printf '%.0f' "$PCT_RAW")
    COST_RAW=$(${pkgs.jq}/bin/jq -r '.cost.total_cost_usd // 0' <<< "$INPUT")
    COST=$(${pkgs.coreutils}/bin/printf '$%.3f' "$COST_RAW")
    CWD=$(${pkgs.jq}/bin/jq -r '.workspace.current_dir // "."' <<< "$INPUT")
    BRANCH=$(${pkgs.git}/bin/git -C "$CWD" branch --show-current 2>/dev/null || echo "-")

    if [ "$PCT" -gt 80 ]; then COLOR=$'\033[31m'
    elif [ "$PCT" -gt 60 ]; then COLOR=$'\033[33m'
    else COLOR=$'\033[32m'; fi
    RESET=$'\033[0m'

    ${pkgs.coreutils}/bin/printf '[%s @%s] %s | %s%s%% ctx%s | cache %s | %s' \
      "$MODEL" "$EFFORT" "$BRANCH" "$COLOR" "$PCT" "$RESET" "$CACHE" "$COST"
  '';

  # PreCompact hook: re-inject critical NixOS invariants before context is summarized
  preCompactScript = pkgs.writeText "claude-pre-compact.sh" ''
    #!/usr/bin/env bash
    ${pkgs.coreutils}/bin/cat <<'EOF'
    {
      "hookSpecificOutput": {
        "hookEventName": "PreCompact",
        "additionalContext": "COMPACTION REMINDER: NixOS flake repo at ~/dotfiles/thinkpad-p14s-gen5. Rebuild = nh os switch (alias: rebuild). New files MUST be git-staged before flakes see them. Never apt/brew. Always $HOME not hardcoded paths. State version 25.05 - never change. Hostname: pop."
      }
    }
    EOF
  '';

  # SessionStart hook: inject git branch + last NixOS generation at start
  sessionStartScript = pkgs.writeText "claude-session-start.sh" ''
    #!/usr/bin/env bash
    INPUT=$(${pkgs.coreutils}/bin/cat)
    CWD=$(${pkgs.jq}/bin/jq -r '.workspace.current_dir // "."' <<< "$INPUT")
    BRANCH=$(${pkgs.git}/bin/git -C "$CWD" branch --show-current 2>/dev/null || echo "no-git")
    GEN=$(${pkgs.coreutils}/bin/readlink /run/current-system 2>/dev/null | ${pkgs.gnused}/bin/sed 's|.*/||' || echo "unknown")
    LAST_COMMIT=$(${pkgs.git}/bin/git -C "$CWD" log -1 --format='%h %s' 2>/dev/null || echo "no-git")

    ${pkgs.jq}/bin/jq -nc \
      --arg branch "$BRANCH" \
      --arg gen "$GEN" \
      --arg commit "$LAST_COMMIT" \
      '{
        hookSpecificOutput: {
          hookEventName: "SessionStart",
          additionalContext: "Git branch: \($branch) | last commit: \($commit) | NixOS gen: \($gen)"
        }
      }'
  '';

  # GPT-6 second opinion (CLAUDE_GPT=1, alias claude-gpt). Codex (gpt-6-astra,
  # read-only sandbox) reviews and advises; Claude verifies and decides.
  # On demand only: nothing is sent to GPT until the user mentions "gpt" in a
  # prompt (e.g. "verifie avec gpt"). The UserPromptSubmit hook then marks the
  # session and the Stop hook reviews the changes at the end of that turn.
  # Shared snapshot: "<content-hash> <path>" for every file that differs from
  # $BASE (the commit HEAD pointed at when the session started, recorded in
  # $STATE/head) plus untracked files, so the Stop hook can tell which files
  # this session changed. Comparing against the session's starting commit
  # rather than the current HEAD keeps changes reviewable after /commit.
  gptSnapshotFn = ''
    snapshot() (
      # git prints repository-relative paths; resolve them from the root, not $CWD
      cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || echo .)" || exit 0
      { ${pkgs.git}/bin/git diff "''${BASE:-HEAD}" --name-only; ${pkgs.git}/bin/git ls-files --others --exclude-standard; } 2>/dev/null \
        | ${pkgs.coreutils}/bin/sort -u | while IFS= read -r f; do
            # A tracked file deleted in the worktree gets a marker instead of a
            # hash, so a deletion shows up as a new snapshot entry and is reviewed.
            if [ -f "$f" ]; then
              printf '%s %s\n' "$(${pkgs.coreutils}/bin/sha256sum < "$f" | ${pkgs.coreutils}/bin/cut -c1-16)" "$f"
            else
              printf 'deleted %s\n' "$f"
            fi
          done
    )
  '';

  gptSessionStartScript = pkgs.writeText "claude-gpt-session-start.sh" ''
    #!/usr/bin/env bash
    [ "''${CLAUDE_GPT:-}" = "1" ] || exit 0
    INPUT=$(${pkgs.coreutils}/bin/cat)
    SESSION=$(${pkgs.jq}/bin/jq -r '.session_id' <<< "$INPUT")
    CWD=$(${pkgs.jq}/bin/jq -r '.cwd // "."' <<< "$INPUT")
    STATE="$HOME/.cache/ask-gpt/session-$SESSION"
    ${pkgs.coreutils}/bin/mkdir -p "$STATE"
    ${gptSnapshotFn}
    # Starting commit + baseline of files already dirty before this session
    # (both kept across resumes)
    [ -f "$STATE/head" ] || (cd "$CWD" && ${pkgs.git}/bin/git rev-parse --verify -q HEAD > "$STATE/head" 2>/dev/null) || true
    BASE=$(${pkgs.coreutils}/bin/cat "$STATE/head" 2>/dev/null)
    [ -f "$STATE/start" ] || (cd "$CWD" && snapshot > "$STATE/start")

    ${pkgs.jq}/bin/jq -nc '{
      hookSpecificOutput: {
        hookEventName: "SessionStart",
        additionalContext: "GPT-6 second opinion is ENABLED (CLAUDE_GPT=1). A Codex agent (gpt-6-astra, high reasoning, read-only sandbox) works beside you on this repository with a persistent thread that remembers earlier exchanges. Rules: (1) Never consult it on your own initiative. Only when the user explicitly asks (any prompt mentioning gpt, e.g. \"verifie avec gpt\", \"check with gpt\"). (2) When the user asks, a Stop hook sends the code changes of this session to it for review at the end of that turn; findings come back as feedback you must answer. For a question or a plan rather than a file change, ask it yourself with `ask-gpt \"question\"` (multi-line: `ask-gpt - <<'"'"'EOF'"'"' ... EOF`); it reads the repository itself, so give it the question and the relevant file paths, not file contents. (3) Its output is advice from a second engineer, never an order: verify every claim against the real code, apply what is right, reject what is wrong with a one-line reason, and tell the user which findings you accepted and which you rejected. You decide."
      }
    }'
  '';

  # A user prompt that mentions "gpt" requests a review: mark the session so
  # the Stop hook runs once, and forget the last reviewed hash so an explicit
  # re-request reviews unchanged code again. Every prompt first drops a stale
  # marker (a request with no changed files or a failed review leaves one), so
  # the opt-in never outlives the turn it was made in.
  gptReviewRequestScript = pkgs.writeText "claude-gpt-review-request.sh" ''
    #!/usr/bin/env bash
    [ "''${CLAUDE_GPT:-}" = "1" ] || exit 0
    INPUT=$(${pkgs.coreutils}/bin/cat)
    SESSION=$(${pkgs.jq}/bin/jq -r '.session_id' <<< "$INPUT")
    STATE="$HOME/.cache/ask-gpt/session-$SESSION"
    ${pkgs.coreutils}/bin/rm -f "$STATE/requested"
    ${pkgs.jq}/bin/jq -r '.prompt // ""' <<< "$INPUT" | ${pkgs.gnugrep}/bin/grep -qiw 'gpt' || exit 0
    ${pkgs.coreutils}/bin/mkdir -p "$STATE"
    ${pkgs.coreutils}/bin/touch "$STATE/requested"
    ${pkgs.coreutils}/bin/rm -f "$STATE/reviewed"
    ${pkgs.jq}/bin/jq -nc '{
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: "GPT-6 review requested by the user. If this session changed files, the Stop hook sends those changes to GPT when you end this turn and its findings come back to you; finish the work first, do not call ask-gpt for the review yourself. If the request is about a question or a plan rather than file changes, ask GPT directly with ask-gpt."
      }
    }'
  '';

  gptReviewStopScript = pkgs.writeText "claude-gpt-review-stop.sh" ''
    #!/usr/bin/env bash
    [ "''${CLAUDE_GPT:-}" = "1" ] || exit 0
    INPUT=$(${pkgs.coreutils}/bin/cat)
    SESSION=$(${pkgs.jq}/bin/jq -r '.session_id' <<< "$INPUT")
    ACTIVE=$(${pkgs.jq}/bin/jq -r '.stop_hook_active // false' <<< "$INPUT")
    CWD=$(${pkgs.jq}/bin/jq -r '.cwd // "."' <<< "$INPUT")
    cd "$CWD" || exit 0
    cd "$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || exit 0
    STATE="$HOME/.cache/ask-gpt/session-$SESSION"
    ${pkgs.coreutils}/bin/mkdir -p "$STATE"
    # On demand: the user asked for a review in this turn (marker set by the
    # UserPromptSubmit hook), or this is the follow-up round after a block.
    [ -f "$STATE/requested" ] || [ "$ACTIVE" = "true" ] || exit 0
    ${gptSnapshotFn}
    # Session starting commit; fall back to HEAD when it is unknown or gone
    # (rebased away, state dir from an older hook version).
    BASE=$(${pkgs.coreutils}/bin/cat "$STATE/head" 2>/dev/null)
    BASE=''${BASE:-HEAD}
    ${pkgs.git}/bin/git rev-parse --verify -q "$BASE^{commit}" >/dev/null 2>&1 || BASE=HEAD
    snapshot > "$STATE/now"
    [ -f "$STATE/start" ] || { ${pkgs.coreutils}/bin/cp "$STATE/now" "$STATE/start"; exit 0; }

    # Files whose content differs from the session baseline, plus baseline
    # paths that vanished from the snapshot entirely: a pre-existing
    # uncommitted change reverted to HEAD, or an untracked file deleted.
    # Those have no diff against HEAD, so they are reported by name.
    ADDED=$(${pkgs.coreutils}/bin/comm -13 <(${pkgs.coreutils}/bin/sort "$STATE/start") <(${pkgs.coreutils}/bin/sort "$STATE/now"))
    VANISHED=$(${pkgs.coreutils}/bin/comm -23 \
      <(${pkgs.coreutils}/bin/cut -d' ' -f2- "$STATE/start" | ${pkgs.coreutils}/bin/sort) \
      <(${pkgs.coreutils}/bin/cut -d' ' -f2- "$STATE/now" | ${pkgs.coreutils}/bin/sort) \
      | ${pkgs.gnused}/bin/sed 's/^/vanished /')
    CHANGED=$(printf '%s\n%s\n' "$ADDED" "$VANISHED" | ${pkgs.gnugrep}/bin/grep .)
    [ -n "$CHANGED" ] || exit 0
    REVIEW_HASH=$(printf '%s' "$CHANGED" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-16)
    [ "$REVIEW_HASH" != "$(${pkgs.coreutils}/bin/cat "$STATE/reviewed" 2>/dev/null)" ] || exit 0

    # At most two review rounds per turn (stop_hook_active = Claude continued after a block)
    if [ "$ACTIVE" = "true" ]; then
      ROUNDS=$(( $(${pkgs.coreutils}/bin/cat "$STATE/rounds" 2>/dev/null || echo 0) + 1 ))
    else
      ROUNDS=1
    fi
    echo "$ROUNDS" > "$STATE/rounds"
    [ "$ROUNDS" -le 2 ] || exit 0

    # The whole prompt is one argv entry (128 KiB limit): diffs get 100 KB,
    # the file lists share the rest. Files whose diff does not fit are named
    # so the reviewer reads them from the repository instead of silently
    # dropping them; the name list itself stops before the limit.
    export LC_ALL=C  # ''${#var} counts bytes
    DIFF=""
    OMITTED=""
    REVERTED=""
    while read -r kind f; do
      [ -n "$f" ] || continue
      if [ "$kind" = "vanished" ]; then
        REVERTED="$REVERTED$f"$'\n'
        continue
      fi
      # Tracked in the base commit or in the index (covers staged deletions, where the
      # path is gone from the index but still in HEAD)
      if ${pkgs.git}/bin/git cat-file -e "$BASE:$f" 2>/dev/null || ${pkgs.git}/bin/git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
        d=$(${pkgs.git}/bin/git diff "$BASE" -- "$f")
      else
        d=$(${pkgs.git}/bin/git diff --no-index -- /dev/null "$f" || true)
      fi
      if [ $(( ''${#DIFF} + ''${#d} )) -le 100000 ]; then
        DIFF="$DIFF$d"$'\n'
      else
        OMITTED="$OMITTED$f"$'\n'
      fi
    done <<< "$CHANGED"

    PROMPT="You are the second engineer reviewing changes that Claude Code just made in this repository. Claude decides; you only report.
    Review the diff below. Read any file in the repository you need for context.
    Report only real problems: bugs, wrong assumptions, security issues, code that contradicts the rest of the codebase, missed edge cases. No style nits, no praise, no summary of the change.
    For each finding: file and line, what is wrong, why, and a concrete fix.
    End with exactly one line: VERDICT: CLEAN or VERDICT: FINDINGS

    $DIFF"
    append_list() {  # $1 = heading, $2 = newline-separated paths; stops at the prompt budget
      [ -n "$2" ] || return 0
      PROMPT="$PROMPT

    $1"
      while IFS= read -r p; do
        [ -n "$p" ] || continue
        if [ $(( ''${#PROMPT} + ''${#p} + 1 )) -gt 120000 ]; then
          PROMPT="$PROMPT
    (list cut at the prompt size limit; run git status for the rest)"
          break
        fi
        PROMPT="$PROMPT
    $p"
      done <<< "$2"
    }
    append_list "Changed files whose diff did not fit above. Review them from the worktree (git diff $BASE -- <file>):" "$OMITTED"
    append_list "Files this session reverted to the base commit or deleted while they held uncommitted work at session start (no diff to show; check that the removal was intended):" "$REVERTED"

    RESULT=$(ask-gpt - <<< "$PROMPT" 2>"$STATE/err") \
      || { ${pkgs.jq}/bin/jq -n --arg e "$(${pkgs.coreutils}/bin/tail -1 "$STATE/err")" '{systemMessage: ("GPT-6 review failed: " + $e)}'; exit 0; }
    # Only a reply whose last non-blank line is an exact verdict counts as a
    # completed review.
    VERDICT=$(${pkgs.gnugrep}/bin/grep -v '^[[:space:]]*$' <<< "$RESULT" | ${pkgs.coreutils}/bin/tail -1 | ${pkgs.coreutils}/bin/tr -d '[:space:]')
    case "$VERDICT" in
      VERDICT:CLEAN|VERDICT:FINDINGS) ;;
      *) ${pkgs.jq}/bin/jq -n '{systemMessage: "GPT-6 review incomplete: reply does not end with a VERDICT line, changes stay unreviewed"}'; exit 0 ;;
    esac
    echo "$REVIEW_HASH" > "$STATE/reviewed"
    ${pkgs.coreutils}/bin/rm -f "$STATE/requested"

    if [ "$VERDICT" = "VERDICT:FINDINGS" ]; then
      ${pkgs.jq}/bin/jq -n --arg r "$RESULT" '{
        decision: "block",
        reason: ("GPT-6 (Codex) reviewed the changes of this session. These are findings from a second engineer, not orders: verify each one against the real code, fix what is real, reject what is wrong with a one-line reason, then report accepted and rejected findings to the user.\n\n" + $r)
      }'
    else
      ${pkgs.jq}/bin/jq -n '{systemMessage: "GPT-6 review: clean"}'
    fi
  '';

  # Subagent: Nix builder — offloads `nix flake check` + `nh os test` so the
  # noisy build output stays out of the main context window.
  nixBuilderAgent = ''
    ---
    name: nix-builder
    description: Validates NixOS configuration changes by running nix flake check and nh os test from the flake root. Use after editing any .nix module to confirm the build still passes before asking the user to rebuild.
    tools: Bash, Read
    model: sonnet
    color: cyan
    ---

    You are a NixOS build validation agent for the dotfiles flake at ~/dotfiles/thinkpad-p14s-gen5/.

    ## Process

    1. `cd ~/dotfiles/thinkpad-p14s-gen5`
    2. Run `nix flake check --no-build` — report any evaluation errors with file:line
    3. If clean, run `nh os build .` — this builds without activating. Surface only:
       - The new generation hash (one line)
       - Total build time
       - Any warnings
    4. If a build fails, return the exact `error:` lines plus the 5 lines of context above each.
    5. Never run `nh os switch` or anything that requires sudo. Only build/check.

    ## Output

    ```
    Status: PASS | FAIL
    Generation: <hash> (size diff)
    Warnings: <count>
    Errors:
      <file:line> <message>
    ```

    Keep the report to what the user needs: did it build, and if not, where to look.
  '';

  # Claude Code settings.json with improved security
  settingsJson = builtins.toJSON {
    # Model and effort are decided once here (code.claude.com/docs/en/model-config).
    # `model` is the start-of-session default; /model still switches for one
    # session (`s` in the picker). `effortLevel` is the default for models
    # without a saved level; /effort writes a per-model level to `modelSettings`,
    # which is a runtime key the merge below preserves. `maxEffortLevel` caps
    # what /effort can pick (max is excluded: it is the most expensive level).
    model = "fable";
    effortLevel = "high";
    maxEffortLevel = "xhigh";
    # One-hour prompt cache for the main conversation. Within plan usage a
    # subscription already gets 1h; this keeps it when the session draws on
    # extra-usage credits (where Claude Code would drop to 5m), at the higher
    # 1h cache-write rate. Subagents keep the 5m default.
    promptCacheTtl = "1h";
    # Allowlist derived from the declared servers (plus the Stripe plugin
    # server and the blender project server), so the list cannot drift from
    # the ~/.claude.json defaults below. Once a serverCommand entry exists,
    # every stdio server must match one exactly, and once a serverUrl entry
    # exists, every remote server must match one: a server added at runtime
    # with `claude mcp add` or a project .mcp.json is blocked silently until
    # it is listed here. Built-in servers (Claude in Chrome, ide) are exempt.
    allowedMcpServers =
      lib.mapAttrsToList (
        _: s:
        if s ? url then { serverUrl = s.url; } else { serverCommand = [ s.command ] ++ (s.args or [ ]); }
      ) mcpServersDefaults
      ++ [
        { serverUrl = "https://mcp.stripe.com"; }
        { serverCommand = [ "uvx" "blender-mcp" ]; }
      ];
    # Alt-screen renderer with virtualized scrollback. The default main-screen
    # renderer leaks stale frames into terminal scrollback on every window
    # resize (duplicated/overlapping text after resizing Ghostty).
    tui = "fullscreen";
    # Voice mode (push-to-talk dictation). This is reasserted by the activation
    # merge below, while session-owned keys such as /effort stay writable.
    # mode = "hold" | "tap". (voiceEnabled is a deprecated alias of voice.enabled.)
    voice = {
      enabled = true;
      # "tap" (tap to start, tap to stop+submit) instead of "hold": hold-to-talk
      # needs the terminal to report key-release events (Kitty keyboard protocol);
      # in a plain terminal session Space arrives as raw chars, so hold never fires.
      mode = "tap";
    };
    # Statusline: model, effort, git branch, context %, session cost
    statusLine = {
      type = "command";
      command = "$HOME/.claude/statusline.sh";
    };
    env = {
      # Nix owns the binary; block the auto-updater so it can't shadow it with a
      # mutable ~/.local install.
      DISABLE_UPDATES = "1";
      # BASH_MAX_TIMEOUT_MS removed: the documented default is now 600000 (10min),
      # the exact value we used to set.
      # NOTE: DISABLE_TELEMETRY intentionally NOT set — it shares the GrowthBook
      # feature-flag code path and silently hides gated features (Opus 1M ctx, etc.).
      # Everything else is left at Claude Code defaults: the previous performance
      # tweaks (ENABLE_PROMPT_CACHING_1H, output-token cap, autocompact override)
      # interacted with extended thinking and produced "Invalid tool parameters"
      # cascades. The cache TTL is now the promptCacheTtl setting above, which is
      # what a subscription session already runs with inside plan usage.
      # CLAUDE_CODE_ENABLE_TELEMETRY (OpenTelemetry) not set: no collector on this
      # machine; cache hit ratio is on the statusline and in /usage instead.
    };
    permissions = {
      allow = [
        # ── Web documentation ──
        "WebSearch"
        "WebFetch(domain:github.com)"
        "WebFetch(domain:api.github.com)"
        "WebFetch(domain:raw.githubusercontent.com)"
        "WebFetch(domain:wiki.hypr.land)"
        "WebFetch(domain:wiki.hyprland.org)"
        "WebFetch(domain:wiki.nixos.org)"
        "WebFetch(domain:discourse.nixos.org)"
        "WebFetch(domain:search.nixos.org)"
        "WebFetch(domain:nix.dev)"
        "WebFetch(domain:nixos.org)"
        "WebFetch(domain:nixos.wiki)"
        "WebFetch(domain:docs.anthropic.com)"
        "WebFetch(domain:docs.claude.com)"
        "WebFetch(domain:code.claude.com)"
        "WebFetch(domain:support.claude.com)"
        "WebFetch(domain:deepwiki.com)"
        "WebFetch(domain:ghostty.org)"
        "WebFetch(domain:docs.z.ai)"
        "WebFetch(domain:opencode.ai)"
        "WebFetch(domain:bigmodel.cn)"
        "WebFetch(domain:open.bigmodel.cn)"
        "WebFetch(domain:platform.minimax.io)"
        "WebFetch(domain:platform.minimaxi.com)"
        # ── fal.ai ──
        "WebFetch(domain:fal.ai)"
        "WebFetch(domain:queue.fal.run)"
        "WebFetch(domain:rest.alpha.fal.run)"
        # ── System info (read-only) ──
        "Bash(pgrep:*)"
        "Bash(ps:*)"
        "Bash(pstree:*)"
        "Bash(ip addr:*)"
        "Bash(ip route:*)"
        "Bash(resolvectl status:*)"
        "Bash(systemctl status:*)"
        "Bash(systemctl list-timers:*)"
        "Bash(systemctl --user status:*)"
        "Bash(systemctl --user list-timers:*)"
        "Bash(systemctl --failed:*)"
        "Bash(systemctl --user --failed:*)"
        "Bash(journalctl:*)"
        "Bash(dmesg:*)"
        "Bash(printenv:*)"
        "Bash(nmcli connection:*)"
        # ── Hyprland ──
        "Bash(hyprctl getoption:*)"
        "Bash(hyprctl options:*)"
        "Bash(hyprctl version:*)"
        "Bash(hyprctl clients:*)"
        "Bash(hyprctl monitors:*)"
        "Bash(hyprctl devices:*)"
        "Bash(hyprctl reload:*)"
        # ── Nix (read/check/build) ──
        "Bash(nix-instantiate:*)"
        "Bash(nix flake check:*)"
        "Bash(nix flake lock:*)"
        "Bash(nix search:*)"
        "Bash(nix hash to-sri:*)"
        "Bash(nix hash convert:*)"
        "Bash(nix eval:*)"
        "Bash(nix build:*)"
        "Bash(nix-prefetch-url:*)"
        "Bash(nh os switch:*)"
        # ── Git (no push/commit) ──
        "Bash(git fetch:*)"
        "Bash(git status:*)"
        "Bash(git log:*)"
        "Bash(git diff:*)"
        "Bash(git branch:*)"
        "Bash(git add:*)"
        "Bash(git mv:*)"
        # ── Desktop tools (read-only) ──
        "Bash(uwsm check:*)"
        "Bash(uwsm list:*)"
        "Bash(Hyprland --help)"
        "Bash(hyprlauncher --help:*)"
        "Bash(waybar --version)"
        "Bash(ghostty +show-config --default --docs)"
        "Bash(ghostty +list-keybinds --default)"
        "Bash(ghostty +list-actions)"
        "Bash(cliphist list:*)"
        "Bash(makoctl list:*)"
        "Bash(amixer:*)"
        "Bash(xdg-mime query:*)"
        # ── Hardware info ──
        "Bash(fwupdmgr get-devices:*)"
        "Bash(fwupdmgr get-updates:*)"
        # ── Dev tools ──
        "Bash(runpodctl:*)"
        "Bash(arkcli:*)"
        "Bash(gh search:*)"
        "Bash(gh api:*)"
        "Bash(mpv:*)"
        "Bash(ask-gpt:*)"
        "Bash(ask-gemini:*)"
        # ── MCP servers (whole server = every tool it exposes) ──
        # Allow rules resolve before the auto mode classifier, so these stop
        # "denied by auto mode" on routine MCP calls (browser navigation,
        # Neon queries, GitHub, ...). Destructive tools are caught by the ask
        # rules below, which also run before the classifier.
        "mcp__claude-in-chrome"
        "mcp__chrome-devtools"
        "mcp__playwright"
        "mcp__nixos"
        "mcp__neon"
        "mcp__github"
        "mcp__cloudflare-ai-gateway"
        "mcp__workos"
        "mcp__plugin_stripe_stripe"
        "mcp__terraform"
        "mcp__headroom"
        "mcp__blender"
        "mcp__reva"
        "mcp__rea"
      ];
      # Always prompt for these, in every mode (ask rules beat allow rules and
      # the auto mode classifier). Server allow rules above would otherwise
      # approve them silently.
      ask = [
        # ── Arbitrary code execution / writes behind whole-server allows ──
        "mcp__playwright__browser_run_code_unsafe"
        "mcp__blender__execute_blender_code"
        "mcp__reva__run-script"
        "mcp__reva__write-script"
        "mcp__reva__edit-script"
        # REA: these launch an arbitrary local binary or Electron app to record it
        "mcp__rea__capture_process_scenario"
        "mcp__rea__capture_electron_scenario"
        "mcp__github__push_files"
        "mcp__github__create_or_update_file"
        "mcp__github__delete_file"
        "mcp__github__merge_pull_request"
        # ── Neon: destructive / irreversible ──
        "mcp__neon__delete_project"
        "mcp__neon__delete_branch"
        "mcp__neon__delete_postgres_database"
        "mcp__neon__delete_postgres_role"
        "mcp__neon__delete_postgres_endpoint"
        "mcp__neon__delete_snapshot"
        "mcp__neon__delete_storage_bucket"
        "mcp__neon__delete_storage_object"
        "mcp__neon__delete_storage_objects_by_prefix"
        "mcp__neon__delete_function"
        "mcp__neon__delete_functions_custom_domain"
        "mcp__neon__delete_trigger"
        "mcp__neon__delete_data_api"
        "mcp__neon__delete_auth_user"
        "mcp__neon__delete_auth_oauth_provider"
        "mcp__neon__delete_auth_trusted_domain"
        "mcp__neon__disable_auth"
        "mcp__neon__reset_from_parent"
        "mcp__neon__restore_snapshot"
        "mcp__neon__finalize_branch_restore"
        "mcp__neon__complete_database_migration"
        "mcp__neon__revoke_credential"
        "mcp__neon__rotate_credential"
        "mcp__neon__reset_postgres_role_password"
        # Arbitrary SQL (DROP/DELETE/UPDATE) and tuning/EXPLAIN ANALYZE, which execute the statement
        "mcp__neon__run_sql"
        "mcp__neon__run_sql_transaction"
        "mcp__neon__complete_query_tuning"
        "mcp__neon__explain_sql_statement"
        # ── Terraform: runs change real infrastructure ──
        "mcp__terraform__create_run"
        # ── WorkOS: every write goes through mutate ──
        "mcp__workos__mutate"
        # ── Stripe: every POST/PATCH/PUT/DELETE goes through one tool ──
        # (refunds, subscription cancels, invoice finalize, dispute updates).
        # Stripe adds its own confirmation link for refunds and outbound
        # payments, but the other writes land with no second step.
        "mcp__plugin_stripe_stripe__stripe_api_write"
      ];
      # Path rule syntax (per docs/en/permissions): gitignore spec. Directory
      # contents need a trailing /**; a single leading / anchors at the
      # SETTINGS FILE (~/.claude/), NOT the filesystem root, so absolute paths
      # must start with //. These rules also cover Bash file commands
      # (cat/head/tail/sed) that Claude Code recognizes.
      deny = [
        # ── Environment files (secrets) ──
        "Read(~/.env)"
        "Read(~/.env.local)"
        "Read(~/.env.production)"
        "Read(~/.env.development)"
        "Read(~/.env.staging)"
        "Read(~/.env.test)"
        "Read(~/.envrc)"
        # ── Credential directories ──
        "Read(~/.ssh/**)"
        "Read(~/.aws/**)"
        "Read(~/.gnupg/**)"
        "Read(~/.password-store/**)"
        "Read(~/.kube/**)"
        "Read(~/.docker/**)"
        "Read(~/.config/containers/**)"
        "Read(~/.config/gcloud/**)"
        "Read(~/.azure/**)"
        "Read(~/.helm/**)"
        "Read(~/.local/share/keyrings/**)"
        # ── Sensitive config files ──
        "Read(~/.netrc)"
        "Read(~/.npmrc)"
        "Read(~/.pypirc)"
        "Read(~/.gitconfig-secrets)"
        "Read(~/.config/waybar/.env)" # Wallet zpub keys
        "Read(~/.config/sops/**)" # age private key (sops-nix)
        # ── History files (may contain secrets) ──
        "Read(~/.bash_history)"
        "Read(~/.zsh_history)"
        "Read(~/.python_history)"
        # ── System sensitive files (/etc/passwd dropped: world-readable,
        # no hashes, needed for routine debugging) ──
        "Read(//etc/shadow)"
        "Read(//etc/sudoers)"
        "Read(//etc/ssh/**)"
        # ── Edit restrictions (Edit rules cover all file-editing tools,
        # including Write; Write(path) rules are not matched) ──
        "Edit(~/.env)"
        "Edit(~/.env.local)"
        "Edit(~/.ssh/**)"
        "Edit(~/.aws/**)"
        "Edit(~/.gnupg/**)"
        "Edit(~/.password-store/**)"
        "Edit(~/.kube/**)"
        "Edit(~/.docker/**)"
        "Edit(~/.config/containers/**)"
        "Edit(~/.config/sops/**)"
        "Edit(~/.netrc)"
        "Edit(~/.npmrc)"
        "Edit(//etc/**)"
      ];
      defaultMode = "default";
      # Keep Claude on the normal permission model. The bwrap sandbox is not
      # configured here because it is brittle on this NixOS/Home Manager setup.
      disableBypassPermissionsMode = "disable";
    };
    # Auto mode classifier context. Only ~/.claude/settings.json is read for
    # this block (project settings are ignored), and the activation merge below
    # makes it Nix-owned: a /auto-mode-setup run scoped to one project used to
    # replace the trusted repo with a hardcoded path, so every other repo and
    # every browser navigation was "outside the environment" and denied.
    # "$defaults" keeps the built-in entries (trusted repo = the repo Claude
    # started in, and its remotes); the lines below add machine-wide context.
    autoMode = {
      environment = [
        "$defaults"
        "**Organization**: personal machine of a single developer (GitHub user marceloeatworld). Primary use: software development, NixOS dotfiles, and browser automation/research with Claude in Chrome and Playwright"
        "**Source control**: github.com/marceloeatworld and every repo under it; local-only repos under ~/codes and ~/dotfiles are the user's own work"
        "**Cloud provider(s)**: Cloudflare (Pages, Workers, AI Gateway), Neon Postgres, WorkOS, Stripe, HCP Terraform, RunPod, Google Cloud"
        "**Key internal services**: the user's configured MCP servers (claude-in-chrome, chrome-devtools, playwright, neon, github, cloudflare-ai-gateway, workos, stripe, terraform, nixos, headroom, blender, reva, rea; stripe comes from the official stripe plugin). Opening any website the user asks for in Claude in Chrome or Playwright is routine browser automation, not exfiltration"
        "**Trusted internal domains**: github.com, api.github.com, mcp.neon.tech, console.neon.tech, api.cloudflare.com, dash.cloudflare.com, mcp.workos.com, mcp.stripe.com, dashboard.stripe.com, app.terraform.io, api.runpod.io"
        "**CI/CD deploy targets**: Cloudflare Pages via wrangler (raizes-do-alentejo project and its pages.dev previews)"
        "**Org-specific CLIs**: nix, nh, hyprctl, gh, wrangler, runpodctl, arkcli"
        "**Sensitive data locations & audiences**: genealogy research reports under ~/codes/genealogie/reports contain personal data about identifiable individuals; share only with the user"
      ];
      allow = [
        "$defaults"
        "Bash(wrangler pages deploy:*)"
        "Bash(wrangler pages publish:*)"
      ];
      soft_deny = [
        "$defaults"
        "Bash(wrangler pages project delete:*)"
      ];
    };
    # Plugins
    enabledPlugins = {
      # LSP - language servers
      # Disabled: each Claude session can spawn its own tsserver per workspace,
      # which duplicates VS Code/terminal language-server memory on large repos.
      "typescript-lsp@claude-plugins-official" = false;
      "pyright-lsp@claude-plugins-official" = true;
      "clangd-lsp@claude-plugins-official" = true;
      "csharp-lsp@claude-plugins-official" = true;
      "gopls-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "lua-lsp@claude-plugins-official" = true;
      # Code quality
      "code-simplifier@claude-plugins-official" = true;
      # security-guidance disabled: its PreToolUse hook produces constant false
      # positives in unrelated projects (flags writes that reference shell-exec
      # APIs and redirects to a utility path that only exists inside the Claude
      # Code source tree). Local protect_sensitive_files.py already covers the
      # real secret-protection use case.
      "security-guidance@claude-code-plugins" = false;
      # Workflow
      "commit-commands@claude-code-plugins" = true;
      "feature-dev@claude-code-plugins" = true;
      "frontend-design@claude-code-plugins" = true;
      # Platform skills
      # Ships the official Stripe MCP server (https://mcp.stripe.com) plus the
      # Stripe skills. It registers as plugin:stripe:stripe, so its tools are
      # prefixed mcp__plugin_stripe_stripe__ in the permission rules above.
      "stripe@claude-plugins-official" = true;
      # Duplicated by ai-skills.nix, which copies the same official upstream
      # skill repos to Claude, Forge, OpenCode, and Codex.
      "pg@aiguide" = false;
      "postgres-best-practices@supabase-agent-skills" = false;
      "cloudflare@cloudflare" = false;
    };
    # Marketplaces: the valid key is extraKnownMarketplaces (installedMarketplaces
    # does not exist in the settings schema and was silently ignored).
    extraKnownMarketplaces = {
      "supabase-agent-skills".source = {
        source = "github";
        repo = "supabase/agent-skills";
      };
      "cloudflare".source = {
        source = "github";
        repo = "cloudflare/skills";
      };
      "aiguide".source = {
        source = "github";
        repo = "timescale/pg-aiguide";
      };
    };
    # MCP servers: NOT configured here. settings.json has no mcpServers key
    # (schema-confirmed); user-scope servers live in ~/.claude.json, merged by
    # the writeClaudeUserMcpServers activation below.
    enableAllProjectMcpServers = false;
    enabledMcpjsonServers = [ "blender" ];
    # Git attribution (replaces deprecated includeCoAuthoredBy)
    attribution = {
      commit = "";
      pr = "";
      sessionUrl = false; # no Claude-Session trailer from cloud/Remote Control sessions
    };
    # Privacy and hardening (see code.claude.com/docs/en/settings-reference)
    feedbackSurveyRate = 0; # never show the session quality survey
    feedbackDrafts = "off"; # Claude cannot queue feedback drafts
    disableClaudeAiConnectors = true; # MCP servers are declared here, not fetched from claude.ai
    isolatePeerMachines = true; # approval before SendMessage reaches a session on another machine
    # disableSkillShellExecution intentionally NOT set: it applies to every
    # skill and command, official plugins included, so /commit and
    # /commit-push-pr lost their inline `!git status` / `!git diff` context.
    # Hooks — defense in depth + productivity
    hooks = {
      # Security: block access to sensitive files and dangerous commands
      PreToolUse = [
        {
          matcher = "Read|Edit|Write|Bash";
          hooks = [
            {
              type = "command";
              command = "python3 $HOME/.claude/hooks/protect_sensitive_files.py";
            }
          ];
        }
      ];
      # Productivity: auto-validate nix syntax after edits
      PostToolUse = [
        {
          matcher = "Edit|Write";
          hooks = [
            {
              type = "command";
              # exit 2 is the only PostToolUse exit code whose stderr is fed back
              # to Claude (exit 1 is verbose-only). continueOnBlock is not a real
              # hook field and was removed.
              command = ''
                jq -r '.tool_input.file_path // empty' | { read -r f; [ -z "$f" ] || [[ "$f" != *.nix ]] || [ ! -f "$f" ] || nix-instantiate --parse "$f" >/dev/null || exit 2; }
              '';
              timeout = 30;
            }
          ];
        }
        # Auto-inject core principles into any CLAUDE.md
        {
          matcher = "Edit|Write";
          hooks = [
            {
              type = "command";
              command = "python3 $HOME/.claude/hooks/ensure_claudemd_principle.py";
              timeout = 5;
            }
          ];
        }
      ];
      # Productivity: desktop notification when Claude needs attention
      Notification = [
        {
          matcher = "idle_prompt|permission_prompt";
          hooks = [
            {
              type = "command";
              command = "notify-send 'Claude Code' 'Needs your attention' --icon=dialog-information -t 5000";
            }
          ];
        }
      ];
      # Productivity: distinct notification when Claude finishes a turn
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "notify-send 'Claude Code' 'Task completed' --icon=emblem-default -t 3000";
            }
            # GPT-6 review gate (no-op unless CLAUDE_GPT=1 and the user asked
            # for it this turn): blocks the stop with findings, Claude answers
            # them, at most two rounds per turn.
            {
              type = "command";
              command = "$HOME/.claude/hooks/gpt-review-stop.sh";
              timeout = 900;
            }
          ];
        }
      ];
      # GPT-6 second opinion (no-op unless CLAUDE_GPT=1): a prompt mentioning
      # "gpt" (e.g. "verifie avec gpt") arms the Stop-hook review for this turn.
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "$HOME/.claude/hooks/gpt-review-request.sh";
              timeout = 5;
            }
          ];
        }
      ];
      # Re-inject critical NixOS invariants before compaction summarizes them away
      PreCompact = [
        {
          hooks = [
            {
              type = "command";
              command = "$HOME/.claude/hooks/pre-compact.sh";
              timeout = 5;
            }
          ];
        }
      ];
      # Inject current git branch + last NixOS generation at session start
      SessionStart = [
        {
          hooks = [
            {
              type = "command";
              command = "$HOME/.claude/hooks/session-start.sh";
              timeout = 5;
            }
            # GPT-6 second opinion (no-op unless CLAUDE_GPT=1): baseline
            # snapshot of dirty files + usage rules injected into context.
            {
              type = "command";
              command = "$HOME/.claude/hooks/gpt-session-start.sh";
              timeout = 30;
            }
          ];
        }
      ];
    };
  };
  settingsDefaultsFile = pkgs.writeText "claude-settings-defaults.json" settingsJson;

  # User-scope MCP servers. Claude Code reads these from ~/.claude.json
  # (settings.json ignores an mcpServers key). Merged by an activation script
  # so servers added at runtime with `claude mcp add` are preserved.
  # Persistent Playwright profile per workspace, like upstream @playwright/mcp
  # (mcp-<browser>-<hash of root path>). The nixpkgs wrapper runs a throwaway
  # profile unless PLAYWRIGHT_MCP_USER_DATA_DIR is set, and one shared
  # directory would make concurrent sessions in different repositories fight
  # over Chromium's profile lock. Claude Code starts stdio servers in the
  # session's working directory.
  playwrightMcp = pkgs.writeShellScript "playwright-mcp-workspace" ''
    export PLAYWRIGHT_MCP_USER_DATA_DIR="$HOME/.cache/playwright-mcp/$(printf '%s' "$PWD" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -c1-7)"
    exec ${pkgs.playwright-mcp}/bin/playwright-mcp "$@"
  '';

  # GitHub MCP bearer token read from the decrypted sops file at connection
  # time (headersHelper), so it also works when Claude Code is launched from
  # somewhere that never ran the zsh secret loader (VS Code, desktop entry).
  # Exit 1 with no output when the secret is empty: no "Bearer " header.
  githubMcpHeaders = pkgs.writeShellScript "github-mcp-headers" ''
    TOKEN_FILE="${config.sops.secrets.github_personal_access_token.path}"
    [ -s "$TOKEN_FILE" ] || exit 1
    ${pkgs.jq}/bin/jq -n --rawfile t "$TOKEN_FILE" '{ Authorization: ("Bearer " + ($t | rtrimstr("\n"))) }'
  '';

  # Google Developer Knowledge MCP: the Gemini API key goes in the
  # X-Goog-Api-Key header (never a query parameter). Its Google Cloud project
  # must have the Developer Knowledge API enabled and the key's API
  # restrictions must include it; see the mcpServersDefaults entry.
  developerKnowledgeMcpHeaders = pkgs.writeShellScript "developer-knowledge-mcp-headers" ''
    KEY_FILE="${config.sops.secrets.gemini_api_key.path}"
    [ -s "$KEY_FILE" ] || exit 1
    ${pkgs.jq}/bin/jq -n --rawfile k "$KEY_FILE" '{ "X-Goog-Api-Key": ($k | rtrimstr("\n")) }'
  '';

  # ReVa headless (Ghidra MCP server, nixpkgs mcp-reva). PyGhidra boots the
  # base Ghidra from GHIDRA_INSTALL_DIR and the nixpkgs Java patch loads the
  # ReVa extension from NIX_GHIDRAHOME (withExtensions bundles only the
  # extensions, no Ghidra tree). PyGhidra needs `java` on PATH to run
  # LaunchSupport. Ephemeral Ghidra projects go to TMPDIR: /tmp is a tmpfs
  # here and a firmware image project would swap it into zram. /var/tmp is on
  # disk; ~/.cache is not an option, Ghidra rejects path elements starting
  # with a dot.
  ghidraWithReva = pkgs.ghidra.withExtensions (p: [ p.reva ]);
  revaMcp = pkgs.writeShellScript "mcp-reva-nix" ''
    export GHIDRA_INSTALL_DIR="${pkgs.ghidra}/lib/ghidra"
    export NIX_GHIDRAHOME="${ghidraWithReva}/lib/ghidra/Ghidra"
    export PATH="${pkgs.openjdk21}/bin:$PATH"
    export TMPDIR="/var/tmp"
    exec ${pkgs.mcp-reva}/bin/mcp-reva "$@"
  '';

  # REA's Ghidra provider accepts exactly application.version 12.1.4 and a
  # JDK 21 (GhidraInstallation.js: SUPPORTED_GHIDRA_VERSION). The pinned
  # nixpkgs ghidra-bin is 12.1.2, so this is the same prebuilt derivation
  # with the 12.1.4 release zip. The GUI Ghidra firejail and ReVa stay on
  # pkgs.ghidra; only the rea MCP server sees this tree.
  ghidraForRea = pkgs.ghidra-bin.overrideAttrs (old: {
    version = "12.1.4";
    src = pkgs.fetchzip {
      url = "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_12.1.4_build/ghidra_12.1.4_PUBLIC_20260921.zip";
      hash = "sha256-ZD4Vs1i7BMvrneAbAiOc7F9iBj64Rbom+PaVO//TzK8=";
    };
  });
  reaMcp = pkgs.writeShellScript "mcp-rea-nix" ''
    export GHIDRA_INSTALL_DIR="${ghidraForRea}/lib/ghidra"
    export JAVA_HOME="${pkgs.openjdk21.home}"
    export TMPDIR="/var/tmp"
    exec ${pkgs.rea}/bin/rea mcp "$@"
  '';

  # stdio servers come from nixpkgs where available: no `uvx`/`pnpm dlx`
  # network fetch at session start, and the version is pinned by the flake.
  # `alwaysLoad` only on the two-tool nixos server: it forces a server's whole
  # tool list into context at every session, which for github/playwright is
  # dozens of tools that ToolSearch loads on demand anyway.
  # The stripe server is NOT declared here: the stripe plugin ships it
  # (plugin:stripe:stripe). A user-scope server with the same name overrides
  # the plugin one and renames its tools to mcp__stripe__*, which silently
  # bypassed the mcp__plugin_stripe_stripe__ ask rules above.
  mcpServersDefaultsFile = pkgs.writeText "claude-mcp-servers-defaults.json" (builtins.toJSON mcpServersDefaults);
  mcpServersDefaults = {
    # Real-time NixOS knowledge: 130K+ packages, 23K+ options, home-manager,
    # nix-darwin, flakes, NixHub history, wiki.nixos.org. ~1K tokens overhead.
    "nixos" = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      alwaysLoad = true;
    };
    # Native streamable HTTP: Claude Code performs the OAuth flow itself and
    # persists the token. The former `pnpm dlx mcp-remote` wrapper re-fetched
    # the newest release on every launch, and each version keeps its tokens in
    # its own ~/.mcp-auth/mcp-remote-<version>/ directory, so the browser
    # consent screen reappeared at every session start.
    "cloudflare-ai-gateway" = {
      type = "http";
      url = "https://ai-gateway.mcp.cloudflare.com/mcp";
    };
    # Bundled Chromium from the nix store; see playwrightMcp above.
    "playwright" = {
      command = "${playwrightMcp}";
    };
    # Not in nixpkgs; pnpm dlx caches the package between launches.
    "chrome-devtools" = {
      command = "pnpm";
      args = [ "dlx" "chrome-devtools-mcp" ];
    };
    # Registered at user scope by `headroom wrap claude` (alias claude-hr) as
    # well; declared here so the entry is the same whichever wrote it last.
    # Tools only do work while the headroom proxy is running (headroom-claude).
    "headroom" = {
      command = "headroom";
      args = [ "mcp" "serve" ];
    };
    # Neon Postgres: streamable HTTP with OAuth handled by Claude Code (/mcp).
    "neon" = {
      type = "http";
      url = "https://mcp.neon.tech/mcp";
    };
    # Medusa docs search for the medusa-dev skills (ai-skills.nix). Streamable
    # HTTP behind OAuth (401 + resource_metadata), authenticate once via /mcp.
    # Upstream plugin name kept so the skills' "MedusaDocs MCP" prose matches.
    "MedusaDocs" = {
      type = "http";
      url = "https://docs.medusajs.com/mcp";
    };
    # WorkOS Management: streamable HTTP, OAuth via the dashboard login
    # (authenticate once via /mcp). Secrets are stripped from responses.
    "workos" = {
      type = "http";
      url = "https://mcp.workos.com/mcp";
    };
    # nixpkgs binary instead of `docker run hashicorp/terraform-mcp-server`:
    # podman's docker shim refused the unqualified image name (no
    # unqualified-search registries configured), so the server never started.
    # TFE_TOKEN is inherited from the shell (sops); registry/provider docs
    # work without it, HCP Terraform tools need it.
    "terraform" = {
      command = "${pkgs.terraform-mcp-server}/bin/terraform-mcp-server";
      args = [ "stdio" ];
    };
    # Ghidra decompiler/analysis for Claude (import, decompile, rename, xrefs,
    # diff, PyGhidra scripts). Starts Ghidra headless on first use (~10 s);
    # the GUI Ghidra firejail (--net=none) stays untouched. See revaMcp above.
    "reva" = {
      command = "${revaMcp}";
    };
    # REA is a separate app-analysis server. Its Ghidra provider gets its
    # own Ghidra 12.1.4 tree through reaMcp above.
    "rea" = {
      command = "${reaMcp}";
    };
    # GitHub's remote server does not support OAuth dynamic client
    # registration, so Claude Code's own OAuth flow fails with "Incompatible
    # auth server". The documented path is a PAT bearer header, produced by
    # githubMcpHeaders above from the sops secret.
    "github" = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
      headersHelper = "${githubMcpHeaders}";
    };
    # Google developer docs (Gemini API, Live API, pricing, Android, Cloud)
    # as MCP, for development only: never on an app's live path. Fetching
    # those pages directly fails, they are JavaScript rendered. Reuses the
    # gemini_api_key sops secret; one-time setup on that key's project P:
    #   gcloud services enable developerknowledge.googleapis.com --project=P
    #   gcloud services api-keys update KEY_NAME \
    #     --api-target=service=generativelanguage.googleapis.com \
    #     --api-target=service=developerknowledge.googleapis.com
    # Without it tools/call answers "API keys are not supported by this API".
    "google-developer-knowledge" = {
      type = "http";
      url = "https://developerknowledge.googleapis.com/mcp";
      headersHelper = "${developerKnowledgeMcpHeaders}";
    };
  };

  # Agent: Code Reviewer (general purpose)
  codeReviewerAgent = ''
    ---
    name: code-reviewer
    description: Review a finished chunk of code for bugs, security, performance, and alignment with project standards. Use after a feature, refactor, or endpoint is complete, or when the user asks for a code review.
    model: opus
    color: blue
    ---

    You are an elite code reviewer. Your role is to provide thorough, constructive code reviews that ensure quality, maintainability, and security across any language or framework.

    ## Review Process

    1. **Identify changes**: Run `git diff --name-only HEAD` to find modified files. Focus on recent changes, not the entire codebase.

    2. **Read CLAUDE.md**: Check for project-specific standards, patterns, and conventions.

    3. **Analyze each file** against these criteria:

    **Security (CRITICAL):**
    - Hardcoded credentials, API keys, tokens
    - Injection vulnerabilities (SQL, XSS, command, path traversal)
    - Missing input validation at system boundaries
    - Authentication/authorization gaps
    - Sensitive data in logs or error messages

    **Correctness (HIGH):**
    - Logic errors, off-by-one, race conditions
    - Unhandled edge cases and error paths
    - Missing null/undefined checks where needed
    - Incorrect API usage or type mismatches

    **Performance (MEDIUM):**
    - N+1 queries, unnecessary allocations in hot paths
    - Missing indexes for frequent query patterns
    - Blocking operations that should be async
    - Memory leaks (unclosed resources, growing collections)

    **Maintainability (MEDIUM):**
    - Functions > 50 lines, files > 500 lines
    - Nesting depth > 4 levels
    - Duplicated logic that should be abstracted
    - Unclear naming or misleading comments

    **Consistency (LOW):**
    - Deviations from existing codebase patterns
    - Inconsistent error handling style
    - Mixed conventions within the same file

    4. **Output format:**

    ```
    ## Code Review

    ### Critical Issues
    - [file:line] Description — suggested fix

    ### Important
    - [file:line] Description — suggested fix

    ### Suggestions
    - [file:line] Description

    ### Good
    - What was done well
    ```

    Be direct. Every finding must include file, line, and a concrete fix. Skip categories with no findings. Never approve code with security vulnerabilities.
  '';

  # Agent: SEO Analyzer
  seoAnalyzerAgent = ''
    ---
    name: seo-analyzer
    description: SEO analysis and optimization specialist. Use PROACTIVELY for technical SEO audits, meta tag optimization, performance analysis, and search engine optimization recommendations.
    tools: Read, Write, WebFetch, Grep, Glob
    model: opus
    maxTurns: 30
    ---

    You are an SEO analysis specialist focused on technical SEO audits, content optimization, and search engine performance improvements.

    ## Focus Areas

    - Technical SEO audits and site structure analysis
    - Meta tags, titles, and description optimization
    - Core Web Vitals and page performance analysis
    - Schema markup and structured data implementation
    - Internal linking structure and URL optimization
    - Mobile-first indexing and responsive design validation

    ## Approach

    1. Comprehensive technical SEO assessment
    2. Content quality and keyword optimization analysis
    3. Performance metrics and Core Web Vitals evaluation
    4. Mobile usability and responsive design testing
    5. Structured data validation and enhancement
    6. Competitive analysis and benchmarking

    ## Output

    - Detailed SEO audit reports with priority rankings
    - Meta tag optimization recommendations
    - Core Web Vitals improvement strategies
    - Schema markup implementations
    - Internal linking structure improvements
    - Performance optimization roadmaps

    Focus on actionable recommendations that improve search rankings and user experience. Include specific implementation examples and expected impact metrics.
  '';

  # Agent: TypeScript Expert
  typescriptExpertAgent = ''
    ---
    name: typescript-expert
    description: Write, refactor, review, or optimize TypeScript with a focus on clean, secure, efficient code. Use for new TypeScript modules, cleanup of duplicated logic, security review of TypeScript, or performance work.
    model: opus
    color: green
    ---

    You are a senior TypeScript architect. Simplicity and discipline are the foundations of maintainable software.

    ## Core Philosophy

    You live by two unbreakable principles:

    **KISS (Keep It Simple, Stupid)**: Every line of code is a liability. You write the simplest solution that correctly solves the problem. You resist over-engineering, premature optimization, and clever tricks that sacrifice readability. When reviewing your own code, you ask: "Would a junior developer understand this in 30 seconds?"

    **DRY (Don't Repeat Yourself)**: Duplication is the root of maintenance hell. You identify patterns and abstract them appropriately--but never prematurely. You understand that the wrong abstraction is worse than duplication, so you wait until you see the pattern three times before extracting.

    ## Security-First Mindset

    You treat every input as hostile and every output as potentially sensitive:

    - **Input Validation**: Always validate and sanitize inputs at system boundaries. Use TypeScript's type system as your first line of defense, but never trust runtime data.
    - **Output Encoding**: Escape outputs appropriately for their context (HTML, SQL, shell, etc.)
    - **Secrets Management**: Never hardcode secrets, API keys, or credentials. Flag any you encounter.
    - **Injection Prevention**: Parameterize queries, avoid eval/Function constructors, sanitize dynamic code paths
    - **Authentication/Authorization**: Verify permissions at every entry point, not just the UI layer
    - **Data Exposure**: Minimize data in responses, logs, and error messages. Never log sensitive data.
    - **Dependency Awareness**: Be cautious of third-party packages; prefer well-maintained, audited libraries

    When you see potential security issues, you don't just fix them--you explain the vulnerability and its potential impact.

    ## Efficiency Principles

    You optimize for the right things in the right order:

    1. **Correctness first**: Broken code that runs fast is worthless
    2. **Readability second**: Code is read 10x more than it's written
    3. **Performance third**: Only optimize what you've measured

    When you do optimize:
    - Choose appropriate data structures (Map/Set over Array for lookups)
    - Avoid unnecessary allocations in hot paths
    - Use lazy evaluation and short-circuit logic
    - Leverage TypeScript's type system to catch errors at compile time, not runtime
    - Consider memory footprint for large datasets
    - Prefer async/await patterns that don't block the event loop

    ## TypeScript Excellence

    You leverage TypeScript's full power:

    - **Strict mode**: `strict: true`, because it catches whole classes of bugs at compile time
    - **Precise types**: no `any`. Use `unknown` when the type is truly unknown, then narrow
    - **Type inference**: Let TypeScript infer when it's clearer; annotate when it aids readability
    - **Discriminated unions**: Model state machines and variants correctly
    - **Utility types**: Use `Partial`, `Required`, `Pick`, `Omit`, `Record` appropriately
    - **Generics**: Use them for reusable code, but don't over-generalize
    - **Type guards**: Write custom type guards for runtime type checking
    - **Const assertions**: Use `as const` for literal types and immutable structures

    ## Code Quality Standards

    **Naming**:
    - Variables/functions: camelCase, descriptive verbs for functions (`getUserById`, not `user`)
    - Classes/Types/Interfaces: PascalCase
    - Constants: SCREAMING_SNAKE_CASE for true constants, camelCase for const variables
    - Booleans: prefix with is/has/can/should (`isValid`, `hasPermission`)

    **Structure**:
    - Functions do one thing and do it well
    - Short functions that do one thing
    - Early returns to reduce nesting
    - Guard clauses at the top of functions
    - Group related code, separate concerns

    **Error Handling**:
    - Use typed errors with discriminated unions when appropriate
    - Never swallow errors silently
    - Provide actionable error messages
    - Consider the error recovery path

    **Comments**:
    - Code should be self-documenting; comments explain "why", not "what"
    - JSDoc for public APIs
    - TODO/FIXME with ticket references

    ## Your Working Process

    1. **Understand first**: Before writing code, ensure you understand the requirements. Ask clarifying questions if needed.

    2. **Plan the approach**: Think through the solution before coding. Consider edge cases, error states, and security implications.

    3. **Implement incrementally**: Build in small, testable pieces. Each piece should be correct before moving on.

    4. **Review your work**: Before presenting code, review it for:
       - Security vulnerabilities
       - Performance issues
       - Code duplication
       - Unnecessary complexity
       - Missing error handling
       - Type safety gaps

    5. **Explain your decisions**: When presenting solutions, briefly explain key architectural decisions, especially around security and trade-offs.

    ## Response Format

    When writing code:
    - Provide complete, working implementations
    - Include necessary imports
    - Add brief inline comments for non-obvious logic
    - Highlight any security considerations
    - Note any assumptions you've made
    - Suggest tests for critical paths if appropriate

    When reviewing code:
    - Identify issues by severity (Critical/High/Medium/Low)
    - Provide specific fixes, not just criticism
    - Acknowledge what's done well
    - Focus on security and maintainability issues first

    You are not just a code generator--you are a mentor who helps developers write better, safer, more maintainable TypeScript code.
  '';

in
{
  # Install Claude Code from nixpkgs
  home.packages = with pkgs; [
    claude-code # Official CLI package
  ];

  # Disable Claude Code's built-in auto-updater before it starts.
  # Settings.json's env block is too late: the migration logic reads process.env at
  # startup, before settings.json is parsed, and re-installs itself to
  # ~/.local/share/claude/versions/, shadowing the Nix binary via ~/.local/bin/claude.
  # DISABLE_UPDATES (v2.1.118+) blocks the full update path; we set it in both shell
  # env (here) and the in-app env (settings.json) for belt and suspenders.
  home.sessionVariables = {
    DISABLE_UPDATES = "1";
    CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE = "false";
    # Claude Code's temp files (screenshots, scratchpads, sockets) default to
    # /tmp, which is a 14 GB tmpfs here. On 2026-09-05 old sessions had left
    # 12 GB of PNGs and node_modules in it, all resident in RAM/zram, which
    # starved the machine and ended in a kernel OOM freeze. Keep them on disk.
    CLAUDE_CODE_TMPDIR = "${config.home.homeDirectory}/.cache/claude-tmp";
  };

  # Private (0700) directory required by CLAUDE_CODE_TMPDIR; entries older than
  # 7 days are removed by systemd-tmpfiles-clean.
  systemd.user.tmpfiles.rules = [
    "d %h/.cache/claude-tmp 0700 - - 7d"
  ];

  # Each rebuild: remove the mutable version payload the auto-updater drops in
  # ~/.local/share/claude. Do NOT rm ~/.local/bin/claude here: this activation
  # sorts after linkGeneration, which (with force = true below) has already
  # restored the declarative Nix symlink, so deleting it would leave the path
  # missing and trip Claude Code's "native install not found at ~/.local/bin/claude"
  # diagnostic on every launch.
  home.activation.purgeClaudeLocalInstall = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.local/share/claude" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -rf "$HOME/.local/share/claude"
    fi

    # The root config is ~/.claude.json (in $HOME, not in ~/.claude/) -- that's
    # where Claude Code writes `installMethod`. Normalize it to "native" while
    # keeping updates disabled, because ~/.local/bin/claude is a Home Manager
    # symlink to the Nix package rather than a self-updating native install.
    ROOT_STATE="$HOME/.claude.json"
    for STATE_FILE in "$ROOT_STATE" "$HOME"/.claude/*.json; do
      [ -f "$STATE_FILE" ] || continue
      if [ "$STATE_FILE" != "$ROOT_STATE" ]; then
        ${pkgs.gnugrep}/bin/grep -q '"installMethod"' "$STATE_FILE" 2>/dev/null || continue
      fi
      TMP=$(${pkgs.coreutils}/bin/mktemp)
      if ${pkgs.jq}/bin/jq '.installMethod = "native" | .autoUpdates = false | .autoUpdatesProtectedForNative = true' "$STATE_FILE" > "$TMP" 2>/dev/null; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$STATE_FILE"
      else
        ${pkgs.coreutils}/bin/rm -f "$TMP"
      fi
    done
  '';

  # Claude Code's native diagnostics expect this path to exist and be in PATH.
  # Home Manager owns the symlink; the mutable version payload stays purged.
  home.file.".local/bin/claude" = {
    source = "${pkgs.claude-code}/bin/claude";
    force = true;
  };

  # Claude in Chrome native host wrapper. Claude Code generates this file as
  # `exec claude --chrome-native-host`, and the host names its bridge socket
  # /tmp/claude-mcp-browser-bridge-$USER/<pid>.sock. Brave runs under firejail
  # with its own PID namespace, so the host gets the same PID, and the same
  # socket path, on every Brave launch. Claude Code keys its socket pool by
  # path and never reconnects a path it already knows, so every Brave restart
  # left running sessions at "Browser extension is not connected" until a
  # manual /mcp reconnect. Burning a random number of PIDs before starting the
  # host gives each launch a fresh socket path, which the pool picks up on the
  # next tool call. The host must be a child (no exec): the wrapper's own PID
  # is already assigned before the loop runs.
  # Home Manager owns the symlink; Claude Code's attempt to rewrite it fails
  # on the read-only store and is only logged.
  home.file.".claude/chrome/chrome-native-host" = {
    executable = true;
    force = true;
    text = ''
      #!/bin/sh
      # Claude in Chrome native host wrapper, managed by Home Manager.
      # See modules/home/programs/claude-code.nix for why the PID loop exists.
      n=$(( $(${pkgs.coreutils}/bin/od -An -N2 -tu2 /dev/urandom) % 512 ))
      while [ "$n" -gt 0 ]; do
        ( : )
        n=$((n - 1))
      done
      ${pkgs.claude-code}/bin/claude --chrome-native-host
    '';
  };

  # Deploy global CLAUDE.md (applies to all projects)
  home.file.".claude/CLAUDE.md" = {
    text = ''
      # Global Instructions

      ## Principles

      ### 1. Think before coding
      Don't assume. Don't hide confusion. State ambiguity explicitly. Present multiple interpretations rather than silently picking one. Push back if a simpler approach exists. Stop and ask rather than guess.

      ### 2. Simplicity first
      No features beyond what was asked. No abstractions for single-use code. No "flexibility" that wasn't requested. No error handling for impossible scenarios. The test: would a senior engineer say this is overcomplicated? If yes, rewrite it.
      Before new code, climb: not needed > already in repo > stdlib > native platform > installed dep > one line > minimal new code.
      Bug fix: grep every caller of the function, fix the shared function once, not the one path the report names.

      ### 3. Surgical changes
      Don't "improve" adjacent code. Don't refactor things that aren't broken. Match the existing style even if you'd do it differently. If you notice unrelated dead code, mention it, don't delete it. Every changed line should trace directly to the request.

      ### 4. Goal-driven execution
      Transform "fix the bug" into "write a test that reproduces it, then make it pass." Transform "add validation" into "write tests for invalid inputs, then make them pass." Give it success criteria and watch it loop until done.

      ## User Workflow

      - Treat prompts such as `analyse`, `verifie`, `lecture seul`, `sans modifier`, `ne change rien`, and `li mon plan` as read-only audit requests. Do not edit files until the user clearly approves implementation.
      - When the user switches to `corrige`, `ok va y`, `fait`, or another clear implementation request, make the focused change and verify it.
      - Preserve user work. Check the current diff before editing, and never revert unrelated changes.
      - Use the real source of truth: code, config, logs, generated output, and runtime state. Do not answer from assumptions when the repo or system can be checked.
      - If screenshots, logs, or runtime output contradict a written assumption, trust the observed evidence first.
      - Always answer in English, even when the user writes in French. Everything must be in English everywhere, always: responses, code comments, user-facing strings, notifications, documentation, and commit messages. Never use French.

      ## Communication

      - Do not use emojis in responses or in files.
      - Do not use the em dash character.
      - Do not add Co-Authored-By Claude in commits or PR descriptions.
      - Be direct. Skip preamble, caveats, and trailing summaries.
      - Match response length to the task. A one-line question gets a one-line answer.

      ## Verification

      After completing changes, run the project's verification command (build, type check, tests) before reporting the task done. If you cannot run it, say so explicitly rather than claiming success.

      **Exception for long builds:** When the verification step is a long build (e.g. NixOS `nh os test`, full image builds, anything taking more than a couple of minutes), skip it for cosmetic/visual changes (theme files, Lua configs, prompts, docs, keybindings) as long as a faster check passes (syntax check, `nix flake check`, type check). State explicitly that the full build was not run, and let the user trigger the rebuild.

      **Do not create tests** unless the user asks for them. Do not invent test files, fixtures, or harnesses to "validate" a change.

      ## Secrets and Sensitive Paths

      Never read, display, or suggest writing to: `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.env*`, `~/.netrc`, `~/.config/sops`. Permission deny rules and a PreToolUse hook block them as well; do not work around either.

      ## When Stuck

      If blocked twice on the same error, stop and ask rather than guessing a third approach. Diagnose the root cause; do not use destructive shortcuts (`--no-verify`, `git reset --hard`) to make an obstacle go away.

      ## Always-On Skills

      The two skills below are active in every session without being invoked. Both files come from upstream commits pinned by rev and hash in `ai-skills.nix`.

      - Caveman runs at the `full` level by default. The language rule above wins over the skill's "reply in the user's language" rule: answer in English even when the user writes in French.
      - Skill files are imported after this line, so their rules apply on top of everything above.

      @~/.claude/skills/i-have-adhd/SKILL.md
      @~/.claude/skills/caveman/SKILL.md
    '';
  };

  # Claude writes session preferences such as /effort back into settings.json.
  # A Home Manager symlink points at the read-only Nix store, and Claude's atomic
  # writer follows that symlink when creating its temporary file. Keep the file
  # mutable, but reapply the declarative defaults on every activation. The merge
  # order lets Nix-owned keys win while preserving extra runtime keys.
  home.activation.writeClaudeMutableSettings = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    SETTINGS="$HOME/.claude/settings.json"
    DEFAULTS="${settingsDefaultsFile}"

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/.claude"
    TMP=$(${pkgs.coreutils}/bin/mktemp "$HOME/.claude/settings.json.tmp.XXXXXX")

    # del(): keys we used to set that are not in the settings schema (or are
    # deprecated aliases); drop them from the live file so they don't linger.
    if [ -f "$SETTINGS" ] && ${pkgs.jq}/bin/jq -e . "$SETTINGS" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq -s '.[1] * .[0] | del(.mcpServers, .installedMarketplaces, .switchModelsOnFlag, .voiceEnabled, .disableSkillShellExecution, .env.BASH_MAX_TIMEOUT_MS)' "$DEFAULTS" "$SETTINGS" > "$TMP"
    else
      ${pkgs.coreutils}/bin/cp "$DEFAULTS" "$TMP"
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$SETTINGS"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 600 "$SETTINGS"
  '';

  # Merge declarative user-scope MCP servers into ~/.claude.json, where Claude
  # Code actually reads them. Nix-owned server names win; servers added at
  # runtime with `claude mcp add` (e.g. headroom) are preserved.
  home.activation.writeClaudeUserMcpServers = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    ROOT_STATE="$HOME/.claude.json"
    MCP_DEFAULTS="${mcpServersDefaultsFile}"

    TMP=$(${pkgs.coreutils}/bin/mktemp "$HOME/.claude.json.tmp.XXXXXX")
    if [ -f "$ROOT_STATE" ] && ${pkgs.jq}/bin/jq -e . "$ROOT_STATE" >/dev/null 2>&1; then
      ${pkgs.jq}/bin/jq --slurpfile defs "$MCP_DEFAULTS" \
        '.mcpServers = ((.mcpServers // {})
           | with_entries(select(.key | in($defs[0]) | not))) + $defs[0]' "$ROOT_STATE" > "$TMP"
    else
      ${pkgs.jq}/bin/jq -n --slurpfile defs "$MCP_DEFAULTS" '{ mcpServers: $defs[0] }' > "$TMP"
    fi
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$ROOT_STATE"
  '';

  # Deploy custom agents
  home.file.".claude/agents/code-reviewer.md" = {
    text = codeReviewerAgent;
  };

  home.file.".claude/agents/seo-analyzer.md" = {
    text = seoAnalyzerAgent;
  };

  home.file.".claude/agents/typescript-expert.md" = {
    text = typescriptExpertAgent;
  };

  # Skills are now centralized in ai-skills.nix (clone once, distribute to Claude/Forge/OpenCode)

  # Update all plugin marketplaces on each rebuild (git pull)
  # This keeps Cloudflare, Supabase, and other marketplace skills up to date
  home.activation.updatePluginMarketplaces = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    MARKET_DIR="$HOME/.claude/plugins/marketplaces"
    if [ -d "$MARKET_DIR" ]; then
      for dir in "$MARKET_DIR"/*/; do
        [ -d "''${dir}.git" ] || continue
        $DRY_RUN_CMD ${pkgs.git}/bin/git -C "''${dir}" pull --quiet 2>/dev/null || true
      done
    fi
  '';

  home.file.".claude/agents/nix-builder.md" = {
    text = nixBuilderAgent;
  };

  # Deploy hooks
  home.file.".claude/hooks/protect_sensitive_files.py" = {
    source = protectSensitiveFilesHook;
    executable = true;
  };

  home.file.".claude/hooks/ensure_claudemd_principle.py" = {
    source = ensureClaudeMdPrincipleHook;
    executable = true;
  };

  home.file.".claude/hooks/pre-compact.sh" = {
    source = preCompactScript;
    executable = true;
  };

  home.file.".claude/hooks/session-start.sh" = {
    source = sessionStartScript;
    executable = true;
  };

  home.file.".claude/hooks/gpt-session-start.sh" = {
    source = gptSessionStartScript;
    executable = true;
  };

  home.file.".claude/hooks/gpt-review-request.sh" = {
    source = gptReviewRequestScript;
    executable = true;
  };

  home.file.".claude/hooks/gpt-review-stop.sh" = {
    source = gptReviewStopScript;
    executable = true;
  };

  # Statusline script (referenced by settings.json statusLine.command)
  home.file.".claude/statusline.sh" = {
    source = statuslineScript;
    executable = true;
  };
}
