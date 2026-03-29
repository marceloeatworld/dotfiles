# Everything Claude Code (ECC) - Curated skills & commands
# Source: https://github.com/affaan-m/everything-claude-code (MIT)
# Selected for NixOS / Python / Shell workflow
{ ... }:

let
  # ════════════════════════════════════════════════════════════════════════
  # SLASH COMMANDS (deployed to ~/.claude/commands/)
  # Usage: /plan, /code-review, /verify, etc.
  # ════════════════════════════════════════════════════════════════════════

  cmdPlan = ''
    ---
    description: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.
    ---

    # Plan Command

    This command invokes the **planner** agent to create a comprehensive implementation plan before writing any code.

    ## What This Command Does

    1. **Restate Requirements** - Clarify what needs to be built
    2. **Identify Risks** - Surface potential issues and blockers
    3. **Create Step Plan** - Break down implementation into phases
    4. **Wait for Confirmation** - MUST receive user approval before proceeding

    ## How It Works

    The planner agent will:

    1. **Analyze the request** and restate requirements in clear terms
    2. **Break down into phases** with specific, actionable steps
    3. **Identify dependencies** between components
    4. **Assess risks** and potential blockers
    5. **Estimate complexity** (High/Medium/Low)
    6. **Present the plan** and WAIT for your explicit confirmation

    ## Important Notes

    **CRITICAL**: The planner agent will **NOT** write any code until you explicitly confirm the plan with "yes" or "proceed" or similar affirmative response.

    If you want changes, respond with:
    - "modify: [your changes]"
    - "different approach: [alternative]"
    - "skip phase 2 and do phase 3 first"

    ## Integration with Other Commands

    After planning:
    - Use `/build-fix` if build errors occur
    - Use `/code-review` to review completed implementation
    - Use `/verify` before committing
  '';

  cmdCodeReview = ''
    # Code Review

    Comprehensive security and quality review of uncommitted changes:

    1. Get changed files: git diff --name-only HEAD

    2. For each changed file, check for:

    **Security Issues (CRITICAL):**
    - Hardcoded credentials, API keys, tokens
    - Injection vulnerabilities
    - Missing input validation
    - Insecure dependencies
    - Path traversal risks

    **Code Quality (HIGH):**
    - Functions > 50 lines
    - Files > 800 lines
    - Nesting depth > 4 levels
    - Missing error handling
    - TODO/FIXME comments

    **Best Practices (MEDIUM):**
    - Missing tests for new code
    - Unnecessary complexity

    3. Generate report with:
       - Severity: CRITICAL, HIGH, MEDIUM, LOW
       - File location and line numbers
       - Issue description
       - Suggested fix

    4. Block commit if CRITICAL or HIGH issues found

    Never approve code with security vulnerabilities!
  '';

  cmdRefactorClean = ''
    # Refactor Clean

    Safely identify and remove dead code with test verification at every step.

    ## Step 1: Detect Dead Code

    Run analysis tools based on project type:

    | Tool | What It Finds | Command |
    |------|--------------|---------|
    | vulture | Unused Python code | `vulture src/` |
    | deadcode | Unused Go code | `deadcode ./...` |
    | Grep | Unused exports | Find exports with zero imports |

    If no tool is available, use Grep to find exports with zero imports.

    ## Step 2: Categorize Findings

    | Tier | Examples | Action |
    |------|----------|--------|
    | **SAFE** | Unused utilities, internal functions | Delete with confidence |
    | **CAUTION** | Components, API routes, middleware | Verify no dynamic imports |
    | **DANGER** | Config files, entry points, type definitions | Investigate before touching |

    ## Step 3: Safe Deletion Loop

    For each SAFE item:

    1. **Run full test suite** — Establish baseline (all green)
    2. **Delete the dead code** — Use Edit tool for surgical removal
    3. **Re-run test suite** — Verify nothing broke
    4. **If tests fail** — Immediately revert and skip this item
    5. **If tests pass** — Move to next item

    ## Rules

    - **Never delete without running tests first**
    - **One deletion at a time** — Atomic changes make rollback easy
    - **Skip if uncertain** — Better to keep dead code than break production
    - **Don't refactor while cleaning** — Separate concerns
  '';

  cmdBuildFix = ''
    # Build and Fix

    Incrementally fix build and type errors with minimal, safe changes.

    ## Step 1: Detect Build System

    | Indicator | Build Command |
    |-----------|---------------|
    | `flake.nix` | `nix flake check` |
    | `pyproject.toml` | `python -m py_compile` or `mypy .` |
    | `package.json` with `build` script | `npm run build` |
    | `Cargo.toml` | `cargo build 2>&1` |
    | `go.mod` | `go build ./...` |

    ## Step 2: Parse and Group Errors

    1. Run the build command and capture stderr
    2. Group errors by file path
    3. Sort by dependency order (fix imports/types before logic errors)
    4. Count total errors for progress tracking

    ## Step 3: Fix Loop (One Error at a Time)

    For each error:

    1. **Read the file** — See error context (10 lines around the error)
    2. **Diagnose** — Identify root cause
    3. **Fix minimally** — Smallest change that resolves the error
    4. **Re-run build** — Verify the error is gone and no new errors introduced
    5. **Move to next** — Continue with remaining errors

    ## Step 4: Guardrails

    Stop and ask the user if:
    - A fix introduces **more errors than it resolves**
    - The **same error persists after 3 attempts**
    - The fix requires **architectural changes**
    - Build errors stem from **missing dependencies**

    Fix one error at a time for safety. Prefer minimal diffs over refactoring.
  '';

  cmdCheckpoint = ''
    # Checkpoint Command

    Create or verify a checkpoint in your workflow.

    ## Usage

    `/checkpoint [create|verify|list] [name]`

    ## Create Checkpoint

    1. Run `/verify quick` to ensure current state is clean
    2. Create a git stash or commit with checkpoint name
    3. Log checkpoint to `.claude/checkpoints.log`:

    ```bash
    echo "$(date +%Y-%m-%d-%H:%M) | $CHECKPOINT_NAME | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
    ```

    4. Report checkpoint created

    ## Verify Checkpoint

    1. Read checkpoint from log
    2. Compare current state to checkpoint:
       - Files added/modified since checkpoint
       - Test pass rate now vs then
       - Build status

    3. Report:
    ```
    CHECKPOINT COMPARISON: $NAME
    ============================
    Files changed: X
    Tests: +Y passed / -Z failed
    Build: [PASS/FAIL]
    ```

    ## List Checkpoints

    Show all checkpoints with name, timestamp, git SHA, and status.

    ## Arguments

    $ARGUMENTS:
    - `create <name>` - Create named checkpoint
    - `verify <name>` - Verify against named checkpoint
    - `list` - Show all checkpoints
    - `clear` - Remove old checkpoints (keeps last 5)
  '';

  cmdVerify = ''
    # Verification Command

    Run comprehensive verification on current codebase state.

    ## Instructions

    Execute verification in this exact order:

    1. **Build Check**
       - Run the build command for this project
       - For NixOS: `nix flake check`
       - If it fails, report errors and STOP

    2. **Type Check**
       - Python: `pyright .` or `mypy .`
       - TypeScript: `npx tsc --noEmit`

    3. **Lint Check**
       - Python: `ruff check .`
       - Nix: `nix flake check`
       - Shell: `shellcheck` if available

    4. **Test Suite**
       - Run all tests
       - Report pass/fail count and coverage

    5. **Secrets Scan**
       - Search for hardcoded secrets, API keys, tokens
       - Report locations

    6. **Git Status**
       - Show uncommitted changes
       - Show files modified since last commit

    ## Output

    ```
    VERIFICATION: [PASS/FAIL]

    Build:    [OK/FAIL]
    Types:    [OK/X errors]
    Lint:     [OK/X issues]
    Tests:    [X/Y passed, Z% coverage]
    Secrets:  [OK/X found]

    Ready for PR: [YES/NO]
    ```

    ## Arguments

    $ARGUMENTS can be:
    - `quick` - Only build + types
    - `full` - All checks (default)
    - `pre-commit` - Checks relevant for commits
    - `pre-pr` - Full checks plus security scan
  '';

  cmdSaveSession = ''
    ---
    description: Save current session state to ~/.claude/sessions/ so work can be resumed later with full context.
    ---

    # Save Session Command

    Capture everything that happened in this session and write it to a dated file.

    ## Process

    ### Step 1: Gather context
    - Read all files modified during this session (git diff)
    - Review what was discussed, attempted, and decided
    - Note any errors encountered and resolutions
    - Check current test/build status if relevant

    ### Step 2: Create sessions folder
    ```bash
    mkdir -p ~/.claude/sessions
    ```

    ### Step 3: Write session file
    Create `~/.claude/sessions/YYYY-MM-DD-<short-id>-session.tmp`

    ### Step 4: Populate with all sections

    ```markdown
    # Session: YYYY-MM-DD

    **Project:** [project name or path]
    **Topic:** [one-line summary]

    ## What We Are Building
    [1-3 paragraphs with enough context for zero-memory resumption]

    ## What WORKED (with evidence)
    - **[thing]** — confirmed by: [specific evidence]

    ## What Did NOT Work (and why)
    - **[approach]** — failed because: [exact reason / error]

    ## What Has NOT Been Tried Yet
    - [approach / idea]

    ## Current State of Files
    | File | Status | Notes |
    | --- | --- | --- |

    ## Decisions Made
    - **[decision]** — reason: [why]

    ## Blockers & Open Questions
    - [blocker / question]

    ## Exact Next Step
    [single most important thing to do when resuming]
    ```

    ### Step 5: Show file to user and confirm

    The "What Did NOT Work" section is the most critical — future sessions will blindly retry failed approaches without it.
  '';

  cmdResumeSession = ''
    ---
    description: Load the most recent session file from ~/.claude/sessions/ and resume work with full context.
    ---

    # Resume Session Command

    Load the last saved session state and orient fully before doing any work.

    ## Process

    ### Step 1: Find the session file
    - Check `~/.claude/sessions/`
    - Pick the most recently modified `*-session.tmp` file
    - If none found, tell user to run `/save-session` first

    ### Step 2: Read the entire session file

    ### Step 3: Confirm understanding

    ```
    SESSION LOADED: [path]

    PROJECT: [project / topic]

    WHAT WE'RE BUILDING:
    [2-3 sentence summary]

    CURRENT STATE:
    Working: [count] items confirmed
    In Progress: [list]
    Not Started: [list]

    WHAT NOT TO RETRY:
    [list every failed approach with reason]

    OPEN QUESTIONS / BLOCKERS:
    [list]

    NEXT STEP:
    [exact next step if defined]

    Ready to continue. What would you like to do?
    ```

    ### Step 4: Wait for the user

    Do NOT start working automatically. Do NOT touch any files.

    **Edge Cases:**
    - Session > 7 days old: warn things may have changed
    - Referenced files no longer exist: note in briefing
    - Multiple sessions same date: load most recent
  '';

  cmdLearn = ''
    # /learn - Extract Reusable Patterns

    Analyze the current session and extract any patterns worth saving as skills.

    ## What to Extract

    1. **Error Resolution Patterns** - What error, root cause, fix, reusability
    2. **Debugging Techniques** - Non-obvious steps, tool combinations
    3. **Workarounds** - Library quirks, API limitations, version-specific fixes
    4. **Project-Specific Patterns** - Conventions, architecture decisions

    ## Output Format

    Create a skill file at `~/.claude/skills/learned/[pattern-name].md`:

    ```markdown
    # [Descriptive Pattern Name]

    **Extracted:** [Date]
    **Context:** [When this applies]

    ## Problem
    [What problem this solves]

    ## Solution
    [The pattern/technique/workaround]

    ## Example
    [Code example if applicable]

    ## When to Use
    [Trigger conditions]
    ```

    ## Process

    1. Review the session for extractable patterns
    2. Identify the most valuable/reusable insight
    3. Draft the skill file
    4. Ask user to confirm before saving
    5. Save to `~/.claude/skills/learned/`

    ## Notes

    - Don't extract trivial fixes (typos, simple syntax errors)
    - Don't extract one-time issues
    - Focus on patterns that will save time in future sessions
    - Keep skills focused - one pattern per skill
  '';

  # ════════════════════════════════════════════════════════════════════════
  # SKILLS (deployed to ~/.claude/skills/<name>/SKILL.md)
  # These are automatically loaded by Claude Code when relevant
  # ════════════════════════════════════════════════════════════════════════

  skillSearchFirst = ''
    ---
    name: search-first
    description: Research-before-coding workflow. Search for existing tools, libraries, and patterns before writing custom code.
    origin: ECC
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

    ## Quick Mode (inline)

    Before writing a utility or adding functionality:

    0. Does this already exist in the repo? — `rg` through relevant modules
    1. Is this a common problem? — Search nixpkgs / PyPI / npm
    2. Is there an MCP for this? — Check settings.json
    3. Is there a skill for this? — Check `~/.claude/skills/`
    4. Is there a GitHub implementation? — Search GitHub for maintained OSS

    ## Anti-Patterns

    - **Jumping to code**: Writing a utility without checking if one exists
    - **Ignoring nixpkgs**: Not checking if a Nix package already provides the capability
    - **Over-customizing**: Wrapping a library so heavily it loses its benefits
    - **Dependency bloat**: Installing a massive package for one small feature
  '';

  skillVerificationLoop = ''
    ---
    name: verification-loop
    description: "Comprehensive verification system for Claude Code sessions. Run build, type check, lint, tests, and security scan after completing changes."
    origin: ECC
    ---

    # Verification Loop Skill

    ## When to Use

    - After completing a feature or significant code change
    - Before creating a PR or committing
    - After refactoring
    - When you want to ensure quality gates pass

    ## Verification Phases

    ### Phase 1: Build Verification
    ```bash
    # NixOS projects
    nix flake check
    # Python projects
    python -m py_compile *.py
    # Node projects
    npm run build 2>&1 | tail -20
    ```
    If build fails, STOP and fix before continuing.

    ### Phase 2: Type Check
    ```bash
    # Python
    pyright . 2>&1 | head -30
    # or mypy
    mypy . 2>&1 | head -30
    ```

    ### Phase 3: Lint Check
    ```bash
    # Python
    ruff check . 2>&1 | head -30
    # Shell
    shellcheck *.sh 2>&1 | head -30
    ```

    ### Phase 4: Test Suite
    Run tests with coverage. Target: 80% minimum.

    ### Phase 5: Security Scan
    Check for hardcoded secrets, API keys, tokens in source files.

    ### Phase 6: Diff Review
    ```bash
    git diff --stat
    git diff HEAD~1 --name-only
    ```

    ## Output Format

    ```
    VERIFICATION REPORT
    ==================

    Build:     [PASS/FAIL]
    Types:     [PASS/FAIL] (X errors)
    Lint:      [PASS/FAIL] (X warnings)
    Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
    Security:  [PASS/FAIL] (X issues)
    Diff:      [X files changed]

    Overall:   [READY/NOT READY] for PR

    Issues to Fix:
    1. ...
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
      complex multi-PR task, or describes work that needs multiple sessions.
      DO NOT TRIGGER when: task is completable in a single PR or fewer
      than 3 tool calls, or user says "just do it".
    origin: ECC (community)
    ---

    # Blueprint — Construction Plan Generator

    Turn a one-line objective into a step-by-step construction plan that any coding agent can execute cold.

    ## When to Use

    - Breaking a large feature into multiple PRs with clear dependency order
    - Planning a refactor or migration that spans multiple sessions
    - Coordinating parallel workstreams across sub-agents
    - Any task where context loss between sessions would cause rework

    **Do not use** for tasks completable in a single PR or fewer than 3 tool calls.

    ## How It Works

    Blueprint runs a 5-phase pipeline:

    1. **Research** — Pre-flight checks (git, gh auth, remote, default branch), reads project structure, existing plans, and memory files.
    2. **Design** — Breaks objective into one-PR-sized steps (3-12 typical). Assigns dependency edges, parallel/serial ordering, model tier, and rollback strategy per step.
    3. **Draft** — Writes a self-contained Markdown plan file to `plans/`. Every step includes context brief, task list, verification commands, and exit criteria.
    4. **Review** — Adversarial review against checklist and anti-pattern catalog. Fixes critical findings before finalizing.
    5. **Register** — Saves the plan, updates memory index, presents summary to user.

    ## Key Features

    - **Cold-start execution** — Every step includes a self-contained context brief
    - **Adversarial review gate** — Plan reviewed against completeness, dependency correctness, anti-patterns
    - **Parallel step detection** — Dependency graph identifies parallelizable steps
    - **Plan mutation protocol** — Steps can be split, inserted, skipped, reordered with audit trail
    - **Git-aware** — Detects git/gh and generates branch/PR workflow; degrades gracefully to direct mode

    ## Usage

    ```
    /blueprint <project> "<objective>"
    ```

    Example:
    ```
    /blueprint dotfiles "migrate hyprland config to use hyprsession"
    ```
  '';

  skillSecurityScan = ''
    ---
    name: security-scan
    description: Scan your Claude Code configuration (.claude/ directory) for security vulnerabilities, misconfigurations, and injection risks. Checks CLAUDE.md, settings.json, MCP servers, hooks, and agent definitions.
    origin: ECC
    ---

    # Security Scan Skill

    Audit your Claude Code configuration for security issues.

    ## When to Activate

    - Setting up a new Claude Code project
    - After modifying `.claude/settings.json`, `CLAUDE.md`, or MCP configs
    - Before committing configuration changes
    - Periodic security hygiene checks

    ## What It Scans

    | File | Checks |
    |------|--------|
    | `CLAUDE.md` | Hardcoded secrets, auto-run instructions, prompt injection patterns |
    | `settings.json` | Overly permissive allow lists, missing deny lists, dangerous bypass flags |
    | `mcp.json` | Risky MCP servers, hardcoded env secrets, npx supply chain risks |
    | `hooks/` | Command injection via interpolation, data exfiltration, silent error suppression |
    | `agents/*.md` | Unrestricted tool access, prompt injection surface, missing model specs |

    ## Manual Scan Checklist

    If AgentShield is not available, manually check:

    1. **settings.json permissions**
       - No `Bash(*)` in allow list
       - Deny list covers sensitive paths (~/.ssh, ~/.aws, etc.)
       - No hardcoded API keys or tokens

    2. **CLAUDE.md / project rules**
       - No auto-run instructions that bypass user confirmation
       - No hardcoded secrets or tokens
       - No instructions to ignore security policies

    3. **Hooks**
       - No command injection via variable interpolation
       - No silent error suppression (2>/dev/null, || true)
       - No data exfiltration (curl/wget to external URLs)

    4. **MCP configs**
       - No shell-running MCP servers without justification
       - No hardcoded secrets (use env vars)
       - Minimal npx auto-install usage

    ## Severity Levels

    | Level | Action |
    |-------|--------|
    | CRITICAL | Fix immediately — hardcoded keys, unrestricted shell |
    | HIGH | Fix before production — missing deny lists, auto-run |
    | MEDIUM | Recommended — silent error suppression, missing hooks |
    | INFO | Awareness — missing descriptions, good practices noted |
  '';

in
{
  # ── Slash Commands ──────────────────────────────────────────────────────
  home.file.".claude/commands/plan.md".text = cmdPlan;
  home.file.".claude/commands/code-review.md".text = cmdCodeReview;
  home.file.".claude/commands/refactor-clean.md".text = cmdRefactorClean;
  home.file.".claude/commands/build-fix.md".text = cmdBuildFix;
  home.file.".claude/commands/checkpoint.md".text = cmdCheckpoint;
  home.file.".claude/commands/verify.md".text = cmdVerify;
  home.file.".claude/commands/save-session.md".text = cmdSaveSession;
  home.file.".claude/commands/resume-session.md".text = cmdResumeSession;
  home.file.".claude/commands/learn.md".text = cmdLearn;

  # ── Skills ──────────────────────────────────────────────────────────────
  home.file.".claude/skills/search-first/SKILL.md".text = skillSearchFirst;
  home.file.".claude/skills/verification-loop/SKILL.md".text = skillVerificationLoop;
  home.file.".claude/skills/blueprint/SKILL.md".text = skillBlueprint;
  home.file.".claude/skills/security-scan/SKILL.md".text = skillSecurityScan;
}
