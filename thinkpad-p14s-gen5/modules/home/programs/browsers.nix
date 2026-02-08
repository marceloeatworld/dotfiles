# Browser configuration
{ pkgs, ... }:

{
  # Brave is installed via Firejail wrappedBinaries in modules/system/security.nix
  # with Wayland flags and sandboxing. No need to install it here separately.

  # NOTE: MIME types are centralized in ../config/mimeapps.nix
}
