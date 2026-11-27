# Sandboxed AI coding agents via ~alexdavid/jail.nix (bubblewrap).
# Vendored replacement for andersonjoseph/jailed-agents: same commands, same
# jail shape (network + tz, cwd mounted read-write, per-agent config paths),
# without the numtide dependency stack.
#   jailed-claude-code, jailed-opencode, jailed-codex, jailed-forgecode
#   claude-gpt-tor (no network except Tor, see below)
{ config, inputs, pkgs, ... }:

let
  jail = inputs.jail-nix.lib.init pkgs;

  # Baseline tools inside every jail (same set jailed-agents shipped).
  basePackages = with pkgs; [
    bashInteractive
    curl
    wget
    jq
    git
    which
    ripgrep
    gnugrep
    gawkInteractive
    ps
    findutils
    gzip
    unzip
    gnutar
    diffutils
    gnused
  ];

  # gcc16 lib: newest GLIBCXX symbols (backward compatible), so the leaked
  # LD_LIBRARY_PATH doesn't break newer C++ binaries in the jail.
  bunCompat = pkgs.writeShellScriptBin "bun" ''
    export LD_LIBRARY_PATH="${pkgs.gcc16.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    exec ${pkgs.bun}/bin/bun "$@"
  '';

  # Tools agents commonly need once inside the jail. Secrets stay limited to
  # each agent's explicit config path plus the current working directory.
  agentExtraPkgs = with pkgs; [
    nodejs-slim_22
    pnpm
    bunCompat
    uv
    python313
    nix
    nil
    nixd
    gnumake
    cmake
    gcc
    pkg-config
  ];

  # secretPaths: sops secret files the agent config reads at load time.
  # Bound read-only; bwrap follows the per-activation symlink at exec time.
  makeJailedAgent = { name, pkg, configPaths, secretPaths ? [ ] }:
    jail name pkg (
      with jail.combinators;
      [
        network
        time-zone
        no-new-session
        mount-cwd
      ]
      ++ map (p: readwrite (noescape p)) configPaths
      ++ map try-readonly secretPaths
      ++ [
        (add-pkg-deps basePackages)
        (add-pkg-deps agentExtraPkgs)
      ]
    );

  # claude-gpt-tor: claude-gpt (Claude + GPT second opinion) whose only way
  # out is Tor. The jail has no network namespace share, so it owns a loopback
  # device and nothing else; a program that ignores the proxy variables gets
  # no route at all instead of the real IP. The host Tor (user service below)
  # is reached through unix sockets bound into the jail.
  # Limits: Anthropic and OpenAI still identify the account, Tor only hides
  # the IP; MCP servers are off (most hold account tokens or skip the proxy);
  # no D-Bus, no nix-daemon, no secrets from the shell environment.
  torHttpPort = "18118";
  torHostDir = jail.combinators.noescape ''"$XDG_RUNTIME_DIR/claude-gpt-tor"'';

  # Tor's HTTPTunnelPort (the HTTP CONNECT proxy Claude Code and Codex need)
  # cannot listen on a unix socket, so socat republishes it as one.
  torService = pkgs.writeShellScript "claude-gpt-tor-service" ''
    ${pkgs.socat}/bin/socat UNIX-LISTEN:"$RUNTIME_DIRECTORY/http",fork,unlink-early TCP4:127.0.0.1:${torHttpPort} &
    exec ${pkgs.tor}/bin/tor \
      --DataDirectory "$STATE_DIRECTORY" \
      --SocksPort "unix:$RUNTIME_DIRECTORY/socks" \
      --HTTPTunnelPort 127.0.0.1:${torHttpPort}
  '';

  # Runs inside the jail: loopback listeners that forward to the Tor sockets.
  claudeGptTorEntry = pkgs.writeShellScriptBin "claude-gpt-tor-entry" ''
    ${pkgs.socat}/bin/socat TCP4-LISTEN:8118,bind=127.0.0.1,fork,reuseaddr UNIX-CONNECT:/run/tor/http &
    ${pkgs.socat}/bin/socat TCP4-LISTEN:9050,bind=127.0.0.1,fork,reuseaddr UNIX-CONNECT:/run/tor/socks &
    exec ${pkgs.claude-code}/bin/claude --strict-mcp-config "$@"
  '';

  jailedClaudeGptTor = jail "jailed-claude-gpt-tor" claudeGptTorEntry (
    with jail.combinators;
    [
      time-zone
      no-new-session
      mount-cwd
      # TLS roots and localhost resolution, without the `network` combinator
      # (it would share the host network namespace).
      (runtime-deep-ro-bind "/etc/hosts")
      (runtime-deep-ro-bind "/etc/nsswitch.conf")
      (runtime-deep-ro-bind "/etc/ssl")
      # Hooks and settings are Home Manager symlinks into the store, with
      # `#!/usr/bin/env` shebangs and tools (ask-gpt, codex, python3) from
      # the user profile.
      (readonly "/nix/store")
      (readonly "/usr/bin/env")
      (readonly config.home.profileDirectory)
      (add-path "${config.home.profileDirectory}/bin")
      (ro-bind torHostDir "/run/tor")
      (add-runtime ''
        mkdir -p ~/.cache/ask-gpt
        echo "claude-gpt-tor: waiting for Tor" >&2
        TOR_READY=
        for _ in $(seq 30); do
          if ${pkgs.curl}/bin/curl -s -o /dev/null -m 10 --proxy http://127.0.0.1:${torHttpPort} https://api.anthropic.com; then
            TOR_READY=1
            break
          fi
          sleep 2
        done
        if [ -z "$TOR_READY" ]; then
          echo "claude-gpt-tor: Tor is not reachable, not starting" >&2
          exit 1
        fi
      '')
      (set-env "CLAUDE_GPT" "1")
      (set-env "HTTPS_PROXY" "http://127.0.0.1:8118")
      (set-env "https_proxy" "http://127.0.0.1:8118")
      (set-env "ALL_PROXY" "socks5h://127.0.0.1:9050")
      (set-env "all_proxy" "socks5h://127.0.0.1:9050")
      (set-env "NO_PROXY" "localhost,127.0.0.1")
      (set-env "no_proxy" "localhost,127.0.0.1")
    ]
    ++ map (p: readwrite (noescape p)) [
      "~/.claude"
      "~/.claude.json"
      "~/.codex"
      "~/.cache/ask-gpt"
    ]
    ++ [
      (add-pkg-deps basePackages)
      (add-pkg-deps agentExtraPkgs)
    ]
  );

  # The scope pulls the Tor service in and, through StopWhenUnneeded, lets it
  # stop when the last claude-gpt-tor session exits.
  claudeGptTor = pkgs.writeShellScriptBin "claude-gpt-tor" ''
    exec ${pkgs.systemd}/bin/systemd-run --user --scope --quiet \
      -p Wants=claude-gpt-tor.service -p After=claude-gpt-tor.service \
      -- ${jailedClaudeGptTor}/bin/jailed-claude-gpt-tor "$@"
  '';
