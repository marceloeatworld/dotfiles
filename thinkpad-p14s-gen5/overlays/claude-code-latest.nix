# Claude Code Latest - Override nixpkgs version with latest from npm
# This overlay fetches the latest version from npm registry (official Anthropic source)
# Source: https://www.npmjs.com/package/@anthropic-ai/claude-code
#
# To update:
#   1. Check latest: npm view @anthropic-ai/claude-code version
#   2. Get hash: nix-prefetch-url --unpack "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-VERSION.tgz"
#   3. Convert: nix hash convert --hash-algo sha256 HASH
#   4. Update version and hash below
{ lib, claude-code, fetchurl, ... }:

let
  version = "2.1.38";
  hash = "sha256-+o8u2I7EKv10+SUaaf9HdRLl1CxOHuKVm4KzilJHmkk=";
in
claude-code.overrideAttrs (oldAttrs: {
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    inherit hash;
  };
})
