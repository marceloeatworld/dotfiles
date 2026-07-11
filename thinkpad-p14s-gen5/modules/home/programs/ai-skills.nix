# Centralized AI agent skills for Claude Code, ForgeCode, OpenCode, and Codex
# First rebuild clones missing repos, subsequent rebuilds only redistribute the cache
# Refresh with network: update-skills (shell function in shell.nix)
{ config, pkgs, ... }:

let
  # ── Skill destinations for each tool ──
  claudeSkills = "$HOME/.claude/skills";
  forgeSkills = "$HOME/.forge/skills";
  opencodeSkills = "$HOME/.config/opencode/skills";
  codexSkills = "$HOME/.codex/skills";
  allSkillDirs = "${claudeSkills} ${forgeSkills} ${opencodeSkills} ${codexSkills}";

  cache = "$HOME/.cache/ai-skills";

  # Helper: clone a git repo if missing (no pull — refresh via `update-skills`)
  # Keeps rebuilds fast and offline-capable; existing caches are left untouched.
  gitSync = ''
    _git_sync() {
      local dir="$1" url="$2"
      if [ ! -d "$dir/.git" ]; then
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c "rm -rf '$dir' && mkdir -p '$(dirname "$dir")' && ${pkgs.git}/bin/git clone --quiet '$url' '$dir'" 2>/dev/null || true
      fi
    }
  '';

  # Helper: mark generated skills and prune old generated skills that disappeared
  # from the centralized source set. Manual, unmarked skills are left alone.
  managedSkillLifecycle = ''
    _ai_skills_begin_manifest() {
      AI_SKILLS_EXPECTED=$(${pkgs.coreutils}/bin/mktemp)
      export AI_SKILLS_EXPECTED
    }

    _ai_skills_record() {
      local dir="$1"
      [ -n "''${AI_SKILLS_EXPECTED:-}" ] && ${pkgs.coreutils}/bin/printf '%s\n' "$dir" >> "$AI_SKILLS_EXPECTED"
      if [ -z "''${DRY_RUN_CMD:-}" ]; then
        ${pkgs.coreutils}/bin/touch "$dir/.ai-skills-managed"
      fi
    }

    _ai_skills_prune_stale() {
      [ -n "''${AI_SKILLS_EXPECTED:-}" ] || return 0

      for dest in ${allSkillDirs}; do
        [ -d "$dest" ] || continue
        ${pkgs.findutils}/bin/find "$dest" -name .ai-skills-managed -type f -print0 2>/dev/null | \
          while IFS= read -r -d "" marker; do
            local dir=$(${pkgs.coreutils}/bin/dirname "$marker")
            if ! ${pkgs.gnugrep}/bin/grep -Fxq "$dir" "$AI_SKILLS_EXPECTED"; then
              $DRY_RUN_CMD rm -rf "$dir"
            fi
          done
      done

      $DRY_RUN_CMD rm -f "$AI_SKILLS_EXPECTED"
    }
  '';

  # Helper: Codex renders all skill names/descriptions into every turn.
  # Upstream skills often ship long trigger prose, so compact only the
  # metadata copied to Codex while leaving each SKILL.md body intact.
  compactCodexSkillDescriptions = ''
    _compact_codex_skill_descriptions() {
      local dir="$1"
      case "$dir" in
        ${codexSkills}/*) ;;
        *) return 0 ;;
      esac

      [ -d "$dir" ] || return 0
      ${pkgs.findutils}/bin/find "$dir" -name SKILL.md -type f -print0 2>/dev/null | \
        ${pkgs.findutils}/bin/xargs -0 -r ${pkgs.perl}/bin/perl -0pi -e '
          my $limit = 120;
          s{\A---\n(.*?)\n---\n}{
            my $fm = $1;
            my $description = "";

            if ($fm =~ /^description:\s*[>|]-?\s*\n(.*?)(?=^[A-Za-z0-9_-]+:\s*|\z)/ms) {
              $description = $1;
            } elsif ($fm =~ /^description:\s*(?![>|]-?\s*$)(.*(?:\n[ \t]+.*)*)/m) {
              $description = $1;
            }

            if ($description ne "") {
              $description =~ s/^[ \t]+//mg;
              $description =~ s/\r?\n/ /g;
              $description =~ s/\s+/ /g;
              $description =~ s/^\s+|\s+$//g;
              $description =~ s/^"|"$//g;

              if (length($description) > $limit) {
                $description = substr($description, 0, $limit);
                $description =~ s/\s+\S*$//;
                $description =~ s/["\\]/ /g;

                if ($fm =~ /^description:\s*[>|]-?/m) {
                  $fm =~ s/^description:\s*[>|]-?\s*\n.*?(?=^[A-Za-z0-9_-]+:\s*|\z)/description: "$description"\n/ms;
                } else {
                  $fm =~ s/^description:\s*(?![>|]-?\s*$).*(?:\n[ \t]+.*)*/description: "$description"/m;
                }
              }
            }

            "---\n$fm\n---\n"
          }es;
        '
    }
  '';

  # Helper: copy skill subdirs to all tool destinations
  copySkills = ''
    _copy_skills() {
      local src="$1"
      for dest in ${allSkillDirs}; do
        $DRY_RUN_CMD mkdir -p "$dest"
        for skill_dir in "$src/"*/; do
          [ -d "''${skill_dir}" ] || continue
          local name=$(${pkgs.coreutils}/bin/basename "''${skill_dir}")
          $DRY_RUN_CMD rm -rf "$dest/''${name}"
          $DRY_RUN_CMD cp -r "''${skill_dir}" "$dest/''${name}"
          if [ -z "''${DRY_RUN_CMD:-}" ]; then
            _ai_skills_record "$dest/''${name}"
            _compact_codex_skill_descriptions "$dest/''${name}"
          fi
        done
      done
    }
  '';

  # Helper: copy only selected skill subdirs from a collection.
  copyNamedSkills = ''
    _copy_named_skills() {
      local src="$1"
      shift

      for name in "$@"; do
        local skill_dir="$src/$name"
        [ -f "$skill_dir/SKILL.md" ] || continue

        for dest in ${allSkillDirs}; do
          $DRY_RUN_CMD mkdir -p "$dest"
          $DRY_RUN_CMD rm -rf "$dest/$name"
          $DRY_RUN_CMD cp -r "$skill_dir" "$dest/$name"
          if [ -z "''${DRY_RUN_CMD:-}" ]; then
            _ai_skills_record "$dest/$name"
            _compact_codex_skill_descriptions "$dest/$name"
          fi
        done
      done
    }
  '';

  # Helper: copy skills that have SKILL.md at root (RunPod-style)
  copySkillsWithMarker = ''
    _copy_skills_marker() {
      local src="$1"
      for dest in ${allSkillDirs}; do
        $DRY_RUN_CMD mkdir -p "$dest"
        for skill_dir in "$src/"*/; do
          [ -f "''${skill_dir}SKILL.md" ] || continue
          local name=$(${pkgs.coreutils}/bin/basename "''${skill_dir}")
          $DRY_RUN_CMD rm -rf "$dest/''${name}"
          $DRY_RUN_CMD cp -r "''${skill_dir}" "$dest/''${name}"
          if [ -z "''${DRY_RUN_CMD:-}" ]; then
            _ai_skills_record "$dest/''${name}"
            _compact_codex_skill_descriptions "$dest/''${name}"
          fi
        done
      done
    }
  '';

  # Helper: copy a purpose-built skill repo as a single skill payload.
  # This intentionally copies only runtime skill files, not the repository
  # metadata around them (.git, .github, agent config, etc.).
  copySkillRepo = ''
    _copy_skill_repo() {
      local src="$1" name="$2"
      [ -f "$src/SKILL.md" ] || return 0

      for dest in ${allSkillDirs}; do
        $DRY_RUN_CMD mkdir -p "$dest"
        $DRY_RUN_CMD rm -rf "$dest/$name"
        $DRY_RUN_CMD mkdir -p "$dest/$name"
        $DRY_RUN_CMD cp "$src/SKILL.md" "$dest/$name/SKILL.md"

        for file in README.md LICENSE LICENSE.md CHANGELOG.md; do
          [ -f "$src/$file" ] || continue
          $DRY_RUN_CMD cp "$src/$file" "$dest/$name/$file"
        done

        for dir in references scripts assets templates examples; do
          [ -d "$src/$dir" ] || continue
          $DRY_RUN_CMD cp -r "$src/$dir" "$dest/$name/$dir"
        done

        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          _ai_skills_record "$dest/$name"
          _compact_codex_skill_descriptions "$dest/$name"
        fi
      done
    }
  '';

  # Helper: copy every nested directory that contains a SKILL.md.
  # Used for upstream repositories that are collections of skills rather than
  # one skill repo.
  copyNestedSkillsWithMarker = ''
    _copy_nested_skills_marker() {
      local src="$1"
      [ -d "$src" ] || return 0

      ${pkgs.findutils}/bin/find "$src" -name SKILL.md -type f -print0 2>/dev/null | \
        while IFS= read -r -d "" marker; do
          local skill_dir=$(${pkgs.coreutils}/bin/dirname "$marker")
          local name=$(${pkgs.coreutils}/bin/basename "$skill_dir")

          for dest in ${allSkillDirs}; do
            $DRY_RUN_CMD mkdir -p "$dest"
            $DRY_RUN_CMD rm -rf "$dest/$name"
            $DRY_RUN_CMD cp -r "$skill_dir" "$dest/$name"
            if [ -z "''${DRY_RUN_CMD:-}" ]; then
              _ai_skills_record "$dest/$name"
              _compact_codex_skill_descriptions "$dest/$name"
            fi
          done
        done
    }
  '';

  helpers = "${gitSync}\n${managedSkillLifecycle}\n${compactCodexSkillDescriptions}\n${copySkills}\n${copyNamedSkills}\n${copySkillsWithMarker}\n${copySkillRepo}\n${copyNestedSkillsWithMarker}";

  # ════════════════════════════════════════════════════════════════════════
  # INLINE SKILLS (deployed as SKILL.md to all tools)
  # ════════════════════════════════════════════════════════════════════════

  skillSearchFirst = ''
    ---
    name: search-first
    description: Research-before-coding workflow. Search for existing tools, libraries, and patterns before writing custom code.
    ---

    # /search-first — Research Before You Code

    ## Trigger

    Use this skill when:
    - Starting a new feature that likely has existing solutions
    - Adding a dependency or integration
    - The user asks "add X functionality" and you're about to write code
    - Before creating a new utility, helper, or abstraction

    ## Workflow

    1. **NEED ANALYSIS** — Define what functionality is needed
    2. **PARALLEL SEARCH** — Check nixpkgs, PyPI, npm, GitHub, MCP, existing skills
    3. **EVALUATE** — Score candidates (functionality, maintenance, license, deps)
    4. **DECIDE** — Adopt as-is / Extend-wrap / Build custom
    5. **IMPLEMENT** — Install package or write minimal custom code

    ## Decision Matrix

    | Signal | Action |
    |--------|--------|
    | Exact match, well-maintained, MIT/Apache | **Adopt** — install and use directly |
    | Partial match, good foundation | **Extend** — install + write thin wrapper |
    | Multiple weak matches | **Compose** — combine 2-3 small packages |
    | Nothing suitable found | **Build** — write custom, informed by research |

    ## Anti-Patterns

    - **Jumping to code**: Writing a utility without checking if one exists
    - **Ignoring nixpkgs**: Not checking if a Nix package already provides the capability
    - **Over-customizing**: Wrapping a library so heavily it loses its benefits
    - **Dependency bloat**: Installing a massive package for one small feature
  '';

  skillVerificationLoop = ''
    ---
    name: verification-loop
    description: "Comprehensive verification system. Run build, type check, lint, tests, and security scan after completing changes."
    ---

    # Verification Loop Skill

    ## When to Use

    - After completing a feature or significant code change
    - Before creating a PR or committing
    - After refactoring

    ## Verification Phases

    ### Phase 1: Build Verification
    Detect build system and run: `nix flake check`, `pnpm run build`, `cargo build`, etc.
    If build fails, STOP and fix before continuing.

    ### Phase 2: Type Check
    `pyright .`, `mypy .`, `pnpm dlx tsc --noEmit`, etc.

    ### Phase 3: Lint Check
    `ruff check .`, `shellcheck *.sh`, etc.

    ### Phase 4: Test Suite
    Run tests with coverage. Target: 80% minimum.

    ### Phase 5: Security Scan
    Check for hardcoded secrets, API keys, tokens in source files.

    ### Phase 6: Diff Review
    `git diff --stat` and `git diff HEAD~1 --name-only`

    ## Output Format

    ```
    VERIFICATION: [PASS/FAIL]
    Build:    [OK/FAIL]
    Types:    [OK/X errors]
    Lint:     [OK/X issues]
    Tests:    [X/Y passed, Z% coverage]
    Security: [OK/X found]
    Ready for PR: [YES/NO]
    ```
  '';

  skillBlueprint = ''
    ---
    name: blueprint
    description: >-
      Turn a one-line objective into a step-by-step construction plan for
      multi-session, multi-agent engineering projects. Each step has a
      self-contained context brief so a fresh agent can execute it cold.
      TRIGGER when: user requests a plan, blueprint, or roadmap for a
      complex multi-PR task.
      DO NOT TRIGGER when: task is completable in a single PR or fewer
      than 3 tool calls, or user says "just do it".
    ---

    # Blueprint — Construction Plan Generator

    Turn a one-line objective into a step-by-step construction plan that any coding agent can execute cold.

    ## When to Use

    - Breaking a large feature into multiple PRs with clear dependency order
    - Planning a refactor or migration that spans multiple sessions
    - Coordinating parallel workstreams across sub-agents

    **Do not use** for tasks completable in a single PR or fewer than 3 tool calls.

    ## How It Works

    1. **Research** — Pre-flight checks, reads project structure, existing plans, and memory files.
    2. **Design** — Breaks objective into one-PR-sized steps. Assigns dependency edges, parallel/serial ordering.
    3. **Draft** — Writes a self-contained Markdown plan file. Every step includes context brief, task list, verification commands, and exit criteria.
    4. **Review** — Adversarial review against checklist and anti-pattern catalog.
    5. **Register** — Saves the plan, presents summary to user.

    ## Key Features

    - **Cold-start execution** — Every step includes a self-contained context brief
    - **Adversarial review gate** — Plan reviewed against completeness, dependency correctness
    - **Parallel step detection** — Dependency graph identifies parallelizable steps
  '';

  skillSecurityScan = ''
    ---
    name: security-scan
    description: Scan your AI coding agent configuration for security vulnerabilities, misconfigurations, and injection risks.
    ---

    # Security Scan Skill

    ## When to Activate

    - Setting up a new project
    - After modifying settings, CLAUDE.md, or MCP configs
    - Before committing configuration changes

    ## What It Scans

    | File | Checks |
    |------|--------|
    | CLAUDE.md | Hardcoded secrets, auto-run instructions, prompt injection |
    | settings.json | Overly permissive allow lists, missing deny lists |
    | MCP configs | Risky servers, hardcoded env secrets |
    | Hooks | Command injection, data exfiltration |

    ## Severity Levels

    | Level | Action |
    |-------|--------|
    | CRITICAL | Fix immediately — hardcoded keys, unrestricted shell |
    | HIGH | Fix before production — missing deny lists, auto-run |
    | MEDIUM | Recommended — silent error suppression |
    | INFO | Awareness — good practices noted |
  '';

  # SKILL.md wrapper for design-md — full spec lives in spec.md / README.md
  # (synced from upstream by the activation script below)
  skillDesignMd = ''
    ---
    name: design-md
    description: >-
      DESIGN.md format specification by Google Labs. Use when authoring,
      reading, validating, or converting DESIGN.md files — a structured
      format that describes a visual identity (design tokens + rationale)
      to coding agents. Triggers on: "DESIGN.md", "design tokens",
      "design system file", "visual identity spec", "design tokens YAML",
      "lint DESIGN.md", or when building a UI from a brand brief.
    metadata:
      source: https://github.com/google-labs-code/design.md
      version: alpha
    ---

    # DESIGN.md — Visual Identity Spec for Agents

    A DESIGN.md file combines machine-readable design tokens (YAML front
    matter) with human-readable rationale (Markdown prose). Tokens are
    the normative values; prose tells the agent *why* and *how to apply*.

    ## When to Use

    - User asks to author or edit a `DESIGN.md`
    - User provides a brand brief and wants tokenized output
    - Building a UI that should follow an existing `DESIGN.md`
    - Validating, diffing, or exporting a `DESIGN.md` to Tailwind / DTCG
    - Converting Figma variables, `tokens.json`, or Tailwind theme to DESIGN.md

    ## Reference Files (this directory)

    Both files are auto-synced from the upstream repo via `update-skills`.
    Read them directly for the canonical, always-current spec:

    - **`spec.md`** — full DESIGN.md format specification (sections, schema,
      consumer behavior, edge cases). Authoritative source.
    - **`README.md`** — overview, CLI usage, linting rules, programmatic API,
      DTCG / Tailwind interoperability.

    Always prefer reading `spec.md` over relying on memory — the format is
    at version `alpha` and may have evolved since this skill was packaged.

    ## CLI

    The `@google/design.md` CLI ships the spec as a tool too:

    ```bash
    pnpm dlx @google/design.md spec            # print canonical spec
    pnpm dlx @google/design.md spec --rules    # spec + linter rules table
    pnpm dlx @google/design.md lint DESIGN.md  # validate
    pnpm dlx @google/design.md diff a.md b.md  # detect regressions
    pnpm dlx @google/design.md export --format tailwind DESIGN.md
    pnpm dlx @google/design.md export --format dtcg DESIGN.md
    ```

    ## Upstream

    - Repo: https://github.com/google-labs-code/design.md
    - Spec: https://github.com/google-labs-code/design.md/blob/main/docs/spec.md
    - Status: `alpha` — schema may evolve
  '';

  designMdSkillFile = pkgs.writeText "design-md-SKILL.md" skillDesignMd;

  copyDesignMdSkill = ''
    _copy_design_md_skill() {
      local src="$1"
      [ -d "$src" ] || return 0

      for dest in ${allSkillDirs}; do
        $DRY_RUN_CMD mkdir -p "$dest"
        $DRY_RUN_CMD rm -rf "$dest/design-md"
        $DRY_RUN_CMD mkdir -p "$dest/design-md"
        $DRY_RUN_CMD cp "${designMdSkillFile}" "$dest/design-md/SKILL.md"

        for file in README.md LICENSE LICENSE.md; do
          [ -f "$src/$file" ] || continue
          $DRY_RUN_CMD cp "$src/$file" "$dest/design-md/$file"
        done

        for dir in docs examples; do
          [ -d "$src/$dir" ] || continue
          $DRY_RUN_CMD cp -r "$src/$dir" "$dest/design-md/$dir"
        done

        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          _ai_skills_record "$dest/design-md"
          _compact_codex_skill_descriptions "$dest/design-md"
        fi
      done
    }
  '';

  # ════════════════════════════════════════════════════════════════════════
  # SLASH COMMANDS (Claude Code only — ~/.claude/commands/)
  # ════════════════════════════════════════════════════════════════════════

  cmdPlan = ''
    ---
    description: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.
    ---

    # Plan Command

    The planner agent will:
    1. **Analyze the request** and restate requirements in clear terms
    2. **Break down into phases** with specific, actionable steps
    3. **Identify dependencies** between components
    4. **Assess risks** and potential blockers
    5. **Present the plan** and WAIT for your explicit confirmation

    **CRITICAL**: The planner agent will **NOT** write any code until you explicitly confirm.
  '';

  cmdCodeReview = ''
    # Code Review

    Comprehensive security and quality review of uncommitted changes:

    1. Get changed files: git diff --name-only HEAD
    2. For each changed file, check for:
       - **Security**: Hardcoded credentials, injection vulnerabilities, missing input validation
       - **Code Quality**: Functions > 50 lines, nesting > 4 levels, missing error handling
       - **Best Practices**: Missing tests, unnecessary complexity
    3. Generate report with severity, file location, issue description, suggested fix
    4. Block commit if CRITICAL or HIGH issues found
  '';

  cmdRefactorClean = ''
    # Refactor Clean

    Safely identify and remove dead code with test verification at every step.

    1. **Detect Dead Code** — Run analysis tools or grep for unused exports
    2. **Categorize** — SAFE (unused utils) / CAUTION (components, routes) / DANGER (config, entry points)
    3. **Safe Deletion Loop** — For each SAFE item: run tests, delete, re-run tests, revert if broken
    4. **Rules** — One deletion at a time. Skip if uncertain. Don't refactor while cleaning.
  '';

  cmdBuildFix = ''
    # Build and Fix

    Incrementally fix build and type errors with minimal, safe changes.

    1. **Detect Build System** — flake.nix → `nix flake check`, package.json → `pnpm run build`, etc.
    2. **Parse and Group Errors** — By file, sorted by dependency order
    3. **Fix Loop** — Read file, diagnose, fix minimally, re-run build, move to next
    4. **Guardrails** — Stop if fix introduces more errors, same error persists 3x, or needs architecture changes
  '';

  cmdCheckpoint = ''
    # Checkpoint Command

    Create or verify a checkpoint in your workflow.

    - `create <name>` — Run verify, create git stash/commit, log to `.claude/checkpoints.log`
    - `verify <name>` — Compare current state to checkpoint (files, tests, build)
    - `list` — Show all checkpoints with name, timestamp, git SHA
    - `clear` — Remove old checkpoints (keeps last 5)
  '';

  cmdVerify = ''
    # Verification Command

    Run comprehensive verification: Build → Types → Lint → Tests → Secrets → Git Status.
    Arguments: `quick` (build + types), `full` (all), `pre-commit`, `pre-pr` (+ security scan).
  '';

  cmdSaveSession = ''
    ---
    description: Save current session state to ~/.claude/sessions/ so work can be resumed later with full context.
    ---

    # Save Session Command

    Capture everything that happened in this session:
    1. Gather context (git diff, decisions, errors, resolutions)
    2. Write to `~/.claude/sessions/YYYY-MM-DD-<id>-session.tmp`
    3. Include: What We Are Building, What WORKED, What Did NOT Work, Current State, Decisions, Blockers, Exact Next Step
    4. The "What Did NOT Work" section is the most critical — prevents future sessions from retrying failed approaches.
  '';

  cmdResumeSession = ''
    ---
    description: Load the most recent session file from ~/.claude/sessions/ and resume work with full context.
    ---

    # Resume Session Command

    1. Find most recent `*-session.tmp` in `~/.claude/sessions/`
    2. Read and present: project, current state, what not to retry, open questions, next step
    3. Wait for user — do NOT start working automatically
  '';

  cmdLearn = ''
    # /learn - Extract Reusable Patterns

    Analyze the current session and extract patterns worth saving as skills.
    Focus on: error resolution patterns, debugging techniques, workarounds, project-specific patterns.
    Save to `~/.claude/skills/learned/[pattern-name].md`.
    Don't extract trivial fixes or one-time issues.
  '';

  # Helper to deploy a skill to all 4 tools
  deploySkill = name: content: {
    ".claude/skills/${name}/SKILL.md".text = content;
    ".forge/skills/${name}/SKILL.md".text = content;
    ".config/opencode/skills/${name}/SKILL.md".text = content;
    ".codex/skills/${name}/SKILL.md".text = content;
  };

