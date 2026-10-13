# Gemini CLI Latest - Google's terminal agent from the upstream npm bundle
# Source: https://www.npmjs.com/package/@google/gemini-cli
#
# nixpkgs lags (0.47.0) and flags the package as replaced by Antigravity CLI.
# That cutoff only concerns Google AI Pro/Ultra and free-tier accounts; a paid
# GEMINI_API_KEY keeps working, which is how ask-gemini authenticates.
# The npm tarball is a self-contained esbuild bundle (bundle/gemini.js, no
# dependencies, no native modules), so it only needs a Node runtime.
#
# To update:
#   1. Run: update-gemini-cli (shell alias)
#   2. Or manually:
#      a. Check latest: pnpm view @google/gemini-cli version
#      b. Get hash: nix-prefetch-url "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-VERSION.tgz"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, nodejs-slim_22, ripgrep, makeWrapper, ... }:

let
  version = "0.64.0";
  sha256 = "sha256-iRp5TlXIMZtrePb48T1riyeCpHCd/S/KvzofY66DZeY=";
in
stdenv.mkDerivation {
  pname = "gemini-cli";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
    inherit sha256;
  };

  nativeBuildInputs = [ makeWrapper ];

  # Keep the whole bundle/ tree: gemini.js loads its chunks relative to itself.
  # grep_search looks for rg-<platform>-<arch> next to the bundle (never PATH),
  # so link nixpkgs ripgrep there instead of the "GrepTool fallback" warning.
  installPhase = ''
    mkdir -p $out/lib/gemini-cli $out/bin
    cp -r bundle package.json $out/lib/gemini-cli/
    ln -s ${ripgrep}/bin/rg $out/lib/gemini-cli/bundle/rg-linux-x64
    makeWrapper ${nodejs-slim_22}/bin/node $out/bin/gemini \
      --add-flags "$out/lib/gemini-cli/bundle/gemini.js"
  '';

  meta = {
    description = "Gemini CLI - Google's terminal AI agent (${version})";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "gemini";
  };
}
