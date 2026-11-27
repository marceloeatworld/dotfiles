# ROCm (TheRock) - AMD's prebuilt ROCm Core SDK for the gfx110X family
# Source: https://stable.repo.amd.com/rocm/core/tarball/
# Docs:   https://rocm.docs.amd.com/en/latest/install/rocm.html
#
# nixpkgs rocmPackages is still 7.2.x, which has no native gfx1103 (Radeon
# 780M) support and needs HSA_OVERRIDE_GFX_VERSION=11.0.0. ROCm 10.x supports
# gfx1103 natively. This packages AMD's portable tarball as-is: the tree is
# self-contained (bundled sysdeps, $ORIGIN runpaths), so only the ELF
# interpreter and the glibc/libstdc++ lookups are patched.
#
# The package root is a regular ROCM_PATH (bin/, lib/, include/, lib/llvm/).
#
# To update:
#   1. Check the latest version: https://github.com/ROCm/TheRock/releases
#   2. Get hash: nix store prefetch-file "https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-gfx110X-all-VERSION.tar.gz"
#   3. Update version and hash below
{ lib, stdenv, fetchurl, autoPatchelfHook, zlib }:

let
  version = "10.2.0";
  hash = "sha256-tE1oVDzTPU+oXsuzhsHvVhd1CPf7Pp/rY4V9s35PT8o=";

  gcc = stdenv.cc.cc;
  libc = stdenv.cc.libc;
in
stdenv.mkDerivation {
  pname = "rocm-therock";
  inherit version;

  src = fetchurl {
    url = "https://stable.repo.amd.com/rocm/core/tarball/therock-dist-linux-gfx110X-all-${version}.tar.gz";
    inherit hash;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  # Everything else the tree needs is bundled under lib/rocm_sysdeps.
  buildInputs = [
    gcc.lib # libstdc++, libgcc_s, libquadmath, libatomic
    zlib
  ];

  # rocgdb ships one binary per Python version (3.10 to 3.14); those that
  # match no installed Python stay unpatched instead of failing the build.
  autoPatchelfIgnoreMissingDeps = [
    "libpython3.*.so.1.0"
    "libcrypt.so.1"
  ];

  # Keep AMD's $ORIGIN runpaths: the runtime dlopen()s bundled libraries
  # (sysdeps, kernel packs, hipBLASLt tensile libraries) through them.
  autoPatchelfFlags = [ "--preserve-origin" ];

  # The tree is 11 GB unpacked: extract straight into $out and leave the
  # binaries alone (stripping and rpath shrinking would break dlopen paths).
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    tar -xf $src -C $out

    # AMD's clang reads <driver>.cfg next to the executable. Extend the
    # C-family ones so amdclang, amdclang++ and hipcc find the Nix glibc and
    # libstdc++ (there is no /usr on NixOS) and emit binaries that run
    # without LD_LIBRARY_PATH.
    cat > $out/lib/llvm/bin/nix.cfg <<EOF
    --gcc-install-dir=${gcc}/lib/gcc/${stdenv.hostPlatform.config}/${gcc.version}
    -idirafter ${lib.getDev libc}/include
    -B${libc}/lib
    -L${libc}/lib
    -L${gcc.lib}/lib
    \$-fuse-ld=lld
    \$-Wl,-dynamic-linker=${stdenv.cc.bintools.dynamicLinker}
    \$-Wl,-rpath,${gcc.lib}/lib
    \$-Wl,-rpath,$out/lib
    EOF
    for cfg in clang clang++ clang-24 clang-cpp; do
      printf '\n@nix.cfg\n' >> $out/lib/llvm/bin/$cfg.cfg
    done

    runHook postInstall
  '';

  meta = {
    description = "AMD ROCm Core SDK ${version} (TheRock prebuilt, gfx110X family)";
    homepage = "https://github.com/ROCm/TheRock";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
