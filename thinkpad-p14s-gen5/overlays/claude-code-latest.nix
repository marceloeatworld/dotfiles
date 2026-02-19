# Claude Code Latest - Override nixpkgs version with latest from npm
# This overlay fetches the latest version from npm registry (official Anthropic source)
# Source: https://www.npmjs.com/package/@anthropic-ai/claude-code
#
# To update:
#   1. Run: update-claude-code (shell alias)
#   2. Or manually:
#      a. Check latest: npm view @anthropic-ai/claude-code version
#      b. Get src hash: nix-prefetch-url --unpack "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-VERSION.tgz"
#      c. Convert: nix hash convert --hash-algo sha256 HASH
#      d. Generate package-lock.json: cd /tmp && tar xzf <src> && cd package && npm install --package-lock-only --ignore-scripts
#      e. Copy lock file to overlays/claude-code-package-lock.json
#      f. Get npmDepsHash: use lib.fakeHash and read error output
#      g. Update version, hash, and npmDepsHash below
{ lib, claude-code, fetchurl, fetchNpmDeps, ... }:

let
  version = "2.1.47";
  hash = "sha256-4CpoDVQK81QA8in60EgnlDwF01Sru8JApAA2Y6UKOGI=";
  npmDepsHash = "sha256-1wvl0vwl9CMntNDuh7sTWqNTnAg1AYgnuUukZOXU+PU=";
in
claude-code.overrideAttrs (oldAttrs: {
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    inherit hash;
  };

  postPatch = ''
    cp ${./claude-code-package-lock.json} package-lock.json
  '';

  npmDeps = fetchNpmDeps {
    name = "claude-code-${version}-npm-deps";
    src = fetchurl {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      inherit hash;
    };
    postPatch = ''
      cp ${./claude-code-package-lock.json} package-lock.json
    '';
    hash = npmDepsHash;
  };
})
