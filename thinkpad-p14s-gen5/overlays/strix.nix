{ lib, fetchFromGitHub, fetchPypi, python3Packages, buildGoModule, writeShellScriptBin }:

let
  version = "1.7.0";
  src = fetchFromGitHub {
    owner = "usestrix";
    repo = "strix";
    rev = "v${version}";
    hash = "sha256-D8kol+k7ZK1bu6LnQO01CwbfhOIp4cMP78kyN7Ex/Lc=";
  };

  # Bubble Tea terminal UI, shipped inside the wheel by scripts/tui_sidecar_hook.py.
  # Built here with vendored modules so the wheel build stays offline.
  strix-tui = buildGoModule {
    pname = "strix-tui";
    inherit version src;
    modRoot = "strix/interface/tui";
    subPackages = [ "cmd/strix-tui" ];
    vendorHash = "sha256-MeLL85C4OSdGwVkJrW4QEiZSZx9nXrmI1TJMAyak2A0=";
    env.CGO_ENABLED = 0;
    ldflags = [ "-s" "-w" ];
  };
  # The hatch hook shells out to `go build ... -o <output> ./cmd/strix-tui`;
  # this stand-in copies the prebuilt sidecar to that output path instead.
  goShim = writeShellScriptBin "go" ''
    while [ $# -gt 0 ]; do
      [ "$1" = "-o" ] && { cp ${strix-tui}/bin/strix-tui "$2"; exit 0; }
      shift
    done
    echo "go shim: no -o argument" >&2; exit 1
  '';

  # nixpkgs ships openai-agents 0.22.0, which needs openai >=3 (nixpkgs has
  # 2.x) and fails its runtime deps check; Strix pins 0.19.x anyway.
  openai-agents = python3Packages.openai-agents.overridePythonAttrs (old: rec {
    version = "0.19.4";
    src = fetchPypi {
      inherit version;
      pname = "openai_agents";
      hash = "sha256-/iF3juHoIWyc23dfqG0RsIvmjAGE4UAjmTCI0/gSwL4=";
    };
    dependencies = old.dependencies ++ [ python3Packages.websockets ];
    # websockets <17 is a version cap; the realtime module only uses the stable API.
    pythonRelaxDeps = [ "websockets" ];
  });
in
python3Packages.buildPythonApplication {
  pname = "strix";
  inherit version src;
  pyproject = true;
  build-system = [ python3Packages.hatchling ];
  nativeBuildInputs = [ goShim ];
  # cryptography <49 is an upstream macOS release-build cap, not an API limit.
  pythonRelaxDeps = [ "cryptography" ];
  dependencies = [ openai-agents ] ++ (with python3Packages; [
    litellm openai google-auth boto3 pydantic pydantic-settings
    rich docker requests cvss caido-sdk-client markdown-it-py reportlab pypdf
    cryptography pyyaml
  ]);
  # Opt out of PostHog/Scarf usage reporting; the sandbox image is pulled from
  # upstream on first run through the rootless Podman socket (DOCKER_HOST).
  # Default to the same Gemini model the other agents use (gemini-cli.nix,
  # opencode.nix). Strix reads only LLM_API_KEY/OPENAI_API_KEY, so the sops
  # GEMINI_API_KEY is mapped across, but only for a gemini model and only when
  # LLM_API_KEY is unset: exporting it unconditionally would shadow
  # OPENAI_API_KEY and break every non-Gemini model.
  makeWrapperArgs = [
    "--set-default" "STRIX_TELEMETRY" "false"
    "--set-default" "STRIX_LLM" "gemini/gemini-4-argon"
    "--run" ''
      case "$STRIX_LLM" in
        gemini/*)
          if [ -z "''${LLM_API_KEY:-}" ] && [ -n "''${GEMINI_API_KEY:-}" ]; then
            export LLM_API_KEY="$GEMINI_API_KEY"
          fi
          ;;
      esac
    ''
  ];
  doCheck = false;
  pythonImportsCheck = [ "strix.interface.main" ];
  doInstallCheck = true;
  postInstallCheck = ''
    "$out/bin/strix" --help > /dev/null
  '';
  meta = {
    description = "AI penetration testing agent that validates findings with proof-of-concept exploits";
    homepage = "https://github.com/usestrix/strix";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "strix";
  };
}
