{ lib, fetchFromGitHub, fetchPypi, python3Packages, git }:

let
  # Not in nixpkgs: WHATWG URL parser used by the exfiltration rules.
  pywhatwgurl = python3Packages.buildPythonPackage rec {
    pname = "pywhatwgurl";
    version = "0.1.1";
    pyproject = true;
    src = fetchPypi {
      inherit pname version;
      hash = "sha256-Zchdo1NnURwSpN2H/srwiqOuVkJZBVs3tK5TQpKJ/PY=";
    };
    build-system = with python3Packages; [ hatchling hatch-vcs ];
    dependencies = with python3Packages; [ idna ];
    pythonImportsCheck = [ "pywhatwgurl" ];
    meta.license = lib.licenses.mit;
  };
in
python3Packages.buildPythonApplication rec {
  pname = "skillspector";
  version = "2.13.1";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "NVIDIA";
    repo = "SkillSpector";
    rev = "v${version}";
    hash = "sha256-6cgi0+uk4cCoS2AAp4aUUQm4ZF9KfGdLjqC1wVOoHa0=";
  };
  build-system = [ python3Packages.hatchling ];
  # typer <0.24 is pinned upstream only to coexist with semgrep's click; the
  # exact regex pin is a lockstep pin, not an API requirement.
  pythonRelaxDeps = [ "typer" "regex" ];
  dependencies = with python3Packages; [
    typer rich httpx pywhatwgurl regex packaging pyyaml pydantic openai
    langgraph langchain-anthropic langchain-aws langchain-core langchain-openai
    boto3 langsmith yara-python google-auth
    mcp # [mcp] extra: `skillspector mcp` stdio server for Claude Code
  ] ++ google-auth.optional-dependencies.requests;
  # Git and URL targets are cloned with the git binary.
  makeWrapperArgs = [ "--prefix" "PATH" ":" (lib.makeBinPath [ git ]) ];
  doCheck = false; # Suite needs the LLM provider stubs; `--no-llm` scan is checked below.
  pythonImportsCheck = [ "skillspector.cli" ];
  doInstallCheck = true;
  postInstallCheck = ''
    "$out/bin/skillspector" --help > /dev/null
    HOME=$(mktemp -d) "$out/bin/skillspector" scan "$src/skills/skill-inspector" --no-llm --format json > /dev/null
  '';
  meta = {
    description = "Security scanner for AI agent skills (prompt injection, exfiltration, malicious code)";
    homepage = "https://github.com/NVIDIA/SkillSpector";
    license = lib.licenses.asl20;
    mainProgram = "skillspector";
  };
}
