{ lib, buildNpmPackage, fetchFromGitHub, nodejs_22, autoPatchelfHook, stdenv }:

buildNpmPackage {
  pname = "rea";
  version = "4.0.1";
  src = fetchFromGitHub {
    owner = "morluto";
    repo = "rea";
    rev = "9b392bb2f83decda39b4f871a079b411082bcd2f";
    hash = "sha256-1PWwXdtzz9U/Ppzfbvk8AGK7TdSuJ9Hgt49pLwa06VE=";
  };
  nodejs = nodejs_22;
  npmDepsHash = "sha256-BgbazDPseg7XqljNAV0YYaLCmOLyF777DqxWibGr3pY=";
  # Build the CLI without running setup, Husky or the upstream prepack build.
  npmFlags = [ "--ignore-scripts" ];
  npmBuildScript = "build:unlocked";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];
  doInstallCheck = true;
  installCheckPhase = ''
    "$out/bin/rea" --version
    "$out/bin/rea" --help > /dev/null
  '';
  meta = {
    description = "Reverse engineering CLI and MCP server for apps and native binaries";
    homepage = "https://github.com/morluto/rea";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "rea";
  };
}
