# RunPod CLI - Built from source (Go)
# Source: https://github.com/runpod/runpodctl
#
# To update:
#   1. Check latest: gh api repos/runpod/runpodctl/releases/latest --jq .tag_name
#   2. Get hash: nix-prefetch-url --unpack "https://github.com/runpod/runpodctl/archive/refs/tags/vVERSION.tar.gz"
#   3. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#   4. Update version and hash below
#   5. Set vendorHash = lib.fakeHash, rebuild to get real vendorHash, then update
{ lib, buildGoModule, fetchFromGitHub, installShellFiles, ... }:

let
  version = "2.1.9";
in
buildGoModule {
  pname = "runpodctl";
  inherit version;

  src = fetchFromGitHub {
    owner = "runpod";
    repo = "runpodctl";
    tag = "v${version}";
    hash = "sha256-cZ8B3o0oX69qrsQpUI9qwDnRFA90cmWHpSZsvElbkMU=";
  };

  vendorHash = "sha256-8Cdj5ZXmfooEh+MlaROjxVsAW6rZfPW7HNy86qnvAJA=";

  ldflags = [
    "-s" "-w"
    "-X" "main.Version=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --cmd runpodctl \
      --bash <($out/bin/runpodctl completion bash) \
      --zsh <($out/bin/runpodctl completion zsh) \
      --fish <($out/bin/runpodctl completion fish) 2>/dev/null || true
  '';

  meta = {
    description = "RunPod CLI to manage GPU workloads (${version})";
    homepage = "https://github.com/runpod/runpodctl";
    license = lib.licenses.mit;
    mainProgram = "runpodctl";
  };
}
