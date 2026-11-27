# Yaru theme - restored after nixpkgs removed it on 2026-07-22 along with
# gtk-engine-murrine (unmaintained, GTK 2). This is the last nixpkgs
# derivation (25.10.3) with the murrine propagation dropped: only the legacy
# GTK 2 theme needed it, and nothing here uses GTK 2. Icon themes and the
# GTK 3/4 themes build unchanged.
{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  sassc,
  pkg-config,
  glib,
  ninja,
  python3,
  gtk3,
  gnome-themes-extra,
  humanity-icon-theme,
  hicolor-icon-theme,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "yaru";
  version = "26.10.3";

  src = fetchFromGitHub {
    owner = "ubuntu";
    repo = "yaru";
    rev = finalAttrs.version;
    hash = "sha256-E8CYl0i9/UzlwhnmBl8IDDeAoB9AxOWAbOnPm2HOcz0=";
  };

  nativeBuildInputs = [
    meson
    sassc
    pkg-config
    glib
    ninja
    python3
  ];
  buildInputs = [
    gtk3
    gnome-themes-extra
  ];
  propagatedBuildInputs = [
    humanity-icon-theme
    hicolor-icon-theme
  ];

  dontDropIconThemeCache = true;

  postPatch = "patchShebangs .";

  meta = {
    description = "Ubuntu community theme 'yaru' - default Ubuntu theme since 18.10";
    homepage = "https://github.com/ubuntu/yaru";
    license = with lib.licenses; [
      cc-by-sa-40
      gpl3Plus
      lgpl21Only
      lgpl3Only
    ];
    platforms = lib.platforms.linux;
  };
})
