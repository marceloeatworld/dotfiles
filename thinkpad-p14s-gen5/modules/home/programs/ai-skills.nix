# Centralized AI agent skills for Claude Code, ForgeCode, OpenCode, and Codex
# First rebuild clones missing repos, subsequent rebuilds only redistribute the cache
# Refresh with network: update-skills (shell function in overlay-updates.nix)
# The two always-on skills (caveman, i-have-adhd) are pinned below instead:
# they load with CLAUDE.md authority in every session, so their content must
# not change behind a `git pull`. Bump rev and hash to update them.
{ config, pkgs, ... }:

let
  # ── Skill destinations for each tool ──
  claudeSkills = "$HOME/.claude/skills";
  forgeSkills = "$HOME/.forge/skills";
  opencodeSkills = "$HOME/.config/opencode/skills";
  codexSkills = "$HOME/.codex/skills";
  allSkillDirs = "${claudeSkills} ${forgeSkills} ${opencodeSkills} ${codexSkills}";

  cache = "$HOME/.cache/ai-skills";

  # Pinned sources for the always-on skills imported by the global CLAUDE.md.
  cavemanSrc = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "9b68f7ed12b05e7efaff18e65c5a3fc2849fd0a4"; # 2026-10-25
    hash = "sha256-fuSsPP7GMuAZ5Ab2paS41RAo5k/objd503ElcMeMgsk=";
  };
  # Skills vendored in this repo (modules/home/programs/skills/<name>/SKILL.md).
  localSkills = ./skills;
  # Marketing skills (MIT). 52 skills upstream; only the ones below are
  # installed, all of which read the shared `.agents/product-marketing.md`
  # that product-marketing creates.
  marketingSrc = pkgs.fetchFromGitHub {
    owner = "coreyhaines31";
    repo = "marketingskills";
    rev = "e85f3cbc2e4a79bf33b2a12e9bdd9087d414735b"; # 2026-10-22
    hash = "sha256-7vfgajBoZMtgct2IZwqFoQrAoKkrMrK8jc644NdNju4=";
  };

  # Prompt pack rather than an executable or upstream SKILL.md.
  bugBountySrc = pkgs.fetchFromGitHub {
    owner = "mdpsec";
    repo = "bug-bounty-hunting-prompts";
    rev = "5ed41580564c978417d5f0105f9c92457d77f3b5";
    hash = "sha256-d7tZdbpb1754Z4iD1YUoDCo4MA2Bj/jDdxuQyJR/aS4=";
  };
  # Google Mantis (Apache 2.0): vulnerability review pipeline as prompt-only
  # skills. The ADK/LiteLLM reference harness in reference/ is not installed;
  # the agent runs the stages itself and keeps state under workspace/.
  mantisSrc = pkgs.fetchFromGitHub {
    owner = "google";
    repo = "mantis";
    rev = "f3162c039ecd9c9d5d8bc404dd1373c7ca3152f7"; # 2026-10-25
    hash = "sha256-L0sq1MXicjx+81s9/lLxF0EK3pzJRjDOjPhhlHtvdv0=";
  };
  bugBountySkill = pkgs.writeText "bug-bounty-hunting-SKILL.md" ''
    ---
    name: bug-bounty-hunting
    description: Adapt phase-based bug bounty prompts for an authorized target, from reconnaissance to evidence and report triage.
    ---

    # Bug bounty hunting prompts

    Read [README.md](README.md) for the phase map, then
    [ADAPTATION.md](ADAPTATION.md) before selecting a prompt from `phases/`.
    This is a reference pack, not a scanner or a configured hunting service.
    Resolve scope, workspace paths and required integrations for the selected
    phase; never execute unresolved `YOUR_*` or template placeholders.
    Load one phase at a time and preserve its evidence and handoff artifacts.
    Follow the program's current scope and the user's requested actions.
  '';
  bugBountySkills = pkgs.runCommand "bug-bounty-hunting-skills" { } ''
    mkdir -p "$out/bug-bounty-hunting"
    cp -r ${bugBountySrc}/{README.md,ADAPTATION.md,SECURITY.md,LICENSE,phases} "$out/bug-bounty-hunting/"
    cp ${bugBountySkill} "$out/bug-bounty-hunting/SKILL.md"
  '';

  # @cloudflare/oxlint-config (Apache 2.0): the Oxlint preset every agent
  # applies by default (rule text in agent-rules/js-ts-lint.md, loaded by the
  # global CLAUDE.md and ~/.codex/AGENTS.md). Only its migration skill is
  # distributed; the preset itself is an npm dependency of each project.
  oxlintConfigSrc = pkgs.fetchFromGitHub {
    owner = "cloudflare";
    repo = "oxlint-config";
    rev = "4dd1bb82e63eac925f31917f22d09a8650b26bd5"; # 2026-11-23, v0.2.0
    hash = "sha256-wRDsJaMEc2U1FFDtCudV1xgGA4gkqfGp5E4unAfIbIg=";
  };
  # Factory ESLint plugin (Apache 2.0): an ESLint package, not a skill, and
  # unmaintained upstream. Wrapped as a reference pack: the per-rule READMEs,
  # sources and tests are what an agent adapts into a project's own rules.
  factoryEslintSrc = pkgs.fetchFromGitHub {
    owner = "Factory-AI";
    repo = "eslint-plugin";
    rev = "e713ca4f0376c4389a80a8dff23da368a487e8f5"; # 2026-02-03
    hash = "sha256-He68PCnQ0hv9zobBZC1UWQmyI87/p4EiNvb0zA7RYyk=";
  };
  factoryEslintSkill = pkgs.writeText "factory-eslint-rules-SKILL.md" ''
    ---
    name: factory-eslint-rules
    description: Adapt Factory's agent-steering ESLint rules into a project's own lint setup. Use when adding custom lint rules.
    ---

    # Factory ESLint rules

    This is a reference pack, not an installed linter. Upstream is unmaintained
    and recommends against importing the package: take the ideas and write
    rules that fit the target repository.

    1. Read [README.md](README.md) for the rule index and the four configs.
    2. For each rule the user wants, read `rules/<rule-name>/README.md`
       (rationale, incorrect and correct examples), then `index.js` and
       `index.test.js` in the same directory for the implementation and cases.
    3. `configs/` shows how the rules combine for base, recommended, frontend
       and backend projects. `package.json` lists the third-party plugins
       those configs depend on.
    4. Port the selected rules into the target repository's own local plugin.
       Match its linter (ESLint flat or legacy config, or Oxlint JS plugins),
       file layout and naming, and keep the rule tests.
    5. Run the repository's lint and tests. Report findings in project source
       and fix them only when the user asked for cleanup.

    Do not enable a whole config or add `@factory/eslint-plugin` as a
    dependency unless the user asks for it. Several rules encode Factory
    conventions (`require-v0-*` routes, `logError`/`logException` helpers,
    the `test-utils/` layout): adapt the names and paths or leave them out.
  '';
  factoryEslintSkills = pkgs.runCommand "factory-eslint-rules-skills" { } ''
    mkdir -p "$out/factory-eslint-rules"
    cp -r ${factoryEslintSrc}/{README.md,LICENSE,package.json,index.js,configs,rules} "$out/factory-eslint-rules/"
    cp ${factoryEslintSkill} "$out/factory-eslint-rules/SKILL.md"
  '';

  # Keep skills at the exact CLI source revision, with their referenced assets.
  universalModderSkills = pkgs.runCommand "universal-modder-skills" { } ''
    cp -r ${pkgs.universal-modder.src}/skills "$out"
    chmod -R u+w "$out"
    for skill in "$out"/*; do
      ln -s ${pkgs.universal-modder}/share/universal-modder/examples "$skill/examples"
      ln -s ${pkgs.universal-modder}/share/universal-modder/knowledge "$skill/knowledge"
      ln -s ${pkgs.universal-modder.src}/um "$skill/um"
      substituteInPlace "$skill/SKILL.md" \
        --replace-quiet 'skills/mod-any-game/' '../mod-any-game/'
      cat > "$skill/NIXOS.md" <<'EOF'
    # Local NixOS integration

    `um` is installed through Nix. Do not run the upstream pip/uv installers.
    `examples/` and `knowledge/` contain the pinned upstream support files.
    `um kb search` and `um kb show` default to this read-only knowledge snapshot;
    use `--root` for another corpus. For contributions, first copy `knowledge/`
    into a writable workspace (including TEMPLATE.md) and make that copy writable,
    then use `um kb new --root <workspace>/knowledge`.
    `um win` requires Windows or WSL; it cannot drive this Hyprland desktop.
    3D rendering needs Blender on PATH or BLENDER; fal calls need FAL_KEY.
    Publishing and paid generation require the user's requested scope.
    EOF
    done
    ${pkgs.python313}/bin/python - "$out" <<'PY'
    import pathlib, sys
    for skill in pathlib.Path(sys.argv[1]).glob('*/SKILL.md'):
        head, body = skill.read_text().split('\n---\n', 1)
        skill.write_text(head + '\n---\n\nRead [NIXOS.md](NIXOS.md) for the installed CLI and platform limits.\n' + body)
    PY
  '';

  reaSkills = pkgs.runCommand "rea-skills" { } ''
    mkdir -p "$out"
    cp -r ${pkgs.rea.src}/.agents/skills/reverse-engineer-anything "$out/"
    chmod -R u+w "$out"
    # Use the packaged version; upstream setup would rewrite agent configs.
    substituteInPlace "$out/reverse-engineer-anything/SKILL.md" \
      --replace-fail 'npx -y rea-agents@latest' 'rea'
    cat >> "$out/reverse-engineer-anything/SKILL.md" <<'EOF'

    ## Local NixOS integration

    `rea` is installed by Nix and the `rea` MCP server is configured for Claude.
    Use the CLI in agents without that MCP registration. Manage packages and
    registration through this flake rather than `rea setup` or its installers.
    REA 6.8.0 requires exactly Ghidra 12.1.4 and JDK 21; the `rea` MCP wrapper
    in claude-code.nix points it at the source-built nixpkgs Ghidra, the same
    tree the GUI uses.
    Hopper needs a separate installation/license.
    EOF
  '';

  # Local-only Strix skill set, taken from the same pinned source the CLI is
  # built from. Upstream also documents the managed cloud, whose repo-scan
  # command uploads the working tree, and recommends it whenever a local
  # prerequisite is missing. The cloud and CI skills are not distributed, so
  # that path is cut here too: the chooser section, the whole cloud option and
  # the curl installer are removed, and a local-only note is prepended.
  strixSkills = pkgs.runCommand "strix-skills" { } ''
    mkdir -p "$out"
    for name in penetration-testing-with-strix find-security-vulnerabilities-in-code \
                fix-security-vulnerabilities-with-strix owasp-top-10-testing \
                api-security-testing; do
      cp -r ${pkgs.strix.src}/skills/"$name" "$out/$name"
    done
    chmod -R u+w "$out"
    substituteInPlace "$out/penetration-testing-with-strix/SKILL.md" \
      --replace-fail 'curl -sSL https://strix.ai/install | bash   # or: pipx install strix-agent' \
                     'strix --version   # installed by Nix; never run an upstream installer'
    ${pkgs.python313}/bin/python - "$out" <<'PY'
    import pathlib, sys

    note = """
    > **Local-only install (NixOS).** `strix` is installed by Nix. Never run an
    > upstream installer. Run every scan locally: do not run any `strix cloud`
    > command and never upload source or a working tree to app.strix.ai. The
    > managed-cloud and CI skills are deliberately not installed, so references
    > to them cannot be followed. The sandbox container needs the rootless
    > Podman socket (`DOCKER_HOST`). `STRIX_LLM` defaults to
    > `gemini/gemini-4-carbon` with the local `GEMINI_API_KEY`. `strix view` has
    > no bundled dashboard; read `strix_runs/<run>/` directly. Only test targets
    > the user owns or has written permission to test.

    """
    root = pathlib.Path(sys.argv[1])
    main = root / 'penetration-testing-with-strix' / 'SKILL.md'
    text = main.read_text()
    # Both blocks end at the next horizontal rule.
    for start in ('## Which one?', '# Option B'):
        i = text.index(start)
        text = text[:i] + text[text.index('\n---\n', i) + 5:]
    main.write_text(text)
    for skill in sorted(root.glob('*/SKILL.md')):
        head, body = skill.read_text().split('\n---\n', 1)
        skill.write_text(head + '\n---\n' + note + body)
    PY
    ${pkgs.gnugrep}/bin/grep -rq 'strix cloud scans start --source' "$out" && exit 1
    ${pkgs.gnugrep}/bin/grep -rq 'strix.ai/install' "$out" && exit 1
    true
  '';

  # Helper: clone a git repo if missing (no pull — refresh via `update-skills`)
  # Keeps rebuilds fast and offline-capable; existing caches are left untouched.
  gitSync = ''
    _git_sync() {
      local dir="$1" url="$2"
      if [ ! -d "$dir/.git" ]; then
        $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c "rm -rf '$dir' && mkdir -p '$(dirname "$dir")' && ${pkgs.git}/bin/git clone --quiet '$url' '$dir'" 2>/dev/null || true
        # A failed clone (offline) must be retried on the next activation.
        [ -d "$dir/.git" ] || AI_SKILLS_CLONE_FAILED=1
      fi
    }
  '';

  # Helper: skip the redistribution when its inputs are unchanged. It rewrites
  # ~100 skills into 4 tool directories, which took 6-14 s on every activation,
  # including the boot-time one that runs before the login prompt
  # (home-manager-<user>.service is ordered before systemd-user-sessions).
  # Inputs: the Home Manager generation (skill list, pinned store sources) and
  # the HEAD of every cached clone (moved by `update-skills`).
  # Force a full reinstall with: rm ~/.cache/ai-skills/.install-stamp
  installStamp = ''
    _ai_skills_stamp_key() {
      {
        ${pkgs.coreutils}/bin/printf '%s\n' "$newGenPath"
        for repo in "${cache}"/*/; do
          [ -d "$repo.git" ] || continue
          ${pkgs.coreutils}/bin/printf '%s ' "$repo"
          ${pkgs.git}/bin/git -C "$repo" rev-parse HEAD 2>/dev/null || echo unknown
        done
      } | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1
    }

    _ai_skills_up_to_date() {
      [ -z "''${DRY_RUN_CMD:-}" ] || return 1
      [ -f "${cache}/.install-stamp" ] || return 1
      for dest in ${allSkillDirs}; do
        [ -d "$dest" ] || return 1
      done
      [ "$(${pkgs.coreutils}/bin/cat "${cache}/.install-stamp")" = "$(_ai_skills_stamp_key)" ]
    }

    _ai_skills_write_stamp() {
      [ -z "''${DRY_RUN_CMD:-}" ] || return 0
      [ -z "''${AI_SKILLS_CLONE_FAILED:-}" ] || return 0
      ${pkgs.coreutils}/bin/mkdir -p "${cache}"
      _ai_skills_stamp_key > "${cache}/.install-stamp"
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
          $DRY_RUN_CMD chmod -R u+w "$dest/$name"  # sources from /nix/store are read-only
          if [ -z "''${DRY_RUN_CMD:-}" ]; then
            _ai_skills_record "$dest/$name"
            _compact_codex_skill_descriptions "$dest/$name"
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

        for dir in references scripts assets templates examples forge grimoire; do
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


  helpers = "${gitSync}\n${installStamp}\n${managedSkillLifecycle}\n${compactCodexSkillDescriptions}\n${copyNamedSkills}\n${copySkillRepo}";

  # ════════════════════════════════════════════════════════════════════════
  # INLINE SKILLS (deployed as SKILL.md to all tools)
  # ════════════════════════════════════════════════════════════════════════

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

  # SKILL.md wrapper for modern-web-guidance: a local router over the guides
  # synced from GoogleChrome/modern-web-guidance. The upstream SKILL.md is not
  # installed: it runs `npx -y modern-web-guidance@latest` on every use
  # (unpinned npm code), and that CLI sends the agent's search queries to
  # Google as telemetry. Its only opt-out is DISABLE_TELEMETRY, which must
  # stay unset here because it hides Claude Code features.
  skillModernWebGuidance = ''
    ---
    name: modern-web-guidance
    description: >-
      Current web platform best practices from the Chrome team. Use before
      writing or reviewing browser-side HTML, CSS or client-side JavaScript:
      dialogs, popovers, forms and validation, autofill, focus management
      and accessibility, dark mode, animations and reduced motion, view
      transitions, scroll and swipe behavior, Core Web Vitals (LCP, INP,
      CLS), DOM XSS and HTML sanitization, CSP, passkeys. Not for backend
      code, infrastructure, build tooling or tests.
    metadata:
      source: https://github.com/GoogleChrome/modern-web-guidance
    ---

    # Modern Web Guidance (local copy)

    Guides from the Chrome team on current web platform practice. Training
    data holds obsolete patterns for these topics, so read the matching
    guide before writing the code.

    Everything here is local. Never run `npx modern-web-guidance` or
    `pnpx modern-web-guidance`: that CLI is left out on purpose because it
    runs unpinned npm code and sends search queries to Google.

    ## Find a guide

    1. Search `INDEX.md` in this directory for the UI pattern or platform
       feature, with one keyword at a time (for example `dialog`,
       `autofill`, `passkey`, `motion`). Each line is
       `guides/<category>/<id>.md: <description>`. Do not read the whole
       file.
    2. No match: search the guide bodies under `guides/` for the API,
       property or attribute name.
    3. Read every matching guide in full before writing code. Still no
       match: the topic is not covered, so proceed without a guide.

    Some categories also have a broad discipline guide named after the
    category, for example `guides/accessibility/accessibility.md`,
    `guides/forms/forms.md`, `guides/performance/performance.md` and
    `guides/security/security.md`. Read it when the task covers the whole
    area and not one pattern.

    ## Cross-references between guides

    Guides point to each other as
    `npx -y modern-web-guidance@latest retrieve "<id>"`. Do not run that
    command. Read `guides/*/<id>.md` instead: every id is a unique file
    name.

    ## Applying a guide

    - Guides use plain HTML, CSS and JavaScript. Adapt them to the
      project's framework and keep the modern feature.
    - Baseline Widely available features need no fallback. For anything
      newer, follow the fallback the guide gives, unless the project states
      its own browser support policy.
    - Apply only what the task needs. Do not add features nobody asked for.

    ## Upstream

    - Repo: https://github.com/GoogleChrome/modern-web-guidance
    - Refreshed by `update-skills`
  '';

  modernWebGuidanceSkillFile = pkgs.writeText "modern-web-guidance-SKILL.md" skillModernWebGuidance;

  copyModernWebGuidanceSkill = ''
    _copy_modern_web_guidance_skill() {
      local src="$1"
      [ -d "$src/skills/modern-web-guidance/guides" ] || return 0

      for dest in ${allSkillDirs}; do
        $DRY_RUN_CMD mkdir -p "$dest"
        $DRY_RUN_CMD rm -rf "$dest/modern-web-guidance"
        $DRY_RUN_CMD mkdir -p "$dest/modern-web-guidance"
        $DRY_RUN_CMD cp "${modernWebGuidanceSkillFile}" "$dest/modern-web-guidance/SKILL.md"
        $DRY_RUN_CMD cp -r "$src/skills/modern-web-guidance/guides" "$dest/modern-web-guidance/guides"

        if [ -f "$src/LICENSE" ]; then
          $DRY_RUN_CMD cp "$src/LICENSE" "$dest/modern-web-guidance/LICENSE"
        fi

        if [ -z "''${DRY_RUN_CMD:-}" ]; then
          # INDEX.md: one `guides/<category>/<id>.md: <description>` line per
          # guide, taken from the catalog in the upstream README.
          if [ -f "$src/README.md" ]; then
            ${pkgs.gnused}/bin/sed -n 's|^- \*\*\[[^]]*\](https://github.com/GoogleChrome/modern-web-guidance/blob/main/skills/modern-web-guidance/\(guides/[^)]*\))\*\*: |\1: |p' \
              "$src/README.md" > "$dest/modern-web-guidance/INDEX.md"
          fi
          _ai_skills_record "$dest/modern-web-guidance"
          _compact_codex_skill_descriptions "$dest/modern-web-guidance"
        fi
      done
    }
  '';

  # ════════════════════════════════════════════════════════════════════════
  # LOCAL SKILLS (hand-written here, distributed to every agent CLI)
  # ════════════════════════════════════════════════════════════════════════

  # seo: one skill, five workflows. SKILL.md is the router written here;
  # four reference bodies come from Illyism/seo-skills (MIT, pinned; the
  # linkdr, scribiz, blitz-* and other vendor or prompt-template skills are
  # omitted) and parasite-seo is local.
  seoSkillsSrc = pkgs.fetchFromGitHub {
    owner = "Illyism";
    repo = "seo-skills";
    rev = "a47acc9d28ceebe5d4845cda29113a6c07781bca"; # 2026-10-06
    hash = "sha256-sS/I8hXhQT+uXsByS4gqKA3WGZi0qvOvKoU11DuoCbw=";
  };

  seoSkillFile = pkgs.writeText "seo-SKILL.md" ''
    ---
    name: seo
    description: >-
      SEO and content marketing workflows. Use for any SEO request: run SEO
      for a product end to end on a daily schedule ("seo autopilot"), audit
      or rewrite page titles, title tags and H1s for CTR, refresh an existing
      blog post that fell behind competitors with a SERP gap analysis, turn
      commits and merged PRs into changelogs, posts and emails ("diff
      marketing"), or rank a page fast by publishing on a high-authority
      third-party platform ("parasite SEO", "rank on LinkedIn", Cody
      Schneider's 38-minute workflow). Also triggers on keyword map, search
      intent, meta description, SERP, indexing, backlinks, and AI answer
      tracking (ChatGPT, Perplexity, AI Overviews).
    ---

    # SEO

    One skill, five workflows. Pick the one that matches the request, then
    read only that reference file.

    | Request | Read |
    | --- | --- |
    | Run SEO for a site end to end (daily, weekly, monthly; state kept in `seo/` in the repo) | [references/seo-autopilot.md](references/seo-autopilot.md) |
    | Audit or rewrite titles, title tags, H1s, meta titles; CTR, truncation, bulk title pass | [references/seo-title-optimization.md](references/seo-title-optimization.md) |
    | Refresh an existing post, recover lost rankings, explain why a post fell behind | [references/blog-refresher.md](references/blog-refresher.md) |
    | Turn commits, merged PRs or a release into a changelog, posts, emails | [references/diff-marketing.md](references/diff-marketing.md) |
    | Rank one query fast on LinkedIn, Medium, Substack or Reddit instead of the own site | [references/parasite-seo.md](references/parasite-seo.md) |

    ## Rules for every workflow

    - Treat the SERP as the brief: search the query and read what ranks
      before writing or rewriting anything.
    - Use real data (Search Console, analytics, web search, page fetches).
      If a source is missing, say so once and carry on. Never fill the gap
      with a guess.
    - Never invent a statistic, quote, customer, price, benchmark or ranking
      result. Do not promise ranking or traffic gains.
    - Answer the query in the first two sentences of any page, then give the
      detail.
    - Draft, do not ship: no emails sent, no directory submissions, no social
      posts, no account creation. Hand the owner ready-to-paste copy.
    - The upstream references mention LinkDR and AI SEO Tracker. Those are the
      author's paid tools; ignore them unless the user asks for them.
  '';

  seoParasiteRef = ''
    # Parasite SEO

    Borrow the domain authority of a platform Google already trusts to rank an
    article for one target query, fast. One article, one query. Source: Cody
    Schneider live demo (ranked position one on Google in 38 minutes with a
    LinkedIn article for "Facebook ads for kitchen remodeling").

    Why it works: the pages on page one already show the shape of content
    Google wants for that query. Feed that shape to the model, add something
    only the brand can say, publish on a domain with authority, then get the
    URL crawled quickly.

    ## Workflow

    1. **Pick one target query.** Long-tail, commercial intent, low to medium
       competition. One query per article. Write it down exactly as searched.
    2. **Research the current SERP.** Fetch the top 5 to 10 organic results
       for the query. Extract the main body text of each page (headings,
       sections, FAQs, word count, angle). Skip ads and the platform's own
       pages. Save the extracts as the source material.
    3. **Collect the brand's point of view (recommended).** For a brand,
       get a transcript of a 20 to 30 minute conversation with the founder:
       unique positioning, how they fit in the market, their thesis on the
       industry, objections they hear, concrete examples. If no transcript
       exists, ask the user for notes or a call recording. This step is what
       makes the article more than a remix.
    4. **Write the article.** Use the prompt below. Match the shape of what
       ranks (sections, depth, length), but write it in the brand's voice and
       weave the founder's point of view through it. The exact query must be
       the title. Review the draft with the user before publishing.
    5. **Publish on the host platform.** Default: LinkedIn article (Create a
       post, Write article). Paste the article, set the title to the exact
       query so it becomes the URL slug, use the intro section as the post
       text, publish. Copy the resulting URL.
    6. **Get it indexed.** Submit the published URL to a drip-ping indexing
       service (the demo used Prime Indexer). Warning below.
    7. **Verify.** Check the Google result page for the query after 30 to
       60 minutes, then again after 24 hours. Report position and URL.

    ## Writing prompt

    ```
    Write an article for the target keyword "<QUERY>" based on the following
    source text from the pages currently ranking on Google for that query.

    Requirements:
    - Title: exactly "<QUERY>".
    - Match the structure and depth of the ranking pages (sections, FAQs,
      length), but do not copy sentences.
    - Open with a short intro that can stand alone as a social post.
    - Where the founder transcript gives a position or example, use it and
      attribute it to <BRAND>. Do not invent claims, numbers, or quotes.
    - Plain language, scannable headings, no filler.

    Source text (ranking pages):
    <SERP EXTRACTS>

    Founder transcript (<BRAND> point of view):
    <TRANSCRIPT OR "none">
    ```

    ## Warnings

    - **Never use a drip-ping indexer on the brand's own website.** Only on
      the third-party host page. The demo was explicit about this.
    - **No guarantee.** The demo was one article, one query, one live test.
      Another keyword, platform, or niche may not rank, or may rank and then
      drop. Say so when reporting.
    - **Platform rules.** Respect the host platform's content policy. Do not
      mass-publish near-duplicate articles or spam several platforms with the
      same text; that gets accounts and pages removed.
    - **Review before publishing.** Check facts, brand claims, and anything
      taken from the founder transcript. The model drafts, the human ships.

    ## Checklist to hand back

    - Target query
    - Pages used as source (URLs)
    - Founder context used (yes or no)
    - Published URL
    - Indexing submitted (yes or no, service)
    - Google position at first check, with timestamp
  '';

  seoParasiteRefFile = pkgs.writeText "parasite-seo.md" seoParasiteRef;

  seoSkills = pkgs.runCommand "seo-skills" { } ''
    mkdir -p "$out/seo/references"
    cp ${seoSkillFile} "$out/seo/SKILL.md"
    cp ${seoParasiteRefFile} "$out/seo/references/parasite-seo.md"
    # Upstream SKILL.md bodies become reference files: drop their frontmatter
    # so only the top-level SKILL.md declares a skill.
    for path in seo/seo-autopilot seo/seo-title-optimization seo/blog-refresher marketing/diff-marketing; do
      awk 'seen >= 2 { print } /^---$/ { seen++ }' \
        "${seoSkillsSrc}/$path/SKILL.md" > "$out/seo/references/$(basename "$path").md"
    done
  '';

  # ════════════════════════════════════════════════════════════════════════
  # SLASH COMMANDS (Claude Code only — ~/.claude/commands/)
  # ════════════════════════════════════════════════════════════════════════

  cmdPlan = ''
    ---
    description: Restate requirements, assess risks, and create step-by-step implementation plan. WAIT for user CONFIRM before touching any code.
    ---

    # Plan Command

    Restate the requirements, then write a plan: phases with concrete steps, the dependencies between components, the risks and likely blockers. Present the plan and wait for the user's explicit confirmation before editing any file.
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

    1. **Detect Build System** — flake.nix → `nix flake check`, package.json → its `build` script, run with the project's package manager, etc.
    2. **Parse and Group Errors** — By file, sorted by dependency order
    3. **Fix Loop** — Read file, diagnose, fix minimally, re-run build, move to next
    4. **Guardrails** — Stop if fix introduces more errors, same error persists twice, or needs architecture changes
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

    1. **Find the project's recipe first.** Use the "Validation" or "Verification" section of its AGENTS.md or CLAUDE.md, else the scripts in package.json, Makefile or justfile. Fall back to the generic order above only when the project documents nothing.
    2. **Run cheap checks first.** Syntax, flake check or type check, lint. Then the build, then the tests.
    3. **Run the change itself** when a passing build does not prove it works: start the app or service and inspect the live result (browser, `hyprctl`, `journalctl`, an HTTP call).
    4. **Report evidence.** List each command with its exit status and the decisive output line. Name every step you skipped and why.
    5. **A check that still fails after two fix attempts:** stop and ask the user. Never skip, retry or weaken a check to make it pass.

    NixOS flake repository (flake.nix present): run `nix flake check --no-build`. For system, service, overlay or driver changes also run `nix build --no-link .#nixosConfigurations.<host>.config.system.build.toplevel`. Do not apply the configuration as part of verification; say that the user still has to run `rebuild`.
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
    Save each one as `~/.claude/skills/<pattern-name>/SKILL.md` with `name` and `description` frontmatter.
    Don't extract trivial fixes or one-time issues.
  '';

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
    # Body kept at its original indentation; it only runs when the stamp
    # check at the bottom says the inputs changed.
    _ai_skills_install() {
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
    # caveman is a pinned fetchFromGitHub source; i-have-adhd is vendored (see top of file)
    $DRY_RUN_CMD rm -rf "${cache}/caveman" "${cache}/nulltea"

    # Unmanaged leftovers copied before the managed marker existed, so the
    # prune step cannot see them: the pre-flatten fal-* skills, the fal.ai
    # vertical production skills, and vertex-ai-api-dev (old name of the
    # official gemini-api skill).
    for dest in ${allSkillDirs}; do
      for stale in \
        "$dest"/vertex-ai-api-dev \
        "$dest"/fal-3d "$dest"/fal-audio "$dest"/fal-generate "$dest"/fal-image-edit \
        "$dest"/fal-kling-o3 "$dest"/fal-lip-sync "$dest"/fal-platform "$dest"/fal-realtime \
        "$dest"/fal-restore "$dest"/fal-train "$dest"/fal-tryon "$dest"/fal-upscale \
        "$dest"/fal-video-edit "$dest"/fal-vision \
        "$dest"/character-design "$dest"/cinematography "$dest"/commercial \
        "$dest"/storytelling "$dest"/marketing "$dest"/ugc "$dest"/fan-cam \
        "$dest"/fal-gamedev "$dest"/fal-redesign "$dest"/fal-regenerate-3d; do
        $DRY_RUN_CMD rm -rf "$stale"
      done
    done

    # ── DESIGN.md (official Google Labs source; wrapper copies README/docs/spec) ──
    _git_sync "${cache}/design-md" "https://github.com/google-labs-code/design.md"
    ${copyDesignMdSkill}
    _copy_design_md_skill "${cache}/design-md"

    # ── Modern Web Guidance (Chrome team; guides only, behind a local router
    # SKILL.md. The upstream npx CLI and its telemetry are not used) ──
    _git_sync "${cache}/modern-web-guidance" "https://github.com/GoogleChrome/modern-web-guidance"
    ${copyModernWebGuidanceSkill}
    _copy_modern_web_guidance_skill "${cache}/modern-web-guidance"

    # ── SEO (pinned Illyism/seo-skills references behind a local router
    # SKILL.md, plus the local parasite-seo workflow) ──
    _copy_named_skills "${seoSkills}" seo

    # ── Google Cloud (skills/cloud/ ships 119 skills: GKE, BigQuery, Agent
    # Platform, Airflow, etc. Only gcloud, the IAM/authentication recipe and
    # the Vertex/Agent Platform Gemini skill are kept) ──
    _git_sync "${cache}/google" "https://github.com/google/skills"
    [ -d "${cache}/google/skills/cloud" ] && _copy_named_skills "${cache}/google/skills/cloud" \
      gcloud \
      google-cloud-recipe-auth \
      gemini-api

    # ── Gemini Developer API (official google-gemini repo; omni-flash omitted) ──
    _git_sync "${cache}/gemini" "https://github.com/google-gemini/gemini-skills"
    [ -d "${cache}/gemini/skills" ] && _copy_named_skills "${cache}/gemini/skills" \
      gemini-api-dev \
      gemini-live-api-dev

    # ── Cloudflare (selected skills; web-perf is intentionally omitted;
    # sandbox-sdk was split upstream into sandbox-stable / sandbox-next /
    # sandbox-migrate-to-next, only the stable SDK skill is kept) ──
    _git_sync "${cache}/cloudflare" "https://github.com/cloudflare/skills"
    [ -d "${cache}/cloudflare/skills" ] && _copy_named_skills "${cache}/cloudflare/skills" \
      agents-sdk \
      cloudflare \
      cloudflare-email-service \
      durable-objects \
      sandbox-stable \
      workers-best-practices \
      wrangler

    # ── Cloudflare security-audit (single-skill repo, skill lives in skills/security-audit/) ──
    _git_sync "${cache}/security-audit" "https://github.com/cloudflare/security-audit-skill"
    [ -d "${cache}/security-audit/skills" ] && _copy_named_skills "${cache}/security-audit/skills" security-audit

    # ── Neon (Postgres only; ai-gateway, functions, object-storage, egress-optimizer omitted) ──
    _git_sync "${cache}/neon" "https://github.com/neondatabase/agent-skills"
    [ -d "${cache}/neon/skills" ] && _copy_named_skills "${cache}/neon/skills" \
      neon \
      neon-postgres \
      neon-postgres-branches

    # ── Postgres only from pg-aiguide; Timescale/hypertable skills are omitted ──
    _git_sync "${cache}/pg-aiguide" "https://github.com/timescale/pg-aiguide"
    [ -d "${cache}/pg-aiguide/skills" ] && _copy_named_skills "${cache}/pg-aiguide/skills" postgres

    # ── RunPod (skills in plugins/runpod/skills/*/; flash, mcp, migrate, templates, usage, companion-clis omitted) ──
    _git_sync "${cache}/runpod" "https://github.com/runpod/skills"
    [ -d "${cache}/runpod/plugins/runpod/skills" ] && _copy_named_skills "${cache}/runpod/plugins/runpod/skills" \
      runpod \
      runpodctl

    # ── BytePlus Ark CLI (skills/arkcli-*; 26 skills upstream, only the ModelArk
    # research/generation surface is kept; agent, deploy, train, datasets,
    # iam, billing, plans, helper, onboard, connect omitted). Distributed here,
    # never via `arkcli +connect`, which rewrites every agent skill dir ──
    _git_sync "${cache}/ark-cli" "https://github.com/byteplus-sdk/ark-cli"
    [ -d "${cache}/ark-cli/skills" ] && _copy_named_skills "${cache}/ark-cli/skills" \
      arkcli-shared \
      arkcli-auth \
      arkcli-config \
      arkcli-doctor \
      arkcli-docs \
      arkcli-models \
      arkcli-pricing \
      arkcli-gen \
      arkcli-api-explorer

    # ── Hyprland (purpose-built skill repo) ──
    _git_sync "${cache}/hyprland" "https://github.com/marceloeatworld/hyprland-ai-skill"
    _copy_skill_repo "${cache}/hyprland" "hyprland"

    # ── NixOS (purpose-built skill repo) ──
    _git_sync "${cache}/nixos" "https://github.com/marceloeatworld/nixos-ai-skill"
    _copy_skill_repo "${cache}/nixos" "nixos"

    # ── img2threejs (image to procedural Three.js; scripts in forge/, docs in grimoire/) ──
    _git_sync "${cache}/img2threejs" "https://github.com/hoainho/img2threejs"
    _copy_skill_repo "${cache}/img2threejs" "img2threejs"

    # ── Caveman (pinned; only the terse mode, loaded every session by the global
    # CLAUDE.md import in claude-code.nix; the repo also ships Caveman Cloud
    # skills, generic work patterns, and commit/review skills that auto-trigger
    # and overlap with commit-commands, code-review, and CLAUDE.md rules) ──
    _copy_named_skills "${cavemanSrc}/skills" caveman

    # ── i-have-adhd (vendored copy of nulltea/skills@c982286, 2026-08-05;
    # loaded every session by the global CLAUDE.md import in claude-code.nix) ──
    _copy_named_skills "${localSkills}" i-have-adhd security-godmode

    # ── Marketing (pinned; product-marketing is the shared context every other
    # skill reads first. seo-audit is a technical audit, distinct from the seo
    # router above. ads, sms, events, influencer, PR and the rest are omitted) ──
    _copy_named_skills "${marketingSrc}/skills" \
      product-marketing copywriting cro pricing launch seo-audit

    # Pinned prompt pack, modding toolkit and REA.
    _copy_named_skills "${bugBountySkills}" bug-bounty-hunting
    # ── Mantis (pinned; mantis-advise needs reference/scripts/advise.py from
    # the uninstalled harness, mantis-pipeline-adapter only builds custom
    # harnesses, both omitted). Only run it against throwaway clones:
    # mantis-reproduce executes generated reproducer code ──
    _copy_named_skills "${mantisSrc}/skills" \
      mantis-meta-agent mantis-history mantis-structural-index \
      mantis-architecture mantis-threat-model mantis-plan mantis-researcher \
      mantis-summarize mantis-dedupe mantis-review mantis-critic \
      mantis-calibrate mantis-reflect mantis-chain mantis-reproduce \
      mantis-patch mantis-report
    # ── Lint rule packs that steer coding agents (pinned). The Cloudflare
    # Oxlint preset ships its own migration skill; the Factory ESLint plugin is
    # wrapped as a reference pack by factoryEslintSkills above ──
    _copy_named_skills "${oxlintConfigSrc}/skills" migrate-oxlint-config
    _copy_named_skills "${factoryEslintSkills}" factory-eslint-rules
    _copy_named_skills "${universalModderSkills}" \
      mod-any-game game-recon reverse-engineering fal-assets asset-pipeline \
      game-automation showcase-video mashup-mods publish-mod share-field-notes \
      game-research-websearch port-a-mod
    _copy_named_skills "${reaSkills}" reverse-engineer-anything

    # ── SkillSpector and Strix skills, taken from the same pinned source the
    # CLIs are built from (overlays/skillspector.nix, overlays/strix.nix).
    # Strix: managed-pentesting (uploads code to app.strix.ai) and
    # ci-security-scanning (curl | bash installer in CI) are omitted;
    # web-app-penetration-testing and application-security-testing duplicate
    # penetration-testing-with-strix. The rest are patched local-only by
    # strixSkills above ──
    _copy_named_skills "${pkgs.skillspector.src}/skills" skill-inspector
    _copy_named_skills "${strixSkills}" \
      penetration-testing-with-strix \
      find-security-vulnerabilities-in-code \
      fix-security-vulnerabilities-with-strix \
      owasp-top-10-testing \
      api-security-testing

    # ── fal.ai (skills in skills/*/; genmedia core + umbrellas only, the vertical
    # production skills such as commercial, marketing, ugc, fan-cam are omitted) ──
    _git_sync "${cache}/fal-ai" "https://github.com/fal-ai-community/skills"
    [ -d "${cache}/fal-ai/skills" ] && _copy_named_skills "${cache}/fal-ai/skills" \
      genmedia \
      genmedia-workflow \
      model-routing \
      fal-models-catalog \
      fal-prompting \
      fal-recipes \
      fal-workflow

    # ── Medusa (skills in plugins/<plugin>/skills/*/; medusa-dev and
    # ecommerce-storefront only. learn-medusa is a tutorial and medusa-cloud
    # needs the mcloud CLI, which is not installed. The MedusaDocs MCP server
    # the skills mention is declared in claude-code.nix) ──
    _git_sync "${cache}/medusa" "https://github.com/medusajs/medusa-agent-skills"
    [ -d "${cache}/medusa/plugins/medusa-dev/skills" ] && _copy_named_skills "${cache}/medusa/plugins/medusa-dev/skills" \
      building-with-medusa \
      building-admin-dashboard-customizations \
      building-storefronts \
      creating-internal-agents \
      db-generate \
      db-migrate \
      new-user
    [ -d "${cache}/medusa/plugins/ecommerce-storefront/skills" ] && _copy_named_skills "${cache}/medusa/plugins/ecommerce-storefront/skills" \
      storefront-best-practices

    # ── Vercel/React (selected skills; deploy-to-vercel/web-design omitted) ──
    _git_sync "${cache}/vercel" "https://github.com/vercel-labs/agent-skills"
    [ -d "${cache}/vercel/skills" ] && _copy_named_skills "${cache}/vercel/skills" \
      composition-patterns \
      react-best-practices \
      react-native-skills \
      react-view-transitions \
      vercel-cli-with-tokens

    _ai_skills_prune_stale
    }

    if _ai_skills_up_to_date; then
      verboseEcho "AI skills unchanged, skipping redistribution"
    else
      _ai_skills_install
      _ai_skills_write_stamp
    fi
  '';
}
