# Centralized MIME type associations
# All file type → application mappings in ONE place
{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # ============================================
      # TEXT FILES → xed (GUI text editor)
      # ============================================
      "text/plain" = "org.x.editor.desktop";
      "text/x-log" = "org.x.editor.desktop";
      "text/x-readme" = "org.x.editor.desktop";
      "text/markdown" = "org.x.editor.desktop";
      "text/x-csrc" = "org.x.editor.desktop";
      "text/x-chdr" = "org.x.editor.desktop";
      "text/x-python" = "org.x.editor.desktop";
      "text/x-shellscript" = "org.x.editor.desktop";
      "application/x-shellscript" = "org.x.editor.desktop";
      "text/x-makefile" = "org.x.editor.desktop";
      "text/x-cmake" = "org.x.editor.desktop";
      "application/json" = "org.x.editor.desktop";
      "application/xml" = "org.x.editor.desktop";
      "text/xml" = "org.x.editor.desktop";

      # ============================================
      # FILE MANAGER → Nemo
      # ============================================
      "inode/directory" = "nemo.desktop";

      # ============================================
      # WEB BROWSER → Brave
      # ============================================
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";

      # ============================================
      # PDF VIEWER → Zathura
      # ============================================
      "application/pdf" = "org.pwmt.zathura.desktop";

      # ============================================
      # IMAGES → swayimg (all formats)
      # ============================================
      "image/png" = "swayimg.desktop";
      "image/jpeg" = "swayimg.desktop";
      "image/jpg" = "swayimg.desktop";
      "image/gif" = "swayimg.desktop";
      "image/webp" = "swayimg.desktop";
      "image/bmp" = "swayimg.desktop";
      "image/x-bmp" = "swayimg.desktop";
      "image/tiff" = "swayimg.desktop";
      "image/svg+xml" = "swayimg.desktop";
      "image/avif" = "swayimg.desktop";
      "image/jxl" = "swayimg.desktop";
      "image/heif" = "swayimg.desktop";
      "image/heic" = "swayimg.desktop";
      "image/x-xcf" = "swayimg.desktop";
      "image/x-portable-pixmap" = "swayimg.desktop";
      "image/x-portable-graymap" = "swayimg.desktop";
      "image/x-portable-bitmap" = "swayimg.desktop";
      "image/x-portable-anymap" = "swayimg.desktop";
      "image/x-xbitmap" = "swayimg.desktop";
      "image/x-tga" = "swayimg.desktop";
      "image/vnd.microsoft.icon" = "swayimg.desktop";
      "image/x-icon" = "swayimg.desktop";

      # ============================================
      # VIDEOS → mpv
      # ============================================
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/avi" = "mpv.desktop";
      "video/x-msvideo" = "mpv.desktop";
      "video/quicktime" = "mpv.desktop";
      "video/mpeg" = "mpv.desktop";
      "video/x-flv" = "mpv.desktop";
      "video/x-ms-wmv" = "mpv.desktop";
      "video/ogg" = "mpv.desktop";
      "video/3gpp" = "mpv.desktop";
      "video/3gpp2" = "mpv.desktop";

      # ============================================
      # AUDIO → mpv
      # ============================================
      "audio/mpeg" = "mpv.desktop";
      "audio/mp3" = "mpv.desktop";
      "audio/x-mp3" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "audio/x-flac" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/x-vorbis+ogg" = "mpv.desktop";
      "audio/wav" = "mpv.desktop";
      "audio/x-wav" = "mpv.desktop";
      "audio/aac" = "mpv.desktop";
      "audio/mp4" = "mpv.desktop";
      "audio/x-m4a" = "mpv.desktop";
      "audio/x-aac" = "mpv.desktop";
      "audio/opus" = "mpv.desktop";
      "audio/webm" = "mpv.desktop";
      "audio/x-aiff" = "mpv.desktop";
      "audio/aiff" = "mpv.desktop";
      "audio/x-ms-wma" = "mpv.desktop";

      # ============================================
      # ARCHIVES → file-roller (via Nemo)
      # ============================================
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-gzip" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-zip" = "org.gnome.FileRoller.desktop";
      "application/x-zip-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";

      # ============================================
      # WEB APP PROTOCOL HANDLERS
      # ============================================
      "x-scheme-handler/whatsapp" = "whatsapp-web.desktop";
      "x-scheme-handler/spotify" = "spotify-web.desktop";
      "x-scheme-handler/discord" = "discord-web.desktop";
      "x-scheme-handler/mailto" = "protonmail-web.desktop";
    };
  };
}
