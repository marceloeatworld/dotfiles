# pnpm Latest - Override nixpkgs version with latest npm tarball, wrapped to run
# on the system Node.js (nodejs-slim_22).
# Source: https://registry.npmjs.org/pnpm
#
# Why the npm tarball instead of pnpm-linuxstatic-x64?
# The official `pnpm-linuxstatic-x64` release asset is a Node SEA bundle that
# embeds Node 20.11.1. That embedded version is what `process.version` returns
# when pnpm itself runs, so every project with `engines.node: ">=22"` shows a
# spurious "Unsupported engine" warning even when the actual scripts execute
# on the system Node 22 via `pnpm exec`. Using the npm tarball + a wrapper
# around system Node makes `process.version` match the system Node.
#
# NOTE: still pinned to pnpm v10.x. pnpm v11 (released 2026-04-28) removed
# support for `pnpm config set manage-package-manager-versions` in the global
# config, and nixpkgs's pnpmConfigHook still issues that command, so v11
# breaks every package that uses it (e.g. yt-dlp-ejs). Re-enable v11 once
# nixpkgs ships an updated pnpmConfigHook.
#
# To update:
#   1. Run: update-pnpm (shell function — restricted to v10.x)
#   2. Or manually:
#      a. Check latest v10: curl -sL "https://api.github.com/repos/pnpm/pnpm/releases?per_page=50" | jq -r '[.[] | select(.tag_name | startswith("v10."))][0].tag_name'
#      b. Get hash: nix-prefetch-url "https://registry.npmjs.org/pnpm/-/pnpm-VERSION.tgz"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, nodejs-slim_22, makeWrapper, ... }:

let
  version = "10.34.5";
  sha256 = "sha256-zLXEecqxsAYhMlv+fUyaioAx56Ul1ySeJ17L7IGwjbI=";
in
stdenv.mkDerivation {
  pname = "pnpm";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/pnpm/-/pnpm-${version}.tgz";
    inherit sha256;
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules/pnpm
    cp -r . $out/lib/node_modules/pnpm/

    makeWrapper ${nodejs-slim_22}/bin/node $out/bin/pnpm \
      --add-flags $out/lib/node_modules/pnpm/bin/pnpm.cjs
    makeWrapper ${nodejs-slim_22}/bin/node $out/bin/pnpx \
      --add-flags $out/lib/node_modules/pnpm/bin/pnpx.cjs

    runHook postInstall
  '';

  meta = {
    description = "Fast, disk space efficient package manager (${version})";
    homepage = "https://pnpm.io";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "pnpm";
  };

  passthru = {
    nodejs-slim = nodejs-slim_22;
  };
}
