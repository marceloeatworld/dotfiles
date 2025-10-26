# Web app custom icons
# Icons stored locally in repo, no internet download needed
{ pkgs, lib, config, ... }:

let
  # Local icon directory in dotfiles repo
  iconSource = "${config.home.homeDirectory}/dotfiles/thinkpad-p14s-gen5/assets/icons";

  # Icon mapping: source filename -> target name
  icons = {
    "chatgpt.png" = "chatgpt.png";
    "discord.png" = "discord.png";
    "github.png" = "github.png";
    "whatsapp.png" = "whatsapp.png";
    "youtube.png" = "youtube.png";
    "docker.png" = "docker.png";
    "windows.png" = "windows.png";
    "claude.png" = "claude.png";
  };
in
{
  # Copy icons from repo to system on activation
  home.activation.installWebAppIcons = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ICON_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
    SOURCE_DIR="${iconSource}"

    if [ -d "$SOURCE_DIR" ]; then
      $DRY_RUN_CMD mkdir -p "$ICON_DIR"

      $DRY_RUN_CMD echo "📦 Installing web app icons from local repo..."

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (source: target: ''
        if [ -f "$SOURCE_DIR/${source}" ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp "$SOURCE_DIR/${source}" "$ICON_DIR/${target}"
        fi
      '') icons)}

      # Update icon cache
      $DRY_RUN_CMD ${pkgs.gtk3}/bin/gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

      $DRY_RUN_CMD echo "✅ Web app icons installed from local repo"
    else
      $DRY_RUN_CMD echo "⚠️  Icon source directory not found: $SOURCE_DIR"
    fi
  '';
}
