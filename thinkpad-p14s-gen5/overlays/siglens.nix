{ lib, stdenvNoCC, fetchFromGitHub, python313, makeWrapper }:

let
  dependencies = ps: with ps; [ typer rich pefile yara-python capstone jinja2 ];
  python = python313.withPackages dependencies;
  testPython = python313.withPackages (ps: dependencies ps ++ [ ps.pytest ]);
in
stdenvNoCC.mkDerivation {
  pname = "siglens";
  version = "0-unstable-2026-10-01";
  src = fetchFromGitHub {
    owner = "St0rn";
    repo = "SigLens";
    rev = "a39ec1b5fd605819b8527bdd3629075255f3e2b4";
    hash = "sha256-FC41ahJMcmOJiDoZmINT4v2ZtmFUXPnQNYYqUYaxmBk=";
  };
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    # Upstream's unused fixed_windows compatibility helper now takes bytes;
    # this one stale test still expects KiB. Keep the other helper/CLI tests.
    PYTHONPATH=src ${testPython}/bin/python -m pytest -q tests \
      --deselect tests/test_window_scan.py::test_default_minimum_windows
    runHook postCheck
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/siglens" "$out/bin"
    cp -r src rules siglens_launcher.py engines*.json README.md LICENSE "$out/share/siglens/"
    makeWrapper ${python}/bin/python "$out/bin/siglens" \
      --add-flags "$out/share/siglens/siglens_launcher.py"
    runHook postInstall
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/siglens" --help > /dev/null
    "$out/bin/siglens" about
  '';
  meta = {
    description = "Artifact analysis and YARA correlation (AMSI, Defender and DbgHelp require Windows)";
    homepage = "https://github.com/St0rn/SigLens";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "siglens";
  };
}
