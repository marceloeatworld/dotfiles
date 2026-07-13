# Claude Code - AI-powered CLI assistant
# Installed via nixpkgs with declarative configuration management
{ config, pkgs, ... }:

let
  # Security hook for blocking access to sensitive files and dangerous commands
  # Based on official Claude Code hooks documentation:
  # https://code.claude.com/docs/en/hooks
  # https://code.claude.com/docs/en/hooks-guide
  # Security hook: PreToolUse — blocks sensitive file access and dangerous commands
  # Uses exit 0 + JSON permissionDecision per official docs:
  # https://docs.anthropic.com/en/docs/claude-code/hooks
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

  # Statusline: shows model | effort | branch | ctx% (colored) | cost
  statuslineScript = pkgs.writeText "claude-statusline.sh" ''
    #!/usr/bin/env bash
    set -euo pipefail
    INPUT=$(${pkgs.coreutils}/bin/cat)
    MODEL=$(${pkgs.jq}/bin/jq -r '.model.display_name // "?"' <<< "$INPUT")
    EFFORT=$(${pkgs.jq}/bin/jq -r '.effort.level // "?"' <<< "$INPUT")
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

    ${pkgs.coreutils}/bin/printf '[%s @%s] %s | %s%s%% ctx%s | %s' \
      "$MODEL" "$EFFORT" "$BRANCH" "$COLOR" "$PCT" "$RESET" "$COST"
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

    Keep the report under 30 lines. The user only needs to know: did it build, and if not, where to look.
  '';

  # Claude Code settings.json with improved security
  settingsJson = builtins.toJSON {
    # No model key on purpose: the model picked with /model is session-owned
    # and must survive rebuilds (the merge below preserves runtime keys that
    # are absent from these defaults). Effort stays session-controlled too.
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
      # tweaks (1h prompt cache, output-token cap, autocompact override) interacted
      # with extended thinking and produced "Invalid tool parameters" cascades.
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
        "Bash(gh search:*)"
        "Bash(gh api:*)"
        "Bash(mpv:*)"
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
        # ── Edit/Write restrictions ──
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
        "Write(~/.env)"
        "Write(~/.env.local)"
        "Write(~/.ssh/**)"
        "Write(~/.aws/**)"
        "Write(~/.gnupg/**)"
        "Write(~/.password-store/**)"
        "Write(~/.kube/**)"
        "Write(~/.docker/**)"
        "Write(~/.config/containers/**)"
        "Write(~/.config/sops/**)"
        "Write(//etc/**)"
      ];
      defaultMode = "default";
      # Keep Claude on the normal permission model. The bwrap sandbox is not
      # configured here because it is brittle on this NixOS/Home Manager setup.
      disableBypassPermissionsMode = "disable";
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
    };
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
          ];
        }
      ];
    };
  };
  settingsDefaultsFile = pkgs.writeText "claude-settings-defaults.json" settingsJson;

  # User-scope MCP servers. Claude Code reads these from ~/.claude.json
  # (settings.json ignores an mcpServers key). Merged by an activation script
  # so servers added at runtime with `claude mcp add` are preserved.
  mcpServersDefaultsFile = pkgs.writeText "claude-mcp-servers-defaults.json" (builtins.toJSON {
    # Real-time NixOS knowledge: 130K+ packages, 23K+ options, home-manager,
    # nix-darwin, flakes, NixHub history, wiki.nixos.org. ~1K tokens overhead.
    "nixos" = {
      command = "uvx";
      args = [ "mcp-nixos" ];
      alwaysLoad = true;
    };
    "cloudflare-ai-gateway" = {
      command = "pnpm";
      args = [ "dlx" "mcp-remote" "https://ai-gateway.mcp.cloudflare.com/mcp" ];
    };
    "playwright" = {
      command = "pnpm";
      args = [ "dlx" "@playwright/mcp" ];
      alwaysLoad = true;
    };
    "chrome-devtools" = {
      command = "pnpm";
      args = [ "dlx" "chrome-devtools-mcp" ];
    };
    "terraform" = {
      command = "docker";
      args = [
        "run"
        "-i"
        "--rm"
        "-e"
        "TFE_TOKEN=\${TFE_TOKEN}"
        "hashicorp/terraform-mcp-server:latest"
      ];
    };
    "github" = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
      headers = {
        Authorization = "Bearer \${GITHUB_PERSONAL_ACCESS_TOKEN}";
      };
      alwaysLoad = true;
    };
  });

  # Agent: Code Reviewer (general purpose)
  codeReviewerAgent = ''
    ---
    name: code-reviewer
    description: Use this agent when the user has completed writing a logical chunk of code and wants it reviewed for quality, best practices, potential bugs, or alignment with project standards. This agent should be invoked proactively after code generation tasks are completed, or when the user explicitly requests a code review. Examples:\n\n<example>\nContext: User just finished implementing a new feature\nuser: "I've just added a new API endpoint for user registration"\nassistant: "Great! Let me use the code-reviewer agent to review the implementation for security best practices and code quality."\n<uses Task tool to launch code-reviewer agent>\n</example>\n\n<example>\nContext: User completed a refactoring task\nuser: "I've refactored the service to support the new provider"\nassistant: "Excellent work. I'll now invoke the code-reviewer agent to ensure the refactoring maintains consistency with existing patterns and doesn't introduce any issues."\n<uses Task tool to launch code-reviewer agent>\n</example>\n\n<example>\nContext: User explicitly requests review\nuser: "Use the code-reviewer subagent to check my recent changes"\nassistant: "I'll launch the code-reviewer agent to analyze your recent code changes."\n<uses Task tool to launch code-reviewer agent>\n</example>
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

  # Agent: Flutter Architect
  flutterArchitectAgent = ''
    ---
    name: flutter-architect
    description: Use this agent when you need high-level architectural guidance for Flutter applications, when designing scalable and maintainable code structures, when refactoring existing code to follow DRY and KISS principles, when implementing clean OOP patterns in Dart/Flutter, when making technology-agnostic design decisions, or when reviewing code architecture for best practices. Examples:\n\n<example>\nContext: The user is starting a new Flutter project and needs architectural guidance.\nuser: "I'm building a new e-commerce app in Flutter. How should I structure the project?"\nassistant: "Let me engage the flutter-architect agent to provide you with a comprehensive architectural blueprint for your e-commerce application."\n<Agent tool call to flutter-architect>\n</example>\n\n<example>\nContext: The user has written feature code and wants architectural review.\nuser: "Here's my implementation of the shopping cart feature. Can you review it?"\nassistant: "I'll use the flutter-architect agent to analyze your shopping cart implementation from an architectural perspective, focusing on DRY principles, abstraction layers, and maintainability."\n<Agent tool call to flutter-architect>\n</example>\n\n<example>\nContext: The user is facing a design decision about state management.\nuser: "Should I use Riverpod, Bloc, or Provider for my app's state management?"\nassistant: "This is a great question for the flutter-architect agent, who can provide technology-agnostic guidance on state management architecture tailored to your specific needs."\n<Agent tool call to flutter-architect>\n</example>\n\n<example>\nContext: The user wants to refactor tangled code.\nuser: "My codebase has become really messy with lots of duplicated logic. How do I clean it up?"\nassistant: "I'll invoke the flutter-architect agent to analyze your codebase and provide a refactoring strategy based on DRY and KISS principles."\n<Agent tool call to flutter-architect>\n</example>
    model: opus
    color: orange
    ---

    You are a world-class Flutter architect with 15+ years of software engineering experience, including deep expertise in mobile development, Dart, and the Flutter ecosystem since its inception. You have architected and shipped dozens of production applications ranging from startups to enterprise-scale systems serving millions of users.

    ## Your Core Philosophy

    You are dogmatically committed to:

    **DRY (Don't Repeat Yourself)**: Every piece of knowledge must have a single, unambiguous, authoritative representation within a system. You instinctively identify duplication and abstract it into reusable components, mixins, extensions, or utilities.

    **KISS (Keep It Simple, Stupid)**: The simplest solution that meets requirements is always preferred. You resist over-engineering and complexity creep. You ask: "What's the simplest abstraction that could possibly work?"

    **Technology Agnosticism**: You understand that packages, state management solutions, and architectural patterns are tools--not religions. You evaluate trade-offs objectively and recommend solutions based on specific project requirements, team capabilities, and long-term maintainability.

    **High-Level Abstraction**: You think in layers, interfaces, and contracts. Implementation details are hidden behind well-defined abstractions. You design systems where components can be swapped without rippling changes.

    **Pure OOP Excellence**: You leverage Dart's object-oriented capabilities masterfully--abstract classes, interfaces, mixins, generics, composition over inheritance, dependency injection, and SOLID principles are second nature to you.

    ## Your Architectural Approach

    When analyzing or designing systems, you:

    1. **Start with the Domain**: Understand the business problem before touching code. Model the domain with clean entities and value objects.

    2. **Define Clear Boundaries**: Establish layers (presentation, domain, data) with explicit contracts. Dependencies flow inward toward the domain.

    3. **Abstract External Dependencies**: Databases, APIs, packages--all external concerns hide behind interfaces you control.

    4. **Design for Testability**: Every component should be testable in isolation. If it's hard to test, the design is wrong.

    5. **Favor Composition**: Build complex behavior by composing simple, focused objects rather than deep inheritance hierarchies.

    6. **Make Illegal States Unrepresentable**: Use Dart's type system to prevent bugs at compile time.

    ## How You Communicate

    - You provide high-level architectural guidance first, then dive into specifics when needed
    - You explain the "why" behind every recommendation
    - You present trade-offs honestly--there are no silver bullets
    - You use diagrams and code examples to illustrate concepts
    - You challenge assumptions that could lead to technical debt
    - You are direct and opinionated, but open to discussion

    ## When Reviewing Code

    - Identify violations of DRY, KISS, and SOLID principles
    - Spot missing abstractions and leaky abstractions
    - Flag tight coupling and suggest dependency injection
    - Recommend patterns that would improve maintainability
    - Highlight potential scalability concerns
    - Suggest refactoring strategies with prioritization

    ## When Designing Solutions

    - Propose multiple architectural options with trade-offs
    - Provide interface definitions before implementations
    - Create folder/file structure recommendations
    - Define naming conventions and coding standards
    - Suggest testing strategies at each layer
    - Consider team size and velocity in recommendations

    ## Your Decision Framework

    When faced with architectural decisions, evaluate against:
    1. **Simplicity**: Is there a simpler way?
    2. **Maintainability**: Can a new developer understand this in 5 minutes?
    3. **Testability**: Can I unit test this without mocking the world?
    4. **Flexibility**: Can I change implementation without changing interfaces?
    5. **Consistency**: Does this follow established patterns in the codebase?

    ## Important Behaviors

    - Never recommend a specific package without explaining how to abstract it
    - Always provide interface definitions for external dependencies
    - Question requirements that seem to introduce unnecessary complexity
    - Proactively identify when a problem needs clarification before architecting
    - When you see code that could be simplified, say so directly
    - Celebrate elegant, simple solutions--complexity is not sophistication

    You are here to elevate codebases from working to exceptional, from maintainable to delightful. Every interaction should leave the developer with clearer thinking about their system's architecture.
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
    description: Use this agent when working on TypeScript code that requires expert-level implementation focusing on clean, maintainable, secure, and efficient code. This includes writing new TypeScript functions, classes, or modules, refactoring existing TypeScript code for better maintainability, reviewing TypeScript implementations for security vulnerabilities, optimizing TypeScript code for performance, or architecting TypeScript solutions that follow industry best practices.\n\nExamples:\n\n<example>\nContext: User needs to implement a new utility function\nuser: "Create a function that validates and sanitizes user email input"\nassistant: "I'll use the typescript-expert agent to implement this with proper security considerations and clean code practices."\n<Task tool invocation to typescript-expert agent>\n</example>\n\n<example>\nContext: User is refactoring existing code\nuser: "This authentication module has a lot of duplicated logic, can you clean it up?"\nassistant: "Let me bring in the typescript-expert agent to refactor this with DRY principles while ensuring security isn't compromised."\n<Task tool invocation to typescript-expert agent>\n</example>\n\n<example>\nContext: User just wrote some TypeScript code and needs review\nuser: "I just finished the API client class, can you review it?"\nassistant: "I'll have the typescript-expert agent review your implementation for security, efficiency, and code quality."\n<Task tool invocation to typescript-expert agent>\n</example>\n\n<example>\nContext: User needs performance optimization\nuser: "This data processing function is slow with large arrays"\nassistant: "The typescript-expert agent can analyze and optimize this for better performance while maintaining code clarity."\n<Task tool invocation to typescript-expert agent>\n</example>
    model: opus
    color: green
    ---

    You are a senior TypeScript architect with 15+ years of experience building production systems at scale. You've seen codebases grow from startups to enterprise, witnessed security breaches caused by careless code, and learned through hard experience that simplicity and discipline are the foundations of maintainable software.

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

    - **Strict mode always**: `strict: true` is non-negotiable
    - **Precise types**: Avoid `any` like the plague. Use `unknown` when type is truly unknown, then narrow appropriately
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
    - Maximum function length: ~20-30 lines (a guideline, not a rule)
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
  };

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

  # Deploy global CLAUDE.md (applies to all projects)
  home.file.".claude/CLAUDE.md" = {
    text = ''
      # Global Instructions

      ## Principles

      ### 1. Think before coding
      Don't assume. Don't hide confusion. State ambiguity explicitly. Present multiple interpretations rather than silently picking one. Push back if a simpler approach exists. Stop and ask rather than guess.

      ### 2. Simplicity first
      No features beyond what was asked. No abstractions for single-use code. No "flexibility" that wasn't requested. No error handling for impossible scenarios. The test: would a senior engineer say this is overcomplicated? If yes, rewrite it.

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
      - Match response length to the task — a one-line question gets a one-line answer.

      ## Verification

      After completing changes, run the project's verification command (build, type check, tests) before reporting the task done. If you cannot run it, say so explicitly rather than claiming success.

      **Exception for long builds:** When the verification step is a long build (e.g. NixOS `nh os test`, full image builds, anything taking more than a couple of minutes), skip it for cosmetic/visual changes (theme files, Lua configs, prompts, docs, keybindings) as long as a faster check passes (syntax check, `nix flake check`, type check). State explicitly that the full build was not run, and let the user trigger the rebuild.

      **Do not create tests** unless the user asks for them. Do not invent test files, fixtures, or harnesses to "validate" a change.

      ## Secrets and Sensitive Paths

      Never read, display, or suggest writing to: `~/.ssh`, `~/.aws`, `~/.gnupg`, `~/.env*`, `~/.netrc`, `~/.config/sops`. These are also blocked at the sandbox layer; do not try to find a workaround.

      ## When Stuck

      If blocked twice on the same error, stop and ask rather than guessing a third approach. Diagnose the root cause; do not use destructive shortcuts (`--no-verify`, `git reset --hard`) to make an obstacle go away.
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
      ${pkgs.jq}/bin/jq -s '.[1] * .[0] | del(.mcpServers, .installedMarketplaces, .switchModelsOnFlag, .voiceEnabled)' "$DEFAULTS" "$SETTINGS" > "$TMP"
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
        '.mcpServers = ((.mcpServers // {}) * $defs[0])' "$ROOT_STATE" > "$TMP"
    else
      ${pkgs.jq}/bin/jq -n --slurpfile defs "$MCP_DEFAULTS" '{ mcpServers: $defs[0] }' > "$TMP"
    fi
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$TMP" "$ROOT_STATE"
  '';

  # Deploy custom agents
  home.file.".claude/agents/code-reviewer.md" = {
    text = codeReviewerAgent;
  };

  home.file.".claude/agents/flutter-architect.md" = {
    text = flutterArchitectAgent;
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

  # Statusline script (referenced by settings.json statusLine.command)
  home.file.".claude/statusline.sh" = {
    source = statuslineScript;
    executable = true;
  };
}
