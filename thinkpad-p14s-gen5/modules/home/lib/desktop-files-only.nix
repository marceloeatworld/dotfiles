# Desktop entry, icons and MIME data of a package, without its bin/.
#
# The per-user profile comes before /run/current-system/sw/bin in PATH, so
# installing an application's full package in home.packages makes "<app>"
# resolve to the raw binary and silently bypasses the firejail wrapper that
# security.nix generates for it (found 2026-09-06: 12 of 18 wrappers were
# never used). Install this instead: the launcher still sees the .desktop
# file and icon, and Exec=<app> resolves to the wrapper.
{ pkgs, lib }:
pkg:
pkgs.runCommandLocal "${lib.getName pkg}-desktop-files" { } ''
  mkdir -p $out/share
  for d in applications icons mime pixmaps metainfo; do
    if [ -e ${pkg}/share/$d ]; then
      ln -s ${pkg}/share/$d $out/share/$d
    fi
  done
''
