{ config, pkgs, ... }:

{
  programs.yt-dlp = {
    enable = true;

    settings = {
      # Qualité/taille équilibrée (1080p max)
      format = "bestvideo[height<=1080]+bestaudio/best";

      # Métadonnées essentielles
      embed-thumbnail = true;
      embed-metadata = true;

      # Sous-titres français/anglais
      embed-subs = true;
      sub-langs = "fr,en";

      # Output simple dans dossier Videos
      output = "~/Videos/%(title)s.%(ext)s";

      # Pas de playlist par défaut (sécurité)
      no-playlist = true;
    };
  };
}
