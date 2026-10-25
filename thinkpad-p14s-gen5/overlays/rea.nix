{ lib, buildNpmPackage, fetchFromGitHub, nodejs_22, autoPatchelfHook, stdenv }:

buildNpmPackage {
  pname = "rea";
  version = "6.8.0";
  src = fetchFromGitHub {
    owner = "morluto";
    repo = "rea";
    rev = "160d821ac9a0310afcb8d1fc427862dd6508add5";
    hash = "sha256-2ADn3U3lvUoB4tCEpzO0rMfYE4sis+5uBiEazcp0gpI=";
  };
  nodejs = nodejs_22;
  npmDepsHash = "sha256-3WPXD+qm5WVfrTEvepKwX5RZBfbLBcPB0uDmKIx4MR8=";
  # Build the CLI without running setup, Husky or the upstream prepack build.
  # `npm pack` runs `prepare` even with --ignore-scripts, and upstream's
  # prepare.mjs patches release-please with git.
  npmFlags = [ "--ignore-scripts" ];
  postPatch = ''
    npm pkg delete scripts.prepare scripts.prepack
  '';
  npmBuildScript = "build";
  # Native compiler/bundler binaries from npm (tsrs, rolldown, oxc) need the
  # Nix dynamic loader before the build runs; autoPatchelfHook only fixes $out.
  preBuild = ''
    for dir in node_modules/@*/linux-x64-gnu node_modules/@*/linux-x64 node_modules/*-linux-x64-gnu node_modules/*-linux-x64; do
      [ -d "$dir" ] && autoPatchelf "$dir"
    done
  '';
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
