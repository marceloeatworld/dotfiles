# OpenCode - AI coding agent for terminal
# Installed via overlay (prebuilt Bun SEA binary from GitHub releases)
# Config: ~/.config/opencode/opencode.json (global) + opencode.json (per-project)
# Auth: opencode auth login → select provider and enter API key
{ config, pkgs, ... }:

{
  # ── OpenCode global configuration ──
  # Docs: https://opencode.ai/docs/config
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";

    # Disable auto-update (managed by Nix overlay)
    autoupdate = false;

    # Plugins
    plugin = [
      "@opencode-ai/plugin"
    ];

    # Context compaction
    compaction = {
      auto = true;
      prune = true;
      reserved = 10000;
    };

    # File watcher exclusions
    watcher = {
      ignore = [
        "node_modules/**"
        "dist/**"
        ".git/**"
        ".direnv/**"
        "result"
        "result-*"
      ];
    };

    # LSP servers (nixd for Nix, others auto-detect)
    lsp = {
      nixd = {
        command = [ "nixd" ];
        extensions = [ ".nix" ];
      };
    };
  };

  # ── TUI configuration ──
  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    scroll_speed = 3;
    scroll_acceleration = { enabled = true; };
    diff_style = "auto";
  };

  # ── Official Cloudflare skills (github.com/cloudflare/skills) ──
  home.activation.opencode-cloudflare-skills = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    OC_CACHE="$HOME/.cache/opencode/cloudflare-skills"
    OC_SKILLS="$HOME/.config/opencode/skill"
    OC_COMMANDS="$HOME/.config/opencode/command"

    # Clone or update official repo
    if [ -d "$OC_CACHE/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$OC_CACHE" pull --quiet 2>/dev/null || true
    else
      $DRY_RUN_CMD rm -rf "$OC_CACHE"
      $DRY_RUN_CMD mkdir -p "$(dirname "$OC_CACHE")"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --quiet https://github.com/cloudflare/skills "$OC_CACHE"
    fi

    # Copy all skills
    if [ -d "$OC_CACHE/skills" ]; then
      $DRY_RUN_CMD mkdir -p "$OC_SKILLS"
      for skill_dir in "$OC_CACHE/skills/"*/; do
        [ -d "''${skill_dir}" ] || continue
        skill_name=$(${pkgs.coreutils}/bin/basename "''${skill_dir}")
        $DRY_RUN_CMD rm -rf "$OC_SKILLS/''${skill_name}"
        $DRY_RUN_CMD cp -r "''${skill_dir}" "$OC_SKILLS/''${skill_name}"
      done
    fi

    # Copy commands
    if [ -d "$OC_CACHE/commands" ]; then
      $DRY_RUN_CMD mkdir -p "$OC_COMMANDS"
      $DRY_RUN_CMD cp -r "$OC_CACHE/commands/"* "$OC_COMMANDS/" 2>/dev/null || true
    fi
  '';

  # ── Official Supabase skills (github.com/supabase/agent-skills) ──
  home.activation.opencode-supabase-skills = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    OC_CACHE="$HOME/.cache/opencode/supabase-skills"
    OC_SKILLS="$HOME/.config/opencode/skill"

    if [ -d "$OC_CACHE/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$OC_CACHE" pull --quiet 2>/dev/null || true
    else
      $DRY_RUN_CMD rm -rf "$OC_CACHE"
      $DRY_RUN_CMD mkdir -p "$(dirname "$OC_CACHE")"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --quiet https://github.com/supabase/agent-skills "$OC_CACHE"
    fi

    if [ -d "$OC_CACHE/skills" ]; then
      $DRY_RUN_CMD mkdir -p "$OC_SKILLS"
      for skill_dir in "$OC_CACHE/skills/"*/; do
        [ -d "''${skill_dir}" ] || continue
        skill_name=$(${pkgs.coreutils}/bin/basename "''${skill_dir}")
        $DRY_RUN_CMD rm -rf "$OC_SKILLS/''${skill_name}"
        $DRY_RUN_CMD cp -r "''${skill_dir}" "$OC_SKILLS/''${skill_name}"
      done
    fi
  '';
}
