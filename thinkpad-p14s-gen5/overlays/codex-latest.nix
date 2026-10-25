# Codex Latest - Override nixpkgs version with latest prebuilt package
# Source: https://github.com/openai/codex/releases
# Asset: codex-package-*.tar.gz (musl static binaries, no patchelf needed)
#
# Since 0.157.0 codex runs a background app-server daemon that requires the
# full package layout (bin/, codex-package.json, codex-resources/, codex-path/)
# next to the executable. A bare binary fails with "this CLI has no complete
# local package". The package tarball bundles codex, codex-code-mode-host,
# bwrap, rg, zsh and the voice host.
#
# To update:
#   1. Run: update-codex (shell alias)
#   2. Or manually:
#      a. Check latest: curl -sL https://api.github.com/repos/openai/codex/releases/latest | jq -r .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/openai/codex/releases/download/rust-vVERSION/codex-package-x86_64-unknown-linux-musl.tar.gz"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, ... }:

let
  version = "0.164.0";
  sha256 = "sha256-PsVQUxCWCNUDj35QdQ99Jfdo39dA/vBxqnEOJVm2Oqw=";
in
stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
    inherit sha256;
  };

  sourceRoot = ".";

  dontStrip = true;
  dontPatchELF = true;

  # Keep the whole layout: codex resolves codex-package.json relative to bin/codex
  installPhase = ''
    mkdir -p $out
    cp -r bin codex-package.json codex-path codex-resources $out/
  '';

  meta = {
    description = "Codex - OpenAI's lightweight coding agent (${version})";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
