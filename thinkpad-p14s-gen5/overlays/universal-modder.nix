{ lib, fetchFromGitHub, python313Packages, ffmpeg }:

python313Packages.buildPythonApplication {
  pname = "universal-modder";
  version = "0.2.0-unstable-2026-10-21";
  pyproject = true;
  src = fetchFromGitHub {
    owner = "rehan-remade";
    repo = "universal-modder";
    rev = "c1dff21663665dd17af289744a301b66e369605e";
    hash = "sha256-/hMtVomQl8TZ038Hddt2GQUGI3xZgRlU4wMu+G1mliQ=";
  };
  build-system = [ python313Packages.hatchling ];
  dependencies = with python313Packages; [ pillow numpy pyyaml ];
  makeWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ ffmpeg ])
    "--set-default" "UM_KB" "${placeholder "out"}/share/universal-modder/knowledge"
  ];
  nativeCheckInputs = [ python313Packages.pytestCheckHook ];
  pytestFlags = [ "tests" ]; # Offline suite; examples include live-game scripts.
  pythonImportsCheck = [ "um.cli" "um.sprite" "um.kb" ];
  postInstall = ''
    mkdir -p "$out/share/universal-modder"
    cp -r skills examples knowledge README.md LICENSE "$out/share/universal-modder/"
  '';
  doInstallCheck = true;
  postInstallCheck = ''
    "$out/bin/um" --help > /dev/null
    "$out/bin/um" --version
    "$out/bin/um" sprite --help > /dev/null
  '';
  meta = {
    description = "Game modding CLI and skills; window automation requires Windows or WSL";
    homepage = "https://github.com/rehan-remade/universal-modder";
    license = lib.licenses.mit;
    mainProgram = "um";
  };
}
