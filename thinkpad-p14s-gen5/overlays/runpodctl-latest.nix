# RunPod CLI - Prebuilt release binary (Go, statically linked, no patchelf)
# Source: https://github.com/runpod/runpodctl/releases
#
# To update:
#   1. Run: update-runpodctl (shell alias)
#   2. Or manually:
#      a. Check latest: gh api repos/runpod/runpodctl/releases/latest --jq .tag_name
#      b. Get hash: nix-prefetch-url "https://github.com/runpod/runpodctl/releases/download/vVERSION/runpodctl-linux-amd64"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{ lib, fetchurl, stdenv, installShellFiles, ... }:

let
  version = "2.6.1";
  sha256 = "sha256-6uzY1xEAIrCo2HC3RiYo6rS7R8Z5RxIb5+8gHOkUrk8=";
in
stdenv.mkDerivation {
  pname = "runpodctl";
  inherit version;

  src = fetchurl {
    url = "https://github.com/runpod/runpodctl/releases/download/v${version}/runpodctl-linux-amd64";
    inherit sha256;
  };

  dontUnpack = true;
  dontStrip = true;

  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    install -Dm755 $src $out/bin/runpodctl

    installShellCompletion --cmd runpodctl \
      --bash <($out/bin/runpodctl completion bash) \
      --zsh <($out/bin/runpodctl completion zsh) \
      --fish <($out/bin/runpodctl completion fish) 2>/dev/null || true
  '';

  meta = {
    description = "RunPod CLI to manage GPU workloads (${version})";
    homepage = "https://github.com/runpod/runpodctl";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "runpodctl";
  };
}
