# llama.cpp Latest - Override nixpkgs version with latest from GitHub
# This overlay fetches the latest release with ROCm support and native CPU optimizations
# Source: https://github.com/ggml-org/llama.cpp
#
# To update:
#   1. Check latest: curl -s https://api.github.com/repos/ggml-org/llama.cpp/releases/latest | jq -r .tag_name
#   2. Get hash: nix-prefetch-url --unpack "https://github.com/ggml-org/llama.cpp/archive/refs/tags/VERSION.tar.gz"
#   3. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#   4. Update version and hash below
#
# Or simply run: update-llama-cpp
{ lib, llama-cpp, fetchFromGitHub, ... }:

let
  # AUTO-UPDATED BY update-llama-cpp SCRIPT
  version = "7955";
  hash = "sha256-EqB9auXdlHA5MQbFiekrtNbAgYzp7+OdBkK01Df4ypQ=";
in
(llama-cpp.override {
  rocmSupport = true;   # AMD GPU acceleration via ROCm
}).overrideAttrs (old: {
  inherit version;
  pname = "llama-cpp";

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    inherit hash;
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
