# AGENTS.md

Instructions for AI coding agents working in `thinkpad-p14s-gen5/`.

Also follow the repository-level `../AGENTS.md`. Claude Code users should also read `CLAUDE.md`, which contains Claude-specific context.

## Scope

This directory contains the live NixOS/Home Manager configuration for:

- Hostname: `pop`
- Hardware: ThinkPad P14s Gen 5 AMD
- Desktop: Hyprland on Wayland
- State versions: `25.05`

Do not treat this as a generic starter flake. The current structure, overlays, wrappers, and runtime scripts are intentional.

## Common Commands

Run from this directory unless noted otherwise:

```bash
nix flake check --no-build
nix build --no-link --impure .#nixosConfigurations.pop.config.system.build.toplevel
nh os test .
nh os switch .
```

Use the smallest command that proves the change:

- Docs or comments: inspect the diff and run `git diff --check` from the repo root.
- Home Manager text/config changes: `nix flake check --no-build` is usually enough.
- System modules, services, overlays, drivers, Hyprland packages, kernel, boot, or security changes: prefer a full `nix build --no-link --impure .#nixosConfigurations.pop.config.system.build.toplevel`.
- Applying the system with `nh os switch .` should be explicit. If you do not apply it, tell the user to run `rebuild`.

## Architecture Boundaries

- `flake.nix`: central flake wiring, host assembly, patched package sets, and overlays.
- `overlays/`: latest or pinned packages that intentionally diverge from nixpkgs.
- `hosts/thinkpad/`: hardware, boot, disko, and host-specific system entry points.
- `modules/system/`: NixOS-level modules.
- `modules/home/home.nix`: Home Manager import root.
- `modules/home/programs/`: user applications and CLI tooling.
- `modules/home/programs/hyprland/`: split Hyprland Lua config modules.
- `modules/home/services/`: user services such as Waybar, Mako, Hyprlock, and SwayOSD.
- `modules/home/config/`: theme, GTK/QT, secrets, MIME, wallpaper, runtime theme, and shared config.

Keep edits inside the correct boundary. If a package, plugin, portal, or Hyprland component must share the same patched package set, wire it centrally instead of patching each consumer independently.

## Nix Patterns

- Use `pkgs.writeShellScriptBin` for generated executables and `pkgs.writeShellScript` for generated helper scripts.
- Use `$HOME` in generated shell scripts, not `/home/marcelo`.
- Prefer `${pkgs.package}/bin/tool` in generated scripts when reproducibility matters.
- Keep source scripts under `modules/home/services/waybar-scripts/` when they are maintained as files, and deploy them declaratively.
- When adding a new Nix file that is imported by the flake, stage it with `git add` before validating.
- Do not change `system.stateVersion` or `home.stateVersion` unless the user explicitly asks and the migration is understood.

## Hyprland Notes

- Hyprland config uses Lua (`configType = "lua"`).
- Generated Lua files live under `~/.config/hypr/` and are assembled from the split modules in `modules/home/programs/hyprland/`.
- For plugin/package-set issues, verify both build-time wiring and the live compositor. A successful build does not prove the current Hyprland session has restarted.
- Useful runtime checks include `hyprctl plugin list`, `hyprctl version`, `/run/current-system/sw/bin/Hyprland --version`, and the active log under `/run/user/1000/hypr/`.

## Secrets

- Secrets are managed by sops-nix.
- Encrypted file: `sops/api-keys.yaml`.
- Secret wiring: `modules/home/config/secrets.nix`.
- Age private key is outside the repo and must never be committed.
- Empty or missing secret files are intentionally tolerated by shell export guards.

## Local LLM Notes

- The llama.cpp service is managed by `modules/system/llama-cpp.nix`.
- Do not claim a model change is live until the service and `/v1/models` output confirm it.
- The active symlink alone is not enough evidence because systemd staging can still serve an older model.

## Review Standard

Before saying a change is safe:

- Check the current diff.
- Confirm the touched module boundary is correct.
- Run the appropriate validation command, or state why it was skipped.
- Report whether the user still needs to run `rebuild`.
