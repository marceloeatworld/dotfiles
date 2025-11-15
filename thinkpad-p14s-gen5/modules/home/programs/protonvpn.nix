# ProtonVPN GUI with fix for proton-core bcrypt test failures
{ config, pkgs, pkgs-unstable, ... }:

let
  # Create a custom Python environment with proton-core tests disabled
  python3-fixed = pkgs-unstable.python3.override {
    packageOverrides = self: super: {
      proton-core = super.proton-core.overridePythonAttrs (oldAttrs: {
        # Skip tests due to bcrypt 72-byte password limit incompatibility
        # Tests use 78-byte passwords that fail with newer bcrypt versions
        doCheck = false;
        doInstallCheck = false;
      });
    };
  };

  # Build protonvpn-gui with our fixed Python
  protonvpn-gui-fixed = pkgs-unstable.protonvpn-gui.overridePythonAttrs (oldAttrs: {
    # Use the Python environment with fixed proton-core
    propagatedBuildInputs = map (pkg:
      if pkg.pname or "" == "python3" then python3-fixed
      else pkg
    ) (oldAttrs.propagatedBuildInputs or []);
  });

in
{
  home.packages = [
    protonvpn-gui-fixed
  ];
}
