# AGENTS.md

Instructions for AI coding agents working in this repository.

## First Principles

- Read the relevant code, docs, and current diff before proposing or making changes.
- Keep changes narrow. Do not refactor, reformat, or "clean up" adjacent code unless it is required for the task.
- Preserve user work. Check `git status --short` before editing, and never revert unrelated changes.
- Do not commit, push, reset, remove files, or run destructive commands unless the user explicitly asks.
- Prefer the repository's existing Nix, Home Manager, shell, Lua, and documentation patterns over new abstractions.
- When the user asks for analysis, verification, or "read only", do not edit files until they explicitly approve changes.

## User Workflow

- Treat prompts such as `analyse`, `verifie`, `lecture seul`, `sans modifier`, `ne change rien`, or `li mon plan` as read-only audit requests.
- When the user switches to `corrige`, `ok va y`, `fait`, or another clear implementation request, make the focused change and verify it.
- Always answer in English, even when the user writes in French. All file content (code comments, user-facing strings, docs, commit messages) must be in English. Never use French anywhere.
- The user values source-of-truth answers: cite actual files, commands, logs, and runtime state instead of guessing.
- If the visible UI, logs, or runtime output contradict a written assumption, trust the observed evidence first.

## Repository Shape

This is a NixOS dotfiles repository. The primary machine configuration is:

- Machine: ThinkPad P14s Gen 5 AMD
- Hostname: `pop`
- Main flake directory: `thinkpad-p14s-gen5/`
- NixOS and Home Manager state version: `25.05`
- Desktop: Hyprland on Wayland

Most implementation work belongs under `thinkpad-p14s-gen5/`. Read `thinkpad-p14s-gen5/AGENTS.md` when working there.

## NixOS Rules

- Do not suggest `apt`, `brew`, curl-pipe installers, or manual binary downloads for system tools. Add packages through Nix modules, overlays, or the flake.
- Before adding a package another way, check whether it exists in nixpkgs or already has a local overlay.
- New files imported by a flake must be staged with `git add` before Nix evaluation can see them.
- Never change NixOS or Home Manager `stateVersion` casually.
- In Nix-generated shell scripts, use `$HOME` instead of hardcoded `/home/marcelo` paths.
- In Nix-generated scripts, prefer explicit store paths such as `${pkgs.curl}/bin/curl` when the script should be reproducible.

## Validation

Choose validation based on risk:

- Documentation-only changes: inspect the diff and run `git diff --check`.
- Shell scripts: run `bash -n` when practical.
- Python scripts: run `python3 -m py_compile` when practical.
- Nix syntax or module changes: run `nix flake check --no-build` from `thinkpad-p14s-gen5/` when practical.
- System, boot, driver, Hyprland package, service, or overlay changes may need a real build such as `nix build --no-link --impure .#nixosConfigurations.pop.config.system.build.toplevel`.
- Only run `nh os switch .` when applying the configuration is requested or clearly necessary. Otherwise tell the user to run `rebuild`.

If validation cannot be run, say exactly why and report the remaining risk.

## Runtime Truth

For runtime questions, verify the live system instead of relying only on the repo:

- Hyprland: check `hyprctl`, the running Hyprland version, and the current Hyprland log.
- Waybar or user services: check `journalctl --user`.
- System services: check `systemctl`, `journalctl -u`, and the generated unit when relevant.
- Local LLM service: verify the running `llama-cpp` service and `/v1/models`; a model symlink alone does not prove what is live.

## Communication

- Start with the direct verdict when reviewing or answering a safety question.
- Keep explanations concrete and repo-specific.
- Mention unrelated issues only as notes; do not fix them without scope.
- End with what changed, what was validated, and any command the user needs to run.
