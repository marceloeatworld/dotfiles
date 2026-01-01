# VS Code Latest - Always fetches the specified version from Microsoft
#
# HOW TO UPDATE TO LATEST VERSION:
# 1. Check current version: code --version
# 2. Check latest version: curl -sI "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" | grep -i location
# 3. Get new hash: nix-prefetch-url "https://update.code.visualstudio.com/VERSION/linux-x64/stable"
# 4. Convert hash: nix hash to-sri --type sha256 HASH
# 5. Update version and hash below
#
# Or use the helper script: update-vscode (defined in shell.nix)

{ lib, fetchurl, vscode, ... }:

let
  # ============================================
  # UPDATE THESE VALUES FOR NEW VERSIONS
  # ============================================
  version = "1.107.1";
  sha256 = "sha256-qaGeIN0Jxh7Br31n2d7CRVAE0PvTUSD+HSRYjBI/lHQ=";
  # ============================================
in
vscode.overrideAttrs (oldAttrs: {
  inherit version;

  src = fetchurl {
    url = "https://update.code.visualstudio.com/${version}/linux-x64/stable";
    inherit sha256;
    name = "vscode-${version}.tar.gz";
  };

  # Keep all other attributes from the original package
  meta = oldAttrs.meta // {
    description = "Visual Studio Code - Latest version from Microsoft (${version})";
  };
})
