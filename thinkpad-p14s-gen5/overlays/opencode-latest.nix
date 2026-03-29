# OpenCode Latest - Override nixpkgs version with latest prebuilt binary
# Source: https://github.com/anomalyco/opencode/releases
# Note: OpenCode is a Bun SEA (single-executable application). autoPatchelfHook
# corrupts the embedded Bun runtime, so we only patch the ELF interpreter manually.
#
# To update:
#   1. Run: update-opencode (shell alias)
#   2. Or manually:
#      a. Check latest: curl -s https://api.github.com/repos/anomalyco/opencode/releases/latest | jq -r .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/anomalyco/opencode/releases/download/vVERSION/opencode-linux-x64.tar.gz"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, opencode, patchelf, glibc, stdenv, ... }:

let
  version = "1.3.5";
  sha256 = "sha256-xrSa4VrgZSwzmCFFAx1VhryOTTZrBgH+ZPr7Ytf9mII=";
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    inherit sha256;
  };

  sourceRoot = ".";

  nativeBuildInputs = [ patchelf ];

  dontAutoPatchelf = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 opencode $out/bin/opencode
    patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $out/bin/opencode
  '';

  meta = opencode.meta // {
    description = "OpenCode - AI coding agent (${version})";
  };
}
