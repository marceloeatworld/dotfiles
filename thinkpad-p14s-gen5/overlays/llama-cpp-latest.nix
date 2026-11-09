# llama.cpp Latest - Override nixpkgs version with latest from GitHub
# This overlay fetches the latest release with ROCm support and native CPU optimizations
# Source: https://github.com/ggml-org/llama.cpp
#
# To update:
#   1. Check latest bNNNN build (releases/latest now returns the stable vX.Y.Z line):
#      curl -s "https://api.github.com/repos/ggml-org/llama.cpp/releases?per_page=30" | jq -r '[.[] | select(.tag_name | test("^b[0-9]+$"))][0].tag_name'
#   2. Get hash: nix-prefetch-url --unpack "https://github.com/ggml-org/llama.cpp/archive/refs/tags/VERSION.tar.gz"
#   3. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#   4. Update version and hash below
#
# Or simply run: update-llama-cpp
{ llama-cpp, fetchFromGitHub, fetchNpmDeps, ... }:

let
  # AUTO-UPDATED BY update-llama-cpp SCRIPT
  version = "12212";
  hash = "sha256-GLrXWMJXWGzDaI7m3G+DoYN5DGehx29EVUTlb01lfBo=";
  # webui npm deps hash for this pinned version (decouples from nixpkgs)
  npmDepsHash = "sha256-XLtEZsSFdk+2SyfXzBp8HQ2e27PQPpDCn1YjePU1/9w=";
in
(llama-cpp.override {
  rocmSupport = true;   # AMD GPU acceleration via ROCm
  # Only the kernels this machine runs. The 780M (gfx1103) loads gfx1100
  # code objects through HSA_OVERRIDE_GFX_VERSION=11.0.0; the nixpkgs
  # default compiles 14 targets and turns every update into an hour-long
  # build.
  rocmGpuTargets = [ "gfx1100" ];
}).overrideAttrs (old: rec {
  inherit version;
  pname = "llama-cpp";

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    inherit hash;
  };

  # The webui moved from tools/server/webui to tools/ui in newer llama.cpp.
  # npmRoot drives the base derivation's `pushd ${npmRoot}; npm run build`
  # step in preConfigure; keep npmDeps sourceRoot pointed at the same dir.
  npmRoot = "tools/ui";

  npmDeps = fetchNpmDeps {
    name = "${pname}-${version}-npm-deps";
    inherit src;
    sourceRoot = "${src.name or "source"}/tools/ui";
    hash = npmDepsHash;
  };

  cmakeFlags = (old.cmakeFlags or []) ++ [
    "-DGGML_NATIVE=ON"  # Native CPU optimizations (critical for performance)
  ];

  # Allow native CPU optimizations (Nix normally disables them)
  preConfigure = ''
    export NIX_ENFORCE_NO_NATIVE=0
    ${old.preConfigure or ""}
  '';

  meta = old.meta // {
    description = "LLaMA inference in C/C++ - Latest (b${version}) with ROCm";
  };
})
