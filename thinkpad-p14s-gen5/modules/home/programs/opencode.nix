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

    # Local LLM provider (llama-cpp on port 8080)
    provider = {
      local-llm = {
        name = "local-llm";
        type = "openai";
        api_url = "http://127.0.0.1:8080/v1";
        api_key = "not-needed";
        models = {
          "local-model" = {
            name = "local-model";
            attachment = false;
            can_reason = false;
            context_length = 8192;
            default_temperature = 0.7;
            max_tokens = 4096;
          };
        };
      };
    };

    # LSP servers (nixd for Nix, others auto-detect)
    lsp = {
      nixd = {
        command = [ "nixd" ];
        extensions = [ ".nix" ];
      };
    };

    # MCP servers (browser automation + debugging)
    # Docs: https://opencode.ai/docs/mcp-servers/
    mcp = {
      chrome-devtools = {
        type = "local";
        command = [ "npx" "-y" "chrome-devtools-mcp@0.23.0" ];
        enabled = true;
      };
      playwright = {
        type = "local";
        command = [ "npx" "-y" "@playwright/mcp@0.0.70" ];
        enabled = true;
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

  # Skills are now centralized in ai-skills.nix
}
