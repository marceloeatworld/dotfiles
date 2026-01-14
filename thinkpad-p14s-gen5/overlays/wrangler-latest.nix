# Wrangler Latest - Override nixpkgs version with latest from npm
# This overlay fetches the latest version from npm registry (official Cloudflare source)
# Source: https://www.npmjs.com/package/wrangler
#
# To update:
#   1. Check latest: npm view wrangler version
#   2. Get hash: nix-prefetch-url --unpack "https://registry.npmjs.org/wrangler/-/wrangler-VERSION.tgz"
#   3. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#   4. Update version and hash below
{ lib, wrangler, fetchurl, ... }:

let
  version = "4.59.1";
  hash = "sha256-gAiELlyZSEK+FL5V7QA+3ogXhxBdTx9BY3m02ZW0yFg=";
in
wrangler.overrideAttrs (oldAttrs: {
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/wrangler/-/wrangler-${version}.tgz";
    inherit hash;
  };
})
