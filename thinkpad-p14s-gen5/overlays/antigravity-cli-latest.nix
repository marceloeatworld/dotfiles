# Antigravity CLI Latest - Google's terminal agent (agy), successor of Gemini CLI
# Source: https://storage.googleapis.com/antigravity-public/antigravity-cli
# Asset: linux-x64-musl tarball (one static Go binary, no patchelf needed)
#
# nixpkgs ships the glibc build and lags behind upstream. Download URLs carry a
# build id next to the version, and the release manifest publishes a sha512
# for every asset, so the hash below is upstream's own (no prefetch needed).
#
# To update:
#   1. Run: update-antigravity-cli (shell alias)
#   2. Or manually:
#      a. Check latest: curl -sL https://storage.googleapis.com/antigravity-public/antigravity-cli/latest
#      b. Read the asset: curl -sL https://storage.googleapis.com/antigravity-public/antigravity-cli/VERSION/manifest.json | jq '.platforms."linux-x64-musl"'
#         (the build id is the number after "VERSION-" in the url)
#      c. Convert: nix hash convert --hash-algo sha512 --to sri SHA512
#      d. Update version, buildId and hash below
{ lib, fetchurl, stdenv, ... }:

let
  version = "1.5.19";
  buildId = "4881646848180224";
  hash = "sha512-RK6Buk3EG4+QF+1/oKBmV/NLSomGcRC9YYctWPw3SysK/BTYM88YWrtlEjls+O8yuHbqr/CoA0/Q1rpPVLl14Q==";
in
stdenv.mkDerivation {
  pname = "antigravity-cli";
  inherit version;

  src = fetchurl {
    url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/${version}-${buildId}/linux-x64-musl/cli_linux_x64_musl.tar.gz";
    inherit hash;
  };

  sourceRoot = ".";

  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    install -Dm755 antigravity $out/bin/agy
  '';

  meta = {
    description = "Antigravity CLI - Google's terminal AI agent (${version})";
    homepage = "https://antigravity.google";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agy";
  };
}
