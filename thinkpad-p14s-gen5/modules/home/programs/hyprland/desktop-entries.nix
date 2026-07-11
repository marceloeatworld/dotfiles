# Desktop entry overrides that launch apps via *-current-workspace wrappers
# so they stay on the active Hyprland workspace instead of jumping.
{ hyprScripts, ... }:

{
  xdg.desktopEntries = {
    ferdium = {
      name = "Ferdium";
      genericName = "Messaging Workspace";
      comment = "Messaging workspace for WhatsApp and WhatsApp Business";
      exec = "${hyprScripts.ferdium-current-workspace}/bin/ferdium-current-workspace %U";
      icon = "ferdium";
      terminal = false;
      type = "Application";
      categories = [ "Network" "InstantMessaging" "Chat" ];
      mimeType = [ "x-scheme-handler/whatsapp" ];
    };

    vesktop = {
      name = "Vesktop";
      genericName = "Discord Client";
      comment = "Discord desktop client with Vencord";
      exec = "${hyprScripts.vesktop-current-workspace}/bin/vesktop-current-workspace %U";
      icon = "vesktop";
      terminal = false;
      type = "Application";
      categories = [ "Network" "InstantMessaging" "Chat" ];
      mimeType = [ "x-scheme-handler/discord" ];
    };

    spotify = {
      name = "Spotify";
      genericName = "Music Player";
      comment = "Listen to music and podcasts";
      exec = "${hyprScripts.spotify-current-workspace}/bin/spotify-current-workspace %U";
      icon = "spotify-client";
      terminal = false;
      type = "Application";
      categories = [ "Audio" "Music" "Player" "AudioVideo" ];
      mimeType = [ "x-scheme-handler/spotify" ];
    };

    "org.telegram.desktop" = {
      name = "Telegram";
      genericName = "Messaging Client";
      comment = "Telegram desktop client";
      exec = "${hyprScripts.telegram-current-workspace}/bin/telegram-current-workspace %U";
      icon = "org.telegram.desktop";
      terminal = false;
      type = "Application";
      categories = [ "Chat" "Network" "InstantMessaging" "Qt" ];
      mimeType = [
        "x-scheme-handler/tg"
        "x-scheme-handler/tonsite"
      ];
    };

    "org.keepassxc.KeePassXC" = {
      name = "KeePassXC";
      genericName = "Password Manager";
      comment = "Community-driven port of the Windows application KeePass Password Safe";
      exec = "${hyprScripts.keepassxc-current-workspace}/bin/keepassxc-current-workspace %f";
      icon = "keepassxc";
      terminal = false;
      type = "Application";
      categories = [ "Utility" "Security" "Qt" ];
      mimeType = [ "application/x-keepass2" ];
    };

    joplin = {
      name = "Joplin";
      genericName = "Note Taking";
      comment = "Note taking and to-do application";
      exec = "${hyprScripts.joplin-current-workspace}/bin/joplin-current-workspace %U";
      icon = "joplin";
      terminal = false;
      type = "Application";
      categories = [ "Office" ];
      mimeType = [ "x-scheme-handler/joplin" ];
    };

    bruno = {
      name = "Bruno";
      genericName = "API Client";
      comment = "Open source API client";
      exec = "${hyprScripts.bruno-current-workspace}/bin/bruno-current-workspace %U";
      icon = "bruno";
      terminal = false;
      type = "Application";
      categories = [ "Development" ];
    };

    rustdesk = {
      name = "RustDesk";
      genericName = "Remote Desktop";
      comment = "Remote desktop client";
      exec = "${hyprScripts.rustdesk-current-workspace}/bin/rustdesk-current-workspace %u";
      icon = "rustdesk";
      terminal = false;
      type = "Application";
      categories = [ "Network" "RemoteAccess" "GTK" ];
    };
  };
}
