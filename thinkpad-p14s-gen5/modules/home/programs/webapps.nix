# Web applications using Brave
# Creates "native-like" web apps using Brave's --app flag
{ pkgs, ... }:

{
  # Desktop entries for web apps
  xdg.desktopEntries = {
    # WhatsApp Web
    whatsapp-web = {
      name = "WhatsApp";
      genericName = "Messaging";
      comment = "WhatsApp Web Application";
      exec = "brave --app=https://web.whatsapp.com/";
      icon = "whatsapp";  # From Papirus icon theme
      terminal = false;
      categories = [ "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/whatsapp" ];
    };

    # Spotify Web Player
    spotify-web = {
      name = "Spotify";
      genericName = "Music Streaming";
      comment = "Spotify Web Player";
      exec = "brave --app=https://open.spotify.com/";
      icon = "spotify";  # From Papirus icon theme
      terminal = false;
      categories = [ "Audio" "Music" "Player" "AudioVideo" ];
      mimeType = [ "x-scheme-handler/spotify" ];
    };

    # YouTube (bonus - useful for Hyprland window rules)
    youtube-web = {
      name = "YouTube";
      genericName = "Video Streaming";
      comment = "YouTube Web Application";
      exec = "brave --app=https://youtube.com/";
      icon = "youtube";  # From Papirus icon theme
      terminal = false;
      categories = [ "Network" "AudioVideo" "Video" ];
    };

    # ChatGPT (bonus - popular for productivity)
    chatgpt-web = {
      name = "ChatGPT";
      genericName = "AI Assistant";
      comment = "ChatGPT Web Application";
      exec = "brave --app=https://chatgpt.com/";
      icon = "openai";  # From Papirus icon theme (OpenAI logo)
      terminal = false;
      categories = [ "Network" "Office" ];
    };

    # GitHub (bonus - for developers)
    github-web = {
      name = "GitHub";
      genericName = "Development Platform";
      comment = "GitHub Web Application";
      exec = "brave --app=https://github.com/";
      icon = "github";  # From Papirus icon theme
      terminal = false;
      categories = [ "Network" "Development" ];
    };

    # Discord
    discord-web = {
      name = "Discord";
      genericName = "Chat & Voice";
      comment = "Discord Web Application";
      exec = "brave --app=https://discord.com/channels/@me";
      icon = "discord";  # From Papirus icon theme
      terminal = false;
      categories = [ "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/discord" ];
    };

    # Claude AI
    claude-web = {
      name = "Claude";
      genericName = "AI Assistant";
      comment = "Claude AI Web Application";
      exec = "brave --app=https://claude.ai/";
      icon = "claude";  # Will use generic AI icon if not available
      terminal = false;
      categories = [ "Network" "Office" "Development" ];
    };

    # Proton Mail
    protonmail-web = {
      name = "Proton Mail";
      genericName = "Email Client";
      comment = "Proton Mail Web Application";
      exec = "brave --app=https://mail.proton.me/";
      icon = "protonmail";  # From Papirus icon theme
      terminal = false;
      categories = [ "Network" "Email" "Office" ];
      mimeType = [ "x-scheme-handler/mailto" ];
    };

    # Proton Drive
    protondrive-web = {
      name = "Proton Drive";
      genericName = "Cloud Storage";
      comment = "Proton Drive Web Application";
      exec = "brave --app=https://drive.proton.me/";
      icon = "drive-harddisk";  # Generic drive icon from system
      terminal = false;
      categories = [ "Network" "FileTransfer" "Office" ];
    };
  };
}