in
{
  home.file = {
      # ── Slash commands (Claude Code only) ────────────────────────────────
      ".claude/commands/plan.md".text = cmdPlan;
      ".claude/commands/code-review.md".text = cmdCodeReview;
      ".claude/commands/refactor-clean.md".text = cmdRefactorClean;
      ".claude/commands/build-fix.md".text = cmdBuildFix;
      ".claude/commands/checkpoint.md".text = cmdCheckpoint;
      ".claude/commands/verify.md".text = cmdVerify;
      ".claude/commands/save-session.md".text = cmdSaveSession;
      ".claude/commands/resume-session.md".text = cmdResumeSession;
      ".claude/commands/learn.md".text = cmdLearn;
  };

  # ── Git-cloned skills (all tools) ─────────────────────────────────────
  # Single activation script: clone once, distribute to Claude/Forge/OpenCode/Codex
  home.activation.installAllSkills = config.lib.dag.entryAfter ["writeBoundary"] ''
    ${helpers}
    _ai_skills_begin_manifest

    # Clerk removed from the centralized skill set. Clean stale copies from all
    # agent CLIs and delete the cached upstream clone so it cannot be reused.
    for dest in ${allSkillDirs}; do
      for stale in \
        "$dest"/clerk "$dest"/clerk-* \
        "$dest"/android "$dest"/backend-api "$dest"/custom-ui \
        "$dest"/nextjs-patterns "$dest"/orgs "$dest"/setup \
        "$dest"/swift "$dest"/testing "$dest"/webhooks \
        "$dest"/core/clerk "$dest"/core/clerk-* \
        "$dest"/features/clerk-* "$dest"/frameworks/clerk-* \
        "$dest"/mobile/clerk-*; do
        [ -d "$stale" ] || continue
        if [ -f "$stale/SKILL.md" ] && ${pkgs.gnugrep}/bin/grep -Eq '(^name: *clerk|author: *clerk|clerk\.com|@clerk/|Clerk)' "$stale/SKILL.md"; then
          $DRY_RUN_CMD rm -rf "$stale"
        fi
      done
    done
    $DRY_RUN_CMD rm -rf "${cache}/clerk"

    # Remove local/helper skill families that are no longer part of the shared
    # set. Keep only purpose-built Hyprland and NixOS from the old "other" group.
    for dest in ${allSkillDirs}; do
      for stale in \
        "$dest"/android-reverse-engineering \
        "$dest"/blueprint \
        "$dest"/deploy-to-vercel \
        "$dest"/mdbook \
        "$dest"/search-first \
        "$dest"/security-scan \
        "$dest"/svelte-code-writer \
        "$dest"/svelte-core-bestpractices \
        "$dest"/verification-loop \
        "$dest"/web-design-guidelines \
        "$dest"/web-perf \
        "$dest"/building-ai-agent-on-cloudflare \
        "$dest"/building-mcp-server-on-cloudflare \
        "$dest"/design-postgres-tables \
        "$dest"/design-postgis-tables \
        "$dest"/find-hypertable-candidates \
        "$dest"/migrate-postgres-tables-to-hypertables \
        "$dest"/pgvector-semantic-search \
        "$dest"/postgres-hybrid-text-search \
        "$dest"/setup-timescaledb-hypertables \
        "$dest"/supabase \
        "$dest"/supabase-postgres-best-practices; do
        $DRY_RUN_CMD rm -rf "$stale"
      done
    done
    $DRY_RUN_CMD rm -rf "${cache}/supabase" "${cache}/android-re" "${cache}/mdbook" "${cache}/svelte"

    # ── DESIGN.md (official Google Labs source; wrapper copies README/docs/spec) ──
    _git_sync "${cache}/design-md" "https://github.com/google-labs-code/design.md"
    ${copyDesignMdSkill}
    _copy_design_md_skill "${cache}/design-md"

    # ── Google (Cloud skills in skills/cloud/*/: Gemini API, BigQuery, Cloud Run, Firebase, GKE, AlloyDB, etc.) ──
    _git_sync "${cache}/google" "https://github.com/google/skills"
    [ -d "${cache}/google/skills/cloud" ] && _copy_skills "${cache}/google/skills/cloud"

    # ── Cloudflare (selected skills; web-perf is intentionally omitted) ──
    _git_sync "${cache}/cloudflare" "https://github.com/cloudflare/skills"
    [ -d "${cache}/cloudflare/skills" ] && _copy_named_skills "${cache}/cloudflare/skills" \
      agents-sdk \
      cloudflare \
      cloudflare-email-service \
      durable-objects \
      sandbox-sdk \
      workers-best-practices \
      wrangler

    # ── Neon (skills in skills/*/) ──
    _git_sync "${cache}/neon" "https://github.com/neondatabase/agent-skills"
    [ -d "${cache}/neon/skills" ] && _copy_skills "${cache}/neon/skills"

    # ── Postgres only from pg-aiguide; Timescale/hypertable skills are omitted ──
    _git_sync "${cache}/pg-aiguide" "https://github.com/timescale/pg-aiguide"
    [ -d "${cache}/pg-aiguide/skills" ] && _copy_named_skills "${cache}/pg-aiguide/skills" postgres

    # ── RunPod (SKILL.md at root of each subdir) ──
    _git_sync "${cache}/runpod" "https://github.com/runpod/skills"
    _copy_skills_marker "${cache}/runpod"

    # ── Hyprland (purpose-built skill repo) ──
    _git_sync "${cache}/hyprland" "https://github.com/marceloeatworld/hyprland-ai-skill"
    _copy_skill_repo "${cache}/hyprland" "hyprland"

    # ── NixOS (purpose-built skill repo) ──
    _git_sync "${cache}/nixos" "https://github.com/marceloeatworld/nixos-ai-skill"
    _copy_skill_repo "${cache}/nixos" "nixos"

    # ── Caveman (terse response and review/commit skills) ──
    _git_sync "${cache}/caveman" "https://github.com/JuliusBrussee/caveman"
    [ -d "${cache}/caveman/skills" ] && _copy_skills_marker "${cache}/caveman/skills"

    # ── fal.ai (skills in skills/claude.ai/*/) ──
    _git_sync "${cache}/fal-ai" "https://github.com/fal-ai-community/skills"
    [ -d "${cache}/fal-ai/skills/claude.ai" ] && _copy_skills "${cache}/fal-ai/skills/claude.ai"

    # ── Vercel/React (selected skills; deploy-to-vercel/web-design omitted) ──
    _git_sync "${cache}/vercel" "https://github.com/vercel-labs/agent-skills"
    [ -d "${cache}/vercel/skills" ] && _copy_named_skills "${cache}/vercel/skills" \
      composition-patterns \
      react-best-practices \
      react-native-skills \
      react-view-transitions \
      vercel-cli-with-tokens

    _ai_skills_prune_stale
  '';
}
