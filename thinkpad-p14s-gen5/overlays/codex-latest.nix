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
  version = "0.144.3";
  sha256 = "sha256-ubSujptWHGTfvF71LGMZy6dQrIfePH9ViFAmIx466ok=";
  # Separate release asset since 0.143.0; codex spawns this helper at runtime
  codeModeHostSha256 = "sha256-NnURRlACC9c5RoTgXWYNYEPucZkI+DnooLv2sTu/ZP4=";
in
stdenv.mkDerivation {
  pname = "codex";
  inherit version;

  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
    inherit sha256;
  };

  codeModeHostSrc = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz";
    sha256 = codeModeHostSha256;
  };

  sourceRoot = ".";

  dontStrip = true;

  installPhase = ''
    install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
    tar -xzf $codeModeHostSrc
    install -Dm755 codex-code-mode-host-x86_64-unknown-linux-musl $out/bin/codex-code-mode-host
  '';

  meta = {
    description = "Codex - OpenAI's lightweight coding agent (${version})";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "codex";
  };
}
