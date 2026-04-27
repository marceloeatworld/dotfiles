# pnpm Latest - Override nixpkgs version with latest prebuilt static binary
# Source: https://github.com/pnpm/pnpm/releases
# Binary: musl-linked static executable (no patchelf needed)
#
# To update:
#   1. Run: update-pnpm (shell function)
#   2. Or manually:
#      a. Check latest: curl -sL https://api.github.com/repos/pnpm/pnpm/releases/latest | jq -r .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/pnpm/pnpm/releases/download/vVERSION/pnpm-linuxstatic-x64"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, ... }:

let
  version = "10.33.2";
  sha256 = "sha256-pHvnFZObr6Qg+9xeNPf52CksAyQCFiyJzLYR6UTlJtY=";
in
stdenv.mkDerivation {
  pname = "pnpm";
  inherit version;

  src = fetchurl {
    url = "https://github.com/pnpm/pnpm/releases/download/v${version}/pnpm-linuxstatic-x64";
    inherit sha256;
  };

  dontUnpack = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 $src $out/bin/pnpm
    ln -s pnpm $out/bin/pnpx
  '';

  meta = {
    description = "Fast, disk space efficient package manager (${version})";
    homepage = "https://pnpm.io";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "pnpm";
  };
}
