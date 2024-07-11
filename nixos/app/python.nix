{ pkgs, ... }:
let
  myPython = pkgs.python313;
  myPythonPackages = myPython.pkgs;
in
{
  environment.systemPackages = with pkgs; [
    (myPython.withPackages (ps: with ps; [
      pip
      virtualenv
      setuptools
    ]))
  ];

  environment.sessionVariables = {
    PYTHONBIN = "${myPython}/bin/python3.13";
    PIP = "${myPythonPackages.pip}/bin/pip";
  };

  environment.shellAliases = {
    python = "$(PYTHONBIN)";
    pip = "$(PIP)";
  };
}
