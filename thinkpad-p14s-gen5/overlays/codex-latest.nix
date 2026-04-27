# Codex Latest - Override nixpkgs version with latest prebuilt binary
# Source: https://github.com/openai/codex/releases
# Binary: musl-linked static executable (no patchelf needed)
#
# To update:
#   1. Run: update-codex (shell alias)
#   2. Or manually:
#      a. Check latest: curl -sL https://api.github.com/repos/openai/codex/releases/latest | jq -r .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/openai/codex/releases/download/rust-vVERSION/codex-x86_64-unknown-linux-musl.tar.gz"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, ... }:

let
  version = "0.125.0";
  sha256 = "sha256-SiClOUOn5qDF+kRj1OR8WN2OVT7OveRVpBB+mQa/sAE=";
in
stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
    inherit sha256;
  };

  sourceRoot = ".";

  dontStrip = true;

  installPhase = ''
    install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
  '';

  meta = {
    description = "Codex - OpenAI's lightweight coding agent (${version})";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
