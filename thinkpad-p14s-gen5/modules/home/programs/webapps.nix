# Web applications using Brave
# Creates "native-like" web apps using Brave's --app flag
{ pkgs, ... }:

{
  # Desktop entries for web apps
  xdg.desktopEntries = {
    # Windows 11 VM
    windows-vm = {
      name = "Windows 11";
      genericName = "Virtual Machine";
      comment = "Windows 11 VM via Docker with RDP";
      exec = "windows-vm launch";
      icon = "windows";
      terminal = false;
      type = "Application";
      categories = [ "System" "Emulator" ];
    };

    # WhatsApp Web
    whatsapp-web = {
      name = "WhatsApp";
      genericName = "Messaging";
      comment = "WhatsApp Web Application";
      exec = "brave --app=https://web.whatsapp.com/";
      icon = "whatsapp";
      terminal = false;
      categories = [ "Network" "InstantMessaging" ];
      mimeType = [ "x-scheme-handler/whatsapp" ];
    };

    # YouTube (bonus - useful for Hyprland window rules)
    youtube-web = {
      name = "YouTube";
      genericName = "Video Streaming";
      comment = "YouTube Web Application";
      exec = "brave --app=https://youtube.com/";
      icon = "youtube";
      terminal = false;
      categories = [ "Network" "AudioVideo" "Video" ];
    };

    # ChatGPT (bonus - popular for productivity)
    chatgpt-web = {
      name = "ChatGPT";
      genericName = "AI Assistant";
      comment = "ChatGPT Web Application";
      exec = "brave --app=https://chatgpt.com/";
      icon = "chatgpt";  # Icon name only (installed in hicolor theme)
      terminal = false;
      categories = [ "Office" ];  # Single main category to avoid duplicates
    };

    # GitHub (bonus - for developers)
    github-web = {
      name = "GitHub";
      genericName = "Development Platform";
      comment = "GitHub Web Application";
      exec = "brave --app=https://github.com/";
      icon = "github";
      terminal = false;
      categories = [ "Development" ];  # Single main category
    };

    # Discord
    discord-web = {
      name = "Discord";
      genericName = "Chat & Voice";
      comment = "Discord Web Application";
      exec = "brave --app=https://discord.com/channels/@me";
      icon = "discord";
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
      icon = "claude";
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

    # Proton Pass
    protonpass-web = {
      name = "Proton Pass";
      genericName = "Password Manager";
      comment = "Proton Pass Web Application";
      exec = "brave --app=https://pass.proton.me/";
      icon = "dialog-password";  # Generic password icon from system
      terminal = false;
      categories = [ "Network" "Utility" "Security" ];
    };
  };
}

