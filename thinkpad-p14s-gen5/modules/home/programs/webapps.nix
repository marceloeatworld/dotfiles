# Web applications using Brave
# Creates "native-like" web apps using Brave's --app flag
{ pkgs, ... }:

{
  # Desktop entries for web apps
  xdg.desktopEntries = {
    # YouTube (PiP window rules match this app class)
    youtube-web = {
      name = "YouTube";
      genericName = "Video Streaming";
      comment = "YouTube Web Application";
      exec = "brave --app=https://youtube.com/";
      icon = "youtube";
      terminal = false;
      categories = [ "Network" "AudioVideo" "Video" ];
    };

    # Twitch (PiP window rules match this app class)
    twitch-web = {
      name = "Twitch";
      genericName = "Live Streaming";
      comment = "Twitch Web Application";
      exec = "brave --app=https://twitch.tv/";
      icon = "twitch";  # assets/icons/twitch.png (webapp-icons.nix)
      terminal = false;
      categories = [ "Network" "AudioVideo" "Video" ];
    };

    # ChatGPT
    chatgpt-web = {
      name = "ChatGPT";
      genericName = "AI Assistant";
      comment = "ChatGPT Web Application";
      exec = "brave --app=https://chatgpt.com/";
      icon = "chatgpt";  # Icon name only (installed in hicolor theme)
      terminal = false;
      categories = [ "Office" ];  # Single main category to avoid duplicates
    };

    # GitHub
    github-web = {
      name = "GitHub";
      genericName = "Development Platform";
      comment = "GitHub Web Application";
      exec = "brave --app=https://github.com/";
      icon = "github";
      terminal = false;
      categories = [ "Development" ];  # Single main category
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
      icon = "protonmail";  # assets/icons/protonmail.png (webapp-icons.nix)
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
      icon = "protonpass";  # assets/icons/protonpass.png (webapp-icons.nix)
      terminal = false;
      categories = [ "Network" "Utility" "Security" ];
    };
  };
}

