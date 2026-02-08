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
      # VIDEOS → VLC
      # ============================================
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/avi" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "video/x-flv" = "vlc.desktop";
      "video/x-ms-wmv" = "vlc.desktop";
      "video/ogg" = "vlc.desktop";
      "video/3gpp" = "vlc.desktop";
      "video/3gpp2" = "vlc.desktop";

      # ============================================
      # AUDIO → VLC
      # ============================================
      "audio/mpeg" = "vlc.desktop";
      "audio/mp3" = "vlc.desktop";
      "audio/x-mp3" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";
      "audio/x-flac" = "vlc.desktop";
      "audio/ogg" = "vlc.desktop";
      "audio/x-vorbis+ogg" = "vlc.desktop";
      "audio/wav" = "vlc.desktop";
      "audio/x-wav" = "vlc.desktop";
      "audio/aac" = "vlc.desktop";
      "audio/mp4" = "vlc.desktop";
      "audio/x-m4a" = "vlc.desktop";
      "audio/x-aac" = "vlc.desktop";
      "audio/opus" = "vlc.desktop";
      "audio/webm" = "vlc.desktop";
      "audio/x-aiff" = "vlc.desktop";
      "audio/aiff" = "vlc.desktop";
      "audio/x-ms-wma" = "vlc.desktop";

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
