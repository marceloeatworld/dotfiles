{ ... }:

{
  programs.yt-dlp = {
    enable = true;

    settings = {
      # Balanced quality/size (1080p max)
      format = "bestvideo[height<=1080]+bestaudio/best";

      # Essential metadata
      embed-thumbnail = true;
      embed-metadata = true;

      # French/English subtitles
      embed-subs = true;
      sub-langs = "fr,en";

      # Simple output into the Videos directory
      output = "~/Videos/%(title)s.%(ext)s";

      # No playlist by default (safety)
      no-playlist = true;
    };
  };
}
