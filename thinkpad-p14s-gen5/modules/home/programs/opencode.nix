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

    # Default model (Z.AI GLM 5.2 via models.dev provider id `zai`)
    model = "zai/glm-5.2";
    small_model = "zai/glm-5.2";

    # Never upload sessions to opencode.ai
    share = "disabled";

    # Enable built-in formatters (omitted = all disabled)
    formatter = true;

    # Reuse existing rules files (AGENTS.md is auto-loaded already)
    instructions = [ "CLAUDE.md" ];

    # Permission layer (defaults are allow-everything)
    permission = {
      edit = "ask";
      bash = {
        "*" = "allow";
        "git push *" = "ask";
        "rm -rf *" = "deny";
      };
    };

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
    # Current schema shape; the old type/api_url/api_key keys were legacy
    # pre-1.0 syntax silently stripped at load (provider was dead).
    provider = {
      local-llm = {
        npm = "@ai-sdk/openai-compatible";
        name = "local-llm";
        options = {
          baseURL = "http://127.0.0.1:8080/v1";
          apiKey = "not-needed";
        };
        models = {
          "local-model" = {
            name = "local-model";
            attachment = false;
            reasoning = false;
            tool_call = true;
            limit = {
              context = 8192;
              output = 4096;
            };
          };
        };
      };
    };

    # Agent preset for the local model (numeric temperature lives on agents,
    # not on model definitions, in the current schema)
    agent = {
      local = {
        mode = "primary";
        description = "Offline agent on local llama.cpp";
        model = "local-llm/local-model";
        temperature = 0.7;
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
        command = [ "pnpm" "dlx" "chrome-devtools-mcp@0.23.0" ];
        enabled = true;
      };
      playwright = {
        type = "local";
        command = [ "pnpm" "dlx" "@playwright/mcp@0.0.70" ];
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
    # Desktop notifications on done/permission/error
    attention = { enabled = true; };
  };

  # Skills are now centralized in ai-skills.nix
}
