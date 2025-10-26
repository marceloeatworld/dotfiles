# Desktop entries for applications (IMV, Neovim, etc.)
{ pkgs, ... }:

let
  # Editor launcher for Neovim
  nvim-launcher = pkgs.writeShellScriptBin "nvim-launcher" ''
    #!/usr/bin/env bash
    # Launch Neovim in a new Kitty window

    if [ -n "$1" ]; then
      # If file is provided, open it
      exec kitty -e nvim "$@"
    else
      # Otherwise, just launch nvim
      exec kitty -e nvim
    fi
  '';
in
{
  # Install the launcher script
  home.packages = [ nvim-launcher ];

  # Desktop entries for desktop applications
  xdg.desktopEntries = {
    # IMV Image Viewer
    imv = {
      name = "Image Viewer";
      genericName = "Image Viewer";
      comment = "Fast image viewer for Wayland";
      exec = "imv %F";
      icon = "imv";
      terminal = false;
      type = "Application";
      categories = [ "Graphics" "Viewer" ];
      mimeType = [
        "image/png"
        "image/jpeg"
        "image/jpg"
        "image/gif"
        "image/bmp"
        "image/webp"
        "image/tiff"
        "image/x-xcf"
        "image/x-portable-pixmap"
        "image/x-xbitmap"
      ];
    };

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
  };

  # Set default applications for file types
  xdg.mimeApps.defaultApplications = {
    # Images → IMV
    "image/png" = "imv.desktop";
    "image/jpeg" = "imv.desktop";
    "image/jpg" = "imv.desktop";
    "image/gif" = "imv.desktop";
    "image/bmp" = "imv.desktop";
    "image/webp" = "imv.desktop";
    "image/tiff" = "imv.desktop";

    # Text files → Neovim
    "text/plain" = "nvim.desktop";
    "text/x-makefile" = "nvim.desktop";
    "text/x-shellscript" = "nvim.desktop";
    "application/x-shellscript" = "nvim.desktop";
  };
}
