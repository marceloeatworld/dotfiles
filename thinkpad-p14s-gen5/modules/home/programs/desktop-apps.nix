# Desktop entries for applications (Neovim, Ghidra, Security Tools, etc.)
{ pkgs, pkgs-unstable, pkgs-ghidra, ... }:

let
  # Editor launcher for Neovim
  nvim-launcher = pkgs.writeShellScriptBin "nvim-launcher" ''
    #!/usr/bin/env bash
    # Launch Neovim in a new Ghostty window

    if [ -n "$1" ]; then
      # If file is provided, open it
      exec ghostty -e nvim "$@"
    else
      # Otherwise, just launch nvim
      exec ghostty -e nvim
    fi
  '';
in
{
  # Install the launcher script and applications
  # NOTE: TeamSpeak 6 is in teamspeak.nix (removed TS3 duplicate)
  home.packages = [
    nvim-launcher
    pkgs.rustdesk-flutter           # RustDesk (stable version - unstable has FFmpeg build issues)
    pkgs.popsicle                   # USB flasher (System76) - lightweight, GTK native
    pkgs.woeusb-ng                   # Windows USB flasher - for Windows ISO
    pkgs.ntfs3g                      # NTFS support - required by woeusb-ng
    pkgs.parted                      # Disk partitioning tool
    pkgs.exfatprogs                  # exFAT formatting (mkfs.exfat)
    pkgs.gparted                     # GUI disk partitioning
  ];

  # Desktop entries for desktop applications
  xdg.desktopEntries = {
    # Neovim with custom launcher
    nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "nvim-launcher %F";
      icon = "nvim";
      terminal = false;
      type = "Application";
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
    };

    # Ghidra - Software Reverse Engineering
    ghidra = {
      name = "Ghidra";
      genericName = "Reverse Engineering";
      comment = "NSA Software Reverse Engineering Suite";
      exec = "${pkgs-ghidra.ghidra}/bin/ghidra";
      icon = "ghidra";
      terminal = false;
      type = "Application";
      categories = [ "Development" "System" ];
    };

    # Wireshark - Network Protocol Analyzer
    wireshark = {
      name = "Wireshark";
      genericName = "Network Analyzer";
      comment = "Network traffic analyzer and packet sniffer";
      exec = "${pkgs.wireshark}/bin/wireshark";
      icon = "wireshark";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" ];
    };

    # GIMP 3 - Force single entry
    gimp = {
      name = "GIMP 3 (PhotoGIMP)";
      genericName = "Image Editor";
      comment = "Create images and edit photographs (Photoshop-like interface)";
      exec = "${pkgs.gimp3}/bin/gimp-3.0 %U";
      icon = "gimp";
      terminal = false;
      type = "Application";
      categories = [ "Graphics" "2DGraphics" "RasterGraphics" ];
      mimeType = [
        "image/bmp"
        "image/g3fax"
        "image/gif"
        "image/x-fits"
        "image/x-pcx"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-psd"
        "image/x-sgi"
        "image/x-tga"
        "image/x-xbitmap"
        "image/x-xwindowdump"
        "image/x-xcf"
        "image/x-compressed-xcf"
        "image/x-gimp-gbr"
        "image/x-gimp-pat"
        "image/x-gimp-gih"
        "image/tiff"
        "image/jpeg"
        "image/x-psp"
        "image/png"
        "image/x-icon"
        "image/x-xpixmap"
        "image/x-exr"
        "image/webp"
        "image/x-webp"
        "image/heif"
        "image/heic"
        "image/svg+xml"
        "image/x-wmf"
        "image/jp2"
        "image/x-xcursor"
      ];
    };

    # === SECURITY TOOLS ===

    # Zenmap - Nmap GUI
    zenmap = {
      name = "Zenmap";
      genericName = "Network Scanner";
      comment = "Graphical frontend for Nmap security scanner";
      exec = "sudo ${pkgs.zenmap}/bin/zenmap";
      icon = "zenmap";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" "System" ];
    };

    # Kismet - Wireless Network Detector
    kismet = {
      name = "Kismet";
      genericName = "Wireless Network Detector";
      comment = "Wireless network detector, sniffer, and intrusion detection system";
      exec = "ghostty -e sudo kismet";
      icon = "kismet";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" ];
    };

    # Hashcat - GPU Password Cracker
    hashcat = {
      name = "Hashcat";
      genericName = "Password Recovery";
      comment = "Advanced GPU-accelerated password recovery tool";
      exec = "ghostty -e hashcat --help";
      icon = "dialog-password";
      terminal = false;
      type = "Application";
      categories = [ "System" "Security" ];
    };

    # Aircrack-ng Suite
    aircrack-ng = {
      name = "Aircrack-ng";
      genericName = "WiFi Security Auditing";
      comment = "Complete suite of tools to assess WiFi network security";
      exec = "ghostty -e aircrack-ng --help";
      icon = "network-wireless";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" ];
    };

    # Wifite2 - Automated WiFi Auditing
    wifite = {
      name = "Wifite2";
      genericName = "Automated WiFi Auditing";
      comment = "Automated wireless attack tool for WEP/WPA/WPS";
      exec = "ghostty -e sudo wifite --help";
      icon = "network-wireless-signal-excellent";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" ];
    };

    # Bettercap - MITM Framework
    bettercap = {
      name = "Bettercap";
      genericName = "Network Attack Framework";
      comment = "Complete, modular, portable MITM framework";
      exec = "ghostty -e sudo bettercap --help";
      icon = "network-wired";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" ];
    };

    # SQLMap - SQL Injection Tool
    sqlmap = {
      name = "SQLMap";
      genericName = "SQL Injection Testing";
      comment = "Automatic SQL injection and database takeover tool";
      exec = "ghostty -e sqlmap --help";
      icon = "database";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" "Development" ];
    };

    # Nikto - Web Scanner
    nikto = {
      name = "Nikto";
      genericName = "Web Server Scanner";
      comment = "Web server vulnerability scanner";
      exec = "ghostty -e nikto --help";
      icon = "web-browser";
      terminal = false;
      type = "Application";
      categories = [ "Network" "Security" ];
    };

    # John the Ripper
    john = {
      name = "John the Ripper";
      genericName = "Password Cracker";
      comment = "Fast password cracker for various hash types";
      exec = "ghostty -e john";
      icon = "dialog-password";
      terminal = false;
      type = "Application";
      categories = [ "System" "Security" ];
    };

    # === SYSTEM TOOLS ===

    # Popsicle - USB Flasher
    popsicle = {
      name = "Popsicle";
      genericName = "USB Flasher";
      comment = "Flash multiple USB drives in parallel (System76)";
      exec = "${pkgs.popsicle}/bin/popsicle-gtk";
      icon = "usb-creator";
      terminal = false;
      type = "Application";
      categories = [ "System" "Utility" ];
    };
  };

  # NOTE: MIME types are centralized in ../config/mimeapps.nix
}
