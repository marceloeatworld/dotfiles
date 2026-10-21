# BytePlus Ark CLI - Prebuilt release binary (Go, statically linked, no patchelf)
# Source: https://github.com/byteplus-sdk/ark-cli/releases
# BytePlus edition of volcengine/ark-cli: ModelArk (Seedance, Seedream, Seed
# LLMs) from the terminal and the arkcli-* agent skills (see ai-skills.nix).
# Skills are distributed by ai-skills.nix; never run `arkcli +connect`, it
# rewrites every agent skill dir and deletes third-party Seedance skills.
#
# To update:
#   1. Run: update-arkcli (shell alias)
#   2. Or manually:
#      a. Check latest: gh api repos/byteplus-sdk/ark-cli/releases/latest --jq .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/byteplus-sdk/ark-cli/releases/download/vVERSION/arkcli-VERSION-linux-amd64"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, installShellFiles, ... }:

let
  version = "1.0.41";
  sha256 = "sha256-LuZTst+jCXiZUrbba7Fl7+JV96EitDDFOChSmZnkjrI=";
in
stdenv.mkDerivation {
  pname = "arkcli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/byteplus-sdk/ark-cli/releases/download/v${version}/arkcli-${version}-linux-amd64";
    inherit sha256;
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    install -Dm755 $src $out/bin/arkcli

    installShellCompletion --cmd arkcli \
      --bash <($out/bin/arkcli completion bash) \
      --zsh <($out/bin/arkcli completion zsh) \
      --fish <($out/bin/arkcli completion fish) 2>/dev/null || true
  '';

  meta = {
    description = "BytePlus Ark CLI for ModelArk models, generation and endpoints (${version})";
    homepage = "https://github.com/byteplus-sdk/ark-cli";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "arkcli";
  };
}
