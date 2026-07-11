# Codex - OpenAI's lightweight coding agent for terminal
# Installed via overlay (prebuilt musl binary from GitHub releases)
# Config: ~/.codex/config.toml (not managed by Nix; codex creates it as needed)
# Auth: codex login (oauth tokens stored in ~/.codex/auth.json)
# Sandbox: codex uses bubblewrap (bwrap) to sandbox shell/tool calls
{ pkgs, ... }:

{
  home.packages = [
    pkgs.codex
    pkgs.bubblewrap  # Required by codex for tool sandboxing
  ];
}
