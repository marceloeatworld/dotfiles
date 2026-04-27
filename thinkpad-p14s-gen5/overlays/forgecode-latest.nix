# ForgeCode Latest - Prebuilt static binary from GitHub releases
# Source: https://github.com/tailcallhq/forgecode/releases
# Binary: musl-linked static executable (no patchelf needed)
#
# NOTE: Repo was renamed from antinomyhq/forgecode → tailcallhq/forgecode
#
# To update:
#   1. Run: update-forgecode (shell alias)
#   2. Or manually:
#      a. Check latest: curl -sL https://api.github.com/repos/tailcallhq/forgecode/releases/latest | jq -r .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/tailcallhq/forgecode/releases/download/vVERSION/forge-x86_64-unknown-linux-musl"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, ... }:

let
  version = "2.12.9";
  sha256 = "sha256-aNeqogoZS5+pAFCZ0oyv6nahGX2UdH6subSXOXWMTTM=";
in
stdenv.mkDerivation {
  pname = "forgecode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/tailcallhq/forgecode/releases/download/v${version}/forge-x86_64-unknown-linux-musl";
    inherit sha256;
  };

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 $src $out/bin/forge
  '';

  meta = {
    description = "ForgeCode - AI coding harness (${version})";
    homepage = "https://forgecode.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "forge";
  };
}
