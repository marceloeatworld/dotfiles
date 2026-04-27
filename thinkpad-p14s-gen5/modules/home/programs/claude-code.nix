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
  # PostToolUse hook: auto-inject core principle into any CLAUDE.md created by Claude
  ensureClaudeMdPrincipleHook = pkgs.writeText "ensure_claudemd_principle.py" ''
    #!/usr/bin/env python3
    """
    Claude Code PostToolUse Hook — Ensure Core Principle in CLAUDE.md

    After any Write or Edit on a CLAUDE.md file, checks if the
    "Research the codebase before editing" principle is present.
    If missing, prepends it automatically.
    """
    import sys
    import json
    import os

    PRINCIPLE_MARKER = "Research the codebase before editing"
    PRINCIPLE_BLOCK = """## Core Principle

    **Research the codebase before editing. Never change code you haven't read.**

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

    Complements permissions.deny (literal paths) with pattern-based matching.
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

    # Crypto/key extensions
    SENSITIVE_EXTENSIONS = frozenset({
        'pem', 'key', 'p12', 'pfx', 'crt', 'cer', 'der',
        'keystore', 'jks', 'gpg', 'asc', 'pgp',
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
        'htpasswd', 'shadow', 'passwd', 'sudoers',
        '.bash_history', '.zsh_history', '.python_history',
        '.node_repl_history', '.psql_history', '.mysql_history',
    })

    # File name prefixes (only checked for non-code files)
    SENSITIVE_PREFIXES = (
        '.env', 'secret', 'credential', 'token',
        'password', 'apikey', 'api_key', 'private',
    )

    # Directory names (single path component match)
    SENSITIVE_DIRS = frozenset({
        '.ssh', '.gnupg', '.pgp',
        '.aws', '.azure', '.gcloud',
        '.kube', '.docker', '.helm',
        '.password-store',
        'secrets', 'credentials',
        'sops',
    })

    # Multi-component directory paths (matched as substrings of full path)
    SENSITIVE_PATHS = (
        '/.config/gcloud/',
        '/.config/containers/',
        '/.config/sops/',
        '/.local/share/keyrings/',
        '/.config/waybar/.env',
    )

    # Dangerous bash patterns
    DANGEROUS_COMMANDS = (
        'rm -rf /', 'rm -rf ~', 'rm -rf $HOME', 'rm -rf /*',
        'mkfs.', 'dd if=', ':(){:|:&};:',
        'chmod 777', 'chmod -R 777',
        'cat ~/.ssh', 'cat ~/.aws', 'cat ~/.gnupg',
        'cat /etc/shadow', 'cat /etc/passwd',
        'cat ~/.bash_history', 'cat ~/.zsh_history',
        'cat ~/.netrc', 'cat ~/.npmrc',
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

        # Detect reading sensitive dirs via cat/less/head/tail
        read_cmds = ('cat ', 'less ', 'head ', 'tail ')
        for d in SENSITIVE_DIRS:
            if d in cmd and any(r in cmd for r in read_cmds):
                deny(f"reading from sensitive directory '{d}'")

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

  # Claude Code settings.json with improved security
  settingsJson = builtins.toJSON {
    env = {
      # Model overrides — force 1M context for all tiers
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "claude-sonnet-4-6[1m]";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "claude-sonnet-4-6[1m]";
      # Output and context
      CLAUDE_CODE_MAX_OUTPUT_TOKENS = "64000";
      CLAUDE_AUTOCOMPACT_PCT_OVERRIDE = "85";  # compact earlier (default 95%)
      # Bash timeouts — NixOS builds need longer than default 10s
      BASH_DEFAULT_TIMEOUT_MS = "60000";   # 60s default
      BASH_MAX_TIMEOUT_MS = "600000";      # 10min max (nix builds)
      # UI
      CLAUDE_CODE_NO_FLICKER = "1";
      # Stability
      CLAUDE_ENABLE_STREAM_WATCHDOG = "1";
      CLAUDE_STREAM_IDLE_TIMEOUT_MS = "600000";
      # Effort level — env var has highest precedence (overrides /effort, settings.json, CLI flags)
      # Docs: https://code.claude.com/docs/en/model-config (section "Adjust effort level")
      # Valid: low, medium, high, xhigh (Opus 4.7 only), max
      CLAUDE_CODE_EFFORT_LEVEL = "max";
      # Privacy
      DISABLE_TELEMETRY = "1";
      DISABLE_ERROR_REPORTING = "1";
      # Note: Auto-updater is automatically disabled on NixOS (read-only /nix/store)
      # Updates are handled via: nix flake update && rebuild
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
        "WebFetch(domain:deepwiki.com)"
        "WebFetch(domain:ghostty.org)"
        "WebFetch(domain:clerk.com)"
        "WebFetch(domain:docs.z.ai)"
        "WebFetch(domain:opencode.ai)"
        "WebFetch(domain:hermes-agent.nousresearch.com)"
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
        "Bash(hyprctl dispatch:*)"
        "Bash(hyprctl keyword:*)"
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
        "Bash(hermes config:*)"
        "Bash(mpv:*)"
        # ── Plugin scripts ──
        "Bash(${config.home.homeDirectory}/.claude/plugins/cache/claude-code-plugins/ralph-wiggum/*)"
        "Bash(${config.home.homeDirectory}/.claude/plugins/cache/claude-plugins-official/ralph-wiggum/*)"
      ];
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
        "Read(~/.ssh)"
        "Read(~/.aws)"
        "Read(~/.gnupg)"
        "Read(~/.password-store)"
        "Read(~/.kube)"
        "Read(~/.docker)"
        "Read(~/.config/containers)"
        "Read(~/.config/gcloud)"
        "Read(~/.azure)"
        "Read(~/.helm)"
        "Read(~/.local/share/keyrings)"
        # ── Sensitive config files ──
        "Read(~/.netrc)"
        "Read(~/.npmrc)"
        "Read(~/.pypirc)"
        "Read(~/.gitconfig-secrets)"
        "Read(~/.config/waybar/.env)"  # Wallet zpub keys
        "Read(~/.config/sops)"         # age private key (sops-nix)
        # ── History files (may contain secrets) ──
        "Read(~/.bash_history)"
        "Read(~/.zsh_history)"
        "Read(~/.python_history)"
        # ── System sensitive files ──
        "Read(/etc/passwd)"
        "Read(/etc/shadow)"
        "Read(/etc/sudoers)"
        "Read(/etc/ssh)"
        # ── Edit/Write restrictions ──
        "Edit(~/.env)"
        "Edit(~/.env.local)"
        "Edit(~/.ssh)"
        "Edit(~/.aws)"
        "Edit(~/.gnupg)"
        "Edit(~/.password-store)"
        "Edit(~/.kube)"
        "Edit(~/.docker)"
        "Edit(~/.config/containers)"
        "Edit(~/.config/sops)"
        "Edit(~/.netrc)"
        "Edit(~/.npmrc)"
        "Edit(/etc)"
        "Write(~/.env)"
        "Write(~/.env.local)"
        "Write(~/.ssh)"
        "Write(~/.aws)"
        "Write(~/.gnupg)"
        "Write(~/.password-store)"
        "Write(~/.kube)"
        "Write(~/.docker)"
        "Write(~/.config/containers)"
        "Write(~/.config/sops)"
        "Write(/etc)"
      ];
      defaultMode = "default";
    };
    # Plugins
    enabledPlugins = {
      # LSP - language servers
      "typescript-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
      "clangd-lsp@claude-plugins-official" = true;
      "csharp-lsp@claude-plugins-official" = true;
      "gopls-lsp@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "lua-lsp@claude-plugins-official" = true;
      # Code quality
      "code-review@claude-code-plugins" = true;
      "pr-review-toolkit@claude-code-plugins" = true;
      "code-simplifier@claude-plugins-official" = true;
      "security-guidance@claude-code-plugins" = true;
      # Workflow
      "commit-commands@claude-code-plugins" = true;
      "feature-dev@claude-code-plugins" = true;
      "frontend-design@claude-code-plugins" = true;
      "ralph-wiggum@claude-code-plugins" = true;
      "andrej-karpathy-skills@karpathy-skills" = true;
      # Platform skills
      "stripe@claude-plugins-official" = true;
      "pg@aiguide" = true;
      "postgres-best-practices@supabase-agent-skills" = true;
      "cloudflare@cloudflare" = true;
      "android-reverse-engineering@android-reverse-engineering-skill" = true;
      "neon-postgres@neon" = true;
    };
    installedMarketplaces = {
      "supabase-agent-skills" = {
        url = "https://github.com/supabase/agent-skills";
      };
      "android-reverse-engineering-skill" = {
        url = "https://github.com/SimoneAvogadro/android-reverse-engineering-skill";
      };
      "cloudflare" = {
        url = "https://github.com/cloudflare/skills";
      };
      "aiguide" = {
        url = "https://github.com/timescale/pg-aiguide";
      };
      "neon" = {
        url = "https://github.com/neondatabase/agent-skills";
      };
      "karpathy-skills" = {
        url = "https://github.com/forrestchang/andrej-karpathy-skills";
      };
    };
    # MCP servers
    enableAllProjectMcpServers = false;
    enabledMcpjsonServers = [ "blender" ];
    mcpServers = {
      "cloudflare-ai-gateway" = {
        command = "npx";
        args = [ "-y" "mcp-remote@0.1.38" "https://ai-gateway.mcp.cloudflare.com/mcp" ];
      };
      "playwright" = {
        command = "npx";
        args = [ "-y" "@playwright/mcp@0.0.70" ];
      };
      "chrome-devtools" = {
        command = "npx";
        args = [ "-y" "chrome-devtools-mcp@0.23.0" ];
      };
      "terraform" = {
        command = "docker";
        args = [
          "run" "-i" "--rm"
          "-e" "TFE_TOKEN=\${TFE_TOKEN}"
          "hashicorp/terraform-mcp-server:0.4.0"
        ];
      };
      "github" = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          Authorization = "Bearer \${GITHUB_PERSONAL_ACCESS_TOKEN}";
        };
      };
    };
    # Sandbox (Linux bubblewrap) — OS-level enforcement
    # permissions.deny only blocks Claude's file tools, NOT Bash subprocesses.
    # sandbox.filesystem.denyRead blocks everything including cat/grep/etc.
    sandbox = {
      enabled = true;
      autoAllowBashIfSandboxed = false;
      allowUnsandboxedCommands = false;  # No escape hatch via dangerouslyDisableSandbox
      filesystem = {
        # OS-level read protection (blocks cat, grep, etc. — not just Read tool)
        denyRead = [
          "~/.ssh"
          "~/.aws"
          "~/.gnupg"
          "~/.kube"
          "~/.docker"
          "~/.password-store"
          "~/.netrc"
          "~/.npmrc"
          "~/.config/gcloud"
          "~/.azure"
          "~/.helm"
          "~/.local/share/keyrings"
          "~/.config/waybar/.env"
          "~/.config/sops"
        ];
        # OS-level write protection (mirrors denyRead + shell configs)
        denyWrite = [
          "/etc"
          "~/.ssh"
          "~/.aws"
          "~/.gnupg"
          "~/.kube"
          "~/.docker"
          "~/.password-store"
          "~/.netrc"
          "~/.npmrc"
          "~/.config/gcloud"
          "~/.azure"
          "~/.helm"
          "~/.local/share/keyrings"
          "~/.config/waybar/.env"
          "~/.config/sops"
          "~/.config/containers"
          "~/.bashrc"
          "~/.zshrc"
          "~/.profile"
        ];
      };
      network = {
        allowedDomains = [
          # Anthropic
          "api.anthropic.com"
          "statsig.anthropic.com"
          # Nix caches
          "cache.nixos.org"
          "nix-community.cachix.org"
          "hyprland.cachix.org"
          "numtide.cachix.org"
          # Dev tools
          "github.com"
          "api.github.com"
          "raw.githubusercontent.com"
          "registry.npmjs.org"
          "npmjs.org"
          "pypi.org"
          # Documentation
          "wiki.nixos.org"
          "discourse.nixos.org"
          "docs.anthropic.com"
          "deepwiki.com"
          # fal.ai API
          "fal.ai"
          "queue.fal.run"
          "rest.alpha.fal.run"
          "storage.googleapis.com"
        ];
      };
    };
    # Effort level — max = deepest reasoning, no token spending constraint
    # Env var CLAUDE_CODE_EFFORT_LEVEL=max above takes precedence anyway
    effortLevel = "max";
    # Show thinking summaries (extended thinking visibility)
    showThinkingSummaries = true;
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
              command = ''
                jq -r '.tool_input.file_path // empty' | { read -r f; [ -z "$f" ] || [[ "$f" != *.nix ]] || [ ! -f "$f" ] || nix-instantiate --parse "$f" >/dev/null; }
              '';
              timeout = 30;
            }
          ];
        }
        # Auto-inject core principle into any CLAUDE.md
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
    };
  };

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
    claude-code  # Official CLI package
  ];

  # Deploy global CLAUDE.md (applies to all projects)
  home.file.".claude/CLAUDE.md" = {
    text = ''
      # Global Instructions

      ## Core Principle

      **Research the codebase before editing. Never change code you haven't read.**
    '';
  };

  # Deploy settings.json
  home.file.".claude/settings.json" = {
    text = settingsJson;
  };

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
  home.activation.updatePluginMarketplaces = config.lib.dag.entryAfter ["writeBoundary"] ''
    MARKET_DIR="$HOME/.claude/plugins/marketplaces"
    if [ -d "$MARKET_DIR" ]; then
      for dir in "$MARKET_DIR"/*/; do
        [ -d "''${dir}.git" ] || continue
        $DRY_RUN_CMD ${pkgs.git}/bin/git -C "''${dir}" pull --quiet 2>/dev/null || true
      done
    fi
  '';

  # Deploy hooks
  home.file.".claude/hooks/protect_sensitive_files.py" = {
    source = protectSensitiveFilesHook;
    executable = true;
  };

  home.file.".claude/hooks/ensure_claudemd_principle.py" = {
    source = ensureClaudeMdPrincipleHook;
    executable = true;
  };
}
