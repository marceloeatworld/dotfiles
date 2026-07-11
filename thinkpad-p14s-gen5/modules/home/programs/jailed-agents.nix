# Sandboxed AI coding agents via ~alexdavid/jail.nix (bubblewrap).
# Vendored replacement for andersonjoseph/jailed-agents: same commands, same
# jail shape (network + tz, cwd mounted read-write, per-agent config paths),
# without the numtide dependency stack.
#   jailed-claude-code, jailed-opencode, jailed-codex, jailed-forgecode
{ inputs, pkgs, ... }:

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

  makeJailedAgent = { name, pkg, configPaths }:
    jail name pkg (
      with jail.combinators;
      [
        network
        time-zone
        no-new-session
        mount-cwd
      ]
      ++ map (p: readwrite (noescape p)) configPaths
      ++ [
        (add-pkg-deps basePackages)
        (add-pkg-deps agentExtraPkgs)
      ]
    );
in
{
  home.packages = [
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
