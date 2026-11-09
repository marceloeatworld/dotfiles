# Brave Latest - upstream .deb from the Brave GitHub releases
# Source: https://github.com/brave/brave-browser/releases
#
# nixpkgs removed brave on 2026-11-03 ("no committers among its maintainers
# to unblock security issues"). This is the last nixpkgs builder
# (pkgs/applications/networking/browsers/brave/make-brave.nix at nixpkgs
# 09063bd1) trimmed to Linux x86_64 and the regular browser flavor.
# The wrapper keeps the nixpkgs --enable-features/--disable-features flags:
# modules/system/security.nix documents and overrides them.
#
# To update:
#   1. Run: update-brave (shell function, also part of update-overlays)
#   2. Or manually:
#      a. Check latest: curl -s https://versions.brave.com/latest/release-linux-x64.version
#      b. Get hash: nix-prefetch-url "https://github.com/brave/brave-browser/releases/download/vVERSION/brave-browser_VERSION_amd64.deb"
#      c. Convert: nix hash convert --hash-algo sha256 --to sri HASH
#      d. Update version and sha256 below
{
  lib,
  stdenv,
  fetchurl,
  buildPackages,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  qt6,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libdrm,
  libkrb5,
  libuuid,
  libxkbcommon,
  libxshmfence,
  libgbm,
  nspr,
  nss,
  pango,
  pciutils,
  pipewire,
  snappy,
  speechd-minimal,
  udev,
  wayland,
  xdg-utils,
  coreutils,
  libxcb,
  vulkan-loader,
  zlib,
  libpulseaudio,
  libGL,
  libva,
}:

let
  # AUTO-UPDATED BY update-brave
  version = "1.99.55";
  sha256 = "sha256-Nk6VSirYTVuj4OIXoinVhzxK5xB9FeYSDkIHUpU5yI0=";

  deps = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    gtk4
    libdrm
    libx11
    libGL # GPU acceleration on Wayland
    libxkbcommon
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxshmfence
    libxtst
    libuuid
    libgbm
    nspr
    nss
    pango
    pciutils # ANGLE dlopens libpci to identify GPUs, including for VA-API device selection.
    pipewire
    udev
    wayland
    libxcb
    zlib
    snappy
    speechd-minimal # Text-to-speech through speech-dispatcher (--enable-speech-dispatcher).
    libkrb5
    vulkan-loader # Chromium and Dawn dlopen libvulkan.so.1 by name.
    qt6.qtbase
    libpulseaudio # Necessary for USB audio devices.
    libva # VA-API video acceleration
  ];

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath deps;
in
stdenv.mkDerivation {
  pname = "brave";
  inherit version;

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchurl {
    url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser_${version}_amd64.deb";
    inherit sha256;
  };

  dontConfigure = true;
  dontBuild = true;
  dontPatchELF = true;
  doInstallCheck = true;

  nativeBuildInputs = [
    dpkg
    # override doesn't preserve splicing https://github.com/NixOS/nixpkgs/issues/132651
    # Has to use `makeShellWrapper` from `buildPackages` even though `makeShellWrapper` from the inputs is spliced because `propagatedBuildInputs` would pick the wrong one because of a different offset.
    (buildPackages.wrapGAppsHook3.override { makeWrapper = buildPackages.makeShellWrapper; })
  ];

  buildInputs = [
    # needed for GSETTINGS_SCHEMAS_PATH
    glib
    gsettings-desktop-schemas
    gtk3
    gtk4

    # needed for XDG_ICON_DIRS
    adwaita-icon-theme
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out $out/bin

    cp -R usr/share $out
    cp -R opt/ $out/opt

    export BINARYWRAPPER=$out/opt/brave.com/brave/brave-browser

    # Fix path to bash in $BINARYWRAPPER
    substituteInPlace $BINARYWRAPPER \
        --replace-fail /bin/bash ${stdenv.shell} \
        --replace-fail 'CHROME_WRAPPER' 'WRAPPER'

    ln -sf $BINARYWRAPPER $out/bin/brave

    for exe in $out/opt/brave.com/brave/{brave,chrome_crashpad_handler}; do
        patchelf \
            --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
            --set-rpath "${rpath}" $exe
    done

    # Fix paths
    substituteInPlace $out/share/applications/{brave-browser,com.brave.Browser}.desktop \
        --replace-fail /usr/bin/brave-browser-stable $out/bin/brave
    substituteInPlace $out/share/gnome-control-center/default-apps/brave-browser.xml \
        --replace-fail /opt/brave.com $out/opt/brave.com
    substituteInPlace $out/opt/brave.com/brave/default-app-block \
        --replace-fail /opt/brave.com $out/opt/brave.com

    # Correct icons location
    icon_sizes=("16" "24" "32" "48" "64" "128" "256")

    for icon in ''${icon_sizes[*]}
    do
        mkdir -p $out/share/icons/hicolor/''${icon}x''${icon}/apps
        ln -s $out/opt/brave.com/brave/product_logo_''${icon}.png $out/share/icons/hicolor/''${icon}x''${icon}/apps/brave-browser.png
    done

    # ANGLE loads this copy by absolute path; the NixOS-patched loader finds ICDs
    # under /run/opengl-driver, the bundled one does not.
    rm $out/opt/brave.com/brave/libvulkan.so.1
    ln -s ${lib.getLib vulkan-loader}/lib/libvulkan.so.1 $out/opt/brave.com/brave/libvulkan.so.1

    # Replace xdg-settings and xdg-mime
    ln -sf ${xdg-utils}/bin/xdg-settings $out/opt/brave.com/brave/xdg-settings
    ln -sf ${xdg-utils}/bin/xdg-mime $out/opt/brave.com/brave/xdg-mime

    runHook postInstall
  '';

  # OutdatedBuildDetector off = no automatic update prompts.
  # UseChromeOSDirectVideoDecoder off is needed for VA-API:
  # https://github.com/brave/brave-browser/issues/20935
  preFixup = ''
    # Add command line args to wrapGApp.
    gappsWrapperArgs+=(
      --prefix LD_LIBRARY_PATH : ${rpath}
      --prefix PATH : ${binpath}
      --suffix PATH : ${
        lib.makeBinPath [
          xdg-utils
          coreutils
        ]
      }
      --set CHROME_WRAPPER brave
      --add-flags "--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+,WaylandWindowDecorations --enable-wayland-ime=true}}"
      --add-flags "--disable-features=OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
    )
  '';

  installCheckPhase = ''
    # Bypass upstream wrapper which suppresses errors
    $out/opt/brave.com/brave/brave --version
  '';

  meta = {
    homepage = "https://brave.com/";
    description = "Privacy-oriented browser for Desktop and Laptop computers";
    changelog =
      "https://github.com/brave/brave-browser/blob/master/CHANGELOG_DESKTOP.md#"
      + lib.replaceStrings [ "." ] [ "" ] version;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "brave";
  };
}
