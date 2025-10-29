# Desktop entries for applications (Neovim, etc.)
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
    # Images → swayimg (all formats including WebP, AVIF, JXL)
    "image/png" = "swayimg.desktop";
    "image/jpeg" = "swayimg.desktop";
    "image/jpg" = "swayimg.desktop";
    "image/gif" = "swayimg.desktop";
    "image/bmp" = "swayimg.desktop";
    "image/x-bmp" = "swayimg.desktop";
    "image/webp" = "swayimg.desktop";
    "image/tiff" = "swayimg.desktop";
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
    "image/svg+xml" = "swayimg.desktop";
    "image/vnd.microsoft.icon" = "swayimg.desktop";
    "image/x-icon" = "swayimg.desktop";

    # Text files → Neovim
    "text/plain" = "nvim.desktop";
    "text/x-makefile" = "nvim.desktop";
    "text/x-shellscript" = "nvim.desktop";
    "application/x-shellscript" = "nvim.desktop";
  };
}
