# ForgeCode - AI coding harness for terminal
# Installed via overlay (prebuilt musl binary from GitHub releases)
# Config: ~/.forge/.forge.toml (global) + .forge.toml (per-project)
# Auth: forge provider login → select provider and enter API key
# ZSH: `: <prompt>` sends to active agent from native shell
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.forgecode ];

  # ── ForgeCode global configuration ──
  # Docs: https://forgecode.dev/docs/forgecode-config/
  home.file.".forge/.forge.toml".text = ''
    # ForgeCode configuration — managed by Nix
    # Edit via :config-edit or directly; changes apply on next startup

    # Output tokens
    max_tokens = 20480

    # Tool execution
    max_requests_per_turn = 100
    tool_timeout_secs = 300
    max_tool_failure_per_turn = 3

    # File handling
    max_file_size_bytes = 104857600
    max_read_lines = 2000
    max_line_chars = 2000

    # Shell output
    max_stdout_prefix_lines = 100
    max_stdout_suffix_lines = 100

    # Disable auto-update (managed by Nix flake)
    [updates]
    auto_update = false
    frequency = "daily"

    # Compaction (context management)
    [compact]
    token_threshold = 100000
    message_threshold = 200
    eviction_window = 0.2
    retention_window = 6
    max_tokens = 2000

    # HTTP settings
    [http]
    connect_timeout_secs = 30
    read_timeout_secs = 900

    # Retry settings
    [retry]
    max_attempts = 8
    initial_backoff_ms = 200
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