in
{
  systemd.user.services.claude-gpt-tor = {
    Unit = {
      Description = "Tor client for claude-gpt-tor sessions";
      StopWhenUnneeded = true;
    };
    Service = {
      ExecStart = "${torService}";
      RuntimeDirectory = "claude-gpt-tor";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "claude-gpt-tor";
      StateDirectoryMode = "0700";
    };
  };

  home.packages = [
    claudeGptTor

    (makeJailedAgent {
      name = "jailed-claude-code";
      pkg = pkgs.claude-code;
      configPaths = [ "~/.claude" "~/.claude.json" ];
    })

    (makeJailedAgent {
      name = "jailed-opencode";
      pkg = pkgs.opencode;
      configPaths = [
        "~/.config/opencode"
        "~/.local/share/opencode"
        "~/.local/state/opencode"
      ];
      # opencode.json resolves provider.google apiKey via {file:...} (opencode.nix)
      secretPaths = [ config.sops.secrets.gemini_api_key.path ];
    })

    (makeJailedAgent {
      name = "jailed-codex";
      pkg = pkgs.codex;
      configPaths = [ "~/.codex" ];
    })

    (makeJailedAgent {
      name = "jailed-forgecode";
      pkg = pkgs.forgecode;
      configPaths = [ "~/.forge" ];
    })
  ];
}
