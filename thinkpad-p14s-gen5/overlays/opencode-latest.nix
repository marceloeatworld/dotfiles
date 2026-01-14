# OpenCode Latest - Override nixpkgs version with latest from GitHub releases
# This overlay fetches the latest pre-built binary from GitHub (official source)
# Source: https://github.com/anomalyco/opencode
#
# To update:
#   1. Check latest: curl -s https://api.github.com/repos/anomalyco/opencode/releases/latest | jq -r '.tag_name'
#   2. Get hash: nix-prefetch-url --unpack "https://github.com/anomalyco/opencode/releases/download/vVERSION/opencode-linux-x64.tar.gz"
#   3. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#   4. Update version and hash below
{ lib, stdenv, fetchurl, autoPatchelfHook, ... }:

let
  version = "1.1.20";
  hash = "sha256-b8n5yxAr8iUi2cAE3PXZ5n/N8+FSK7wYf8w3dNjlii4=";
in
stdenv.mkDerivation {
  pname = "opencode";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  # The tarball extracts directly to files, not a subdirectory
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp opencode $out/bin/
    chmod +x $out/bin/opencode
    runHook postInstall
  '';

  meta = with lib; {
    description = "AI coding agent built for the terminal";
    homepage = "https://github.com/anomalyco/opencode";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opencode";
  };
}
