# ForgeCode - AI coding harness for terminal
# Installed via overlay (prebuilt musl binary from GitHub releases)
# Config: ~/.forge/.forge.toml (seeded once by Nix, then owned by forge)
# Auth: forge provider login → select provider and enter API key
# ZSH: `: <prompt>` sends to active agent from native shell
{ config, pkgs, ... }:

let
  # Minimal seed: only values that differ from forge's built-in defaults.
  # Forge rewrites .forge.toml at runtime (model switches, `forge config set`),
  # so this is seeded once and never overwritten. Delete the live file and
  # rebuild to re-seed.
  forgeConfigSeed = pkgs.writeText "forge-config-seed.toml" ''
    # ForgeCode configuration — seeded by Nix, owned by forge at runtime

    # Permission layer (policies in permissions.yaml)
    restricted = true

    # Disable auto-update (managed by Nix overlay)
    [updates]
    auto_update = false

    # Default model (Z.AI GLM 5.2)
    [session]
    provider_id = "zai"
    model_id = "glm-5.2"

    # Reasoning effort (upstream default is medium)
    [reasoning]
    enabled = true
    effort = "high"

    # Commit-message generation model
    [commit]
    provider_id = "zai"
    model_id = "glm-5.2"
  '';

  # Docs: https://forgecode.dev/docs/permissions/
  forgePermissionsSeed = pkgs.writeText "forge-permissions-seed.yaml" ''
    # ForgeCode tool permissions (enabled via restricted = true)
    policies:
      - permission: allow
        rule:
          read: "**/*"
      - permission: confirm
        rule:
          write: "**/*"
      - permission: deny
        rule:
          command: "rm -rf *"
  '';

  # Docs: https://forgecode.dev/docs/mcp-integration/
  forgeMcpSeed = pkgs.writeText "forge-mcp-seed.json" ''
    {
      "mcpServers": {
        "chrome-devtools": {
          "command": "pnpm",
          "args": ["dlx", "chrome-devtools-mcp@0.23.0"]
        },
        "playwright": {
          "command": "pnpm",
          "args": ["dlx", "@playwright/mcp@0.0.70"]
        }
      }
    }
  '';
in
{
  home.packages = [ pkgs.forgecode ];

  # Forge resolves its base path as $FORGE_CONFIG > legacy ~/forge (if it
  # exists) > ~/.forge. Pin it so a legacy dir can never shadow ~/.forge.
  home.sessionVariables.FORGE_CONFIG = "${config.home.homeDirectory}/.forge";

  home.activation.forgeConfig = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    FORGE_BASE="$HOME/.forge"
    LEGACY="$HOME/forge"

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$FORGE_BASE"

    # One-time migration: before FORGE_CONFIG was pinned, forge used the
    # legacy ~/forge base path and all runtime state (credentials, session db,
    # history) lived there. Move it over; keep the rest of the dir as backup.
    if [ -d "$LEGACY" ] && [ ! -e "$FORGE_BASE/.legacy-migration-done" ]; then
      for item in .credentials.json .forge.db .forge.db-shm .forge.db-wal .forge_history cache snapshots; do
        if [ -e "$LEGACY/$item" ]; then
          if [ -e "$FORGE_BASE/$item" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$FORGE_BASE/$item" "$FORGE_BASE/$item.pre-migration"
          fi
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$LEGACY/$item" "$FORGE_BASE/$item"
        fi
      done
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mv "$LEGACY" "$LEGACY.migrated-backup"
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/touch "$FORGE_BASE/.legacy-migration-done"
    fi

    # Seed config files only when absent (or still the old read-only store
    # symlink): forge writes these at runtime, EROFS would break it.
    for seed in "${forgeConfigSeed}:.forge.toml" "${forgePermissionsSeed}:permissions.yaml" "${forgeMcpSeed}:.mcp.json"; do
      src="''${seed%%:*}"
      dest="$FORGE_BASE/''${seed##*:}"
      if [ -L "$dest" ] || [ ! -e "$dest" ]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/rm -f "$dest"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 0644 "$src" "$dest"
      fi
    done
  '';

  # Skills are now centralized in ai-skills.nix

  # ── ZSH integration ──
  # ForgeCode uses `: <prompt>` from native ZSH
  # `forge zsh setup` can't write to ~/.zshrc on NixOS (read-only)
  # so we source the plugin and theme via initContent instead
  programs.zsh.initContent = ''
    # ForgeCode ZSH plugin + theme (`: <prompt>` integration)
    eval "$(forge zsh plugin 2>/dev/null)"
    eval "$(forge zsh theme 2>/dev/null)"
  '';
}
