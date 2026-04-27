# Claude Code Latest - Override nixpkgs version with latest prebuilt binary
# Source: https://www.npmjs.com/package/@anthropic-ai/claude-code-linux-x64
# Note: Claude Code is a Bun SEA (single-executable application). autoPatchelfHook
# corrupts the embedded Bun runtime, so we only patch the ELF interpreter manually.
#
# Since 2.1.x, the main @anthropic-ai/claude-code npm package is just a tiny
# wrapper whose postinstall copies the native binary from a platform-specific
# optionalDependency. We skip the wrapper entirely and fetch the native binary
# directly from @anthropic-ai/claude-code-linux-x64.
#
# To update:
#   1. Run: update-claude-code (shell alias)
#   2. Or manually:
#      a. Check latest: npm view @anthropic-ai/claude-code version
#      b. Get hash: nix-prefetch-url "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-VERSION.tgz"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, claude-code, patchelf, glibc, stdenv, ... }:

let
  version = "2.1.119";
  sha256 = "sha256-KpeVSoYvwdwJZgHwEetGre6g2V0IrJj80nLKFoGunKg=";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${version}.tgz";
    inherit sha256;
  };

  sourceRoot = "package";

  nativeBuildInputs = [ patchelf ];

  dontAutoPatchelf = true;
  dontStrip = true;

  installPhase = ''
    install -Dm755 claude $out/bin/claude
    patchelf --set-interpreter "${glibc}/lib/ld-linux-x86-64.so.2" $out/bin/claude
  '';

  meta = claude-code.meta // {
    description = "Claude Code - Anthropic's AI coding assistant (${version})";
    platforms = [ "x86_64-linux" ];
  };
}
