# Web app custom icons
# Icons stored in repo, deployed at build time via home.file (no runtime repo dependency)
{ pkgs, lib, ... }:

let
  iconDir = ../../../assets/icons;

  iconFiles = [
    "chatgpt.png"
    "github.png"
    "youtube.png"
    "docker.png"
    "windows.png"
    "claude.png"
  ];
in
{
  home.file = lib.listToAttrs (map (name: {
    name = ".local/share/icons/hicolor/256x256/apps/${name}";
    value = { source = iconDir + "/${name}"; };
  }) iconFiles);

  # Update icon cache when icons change
  home.activation.updateIconCache = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
  '';
}
