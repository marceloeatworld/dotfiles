# SANE support for the Canon CanoScan LiDE 400 (USB 04a9:1912).
# The device is handled by the pixma backend shipped with sane-backends
# (backend/pixma/pixma_mp150.c), and its USB id is already in SANE's hwdb, so
# enabling SANE is enough to get both the driver and the udev permissions.
# Access is granted through the "scanner" group, which hardware.sane.enable
# creates. Canon ships no Linux driver for this model; pixma is the only one.
{ pkgs, ... }:

let
  # Serial-qualified device name, stable for this unit. Same approach as the
  # hardcoded printer URI in services.nix.
  device = "pixma:04A91912_51D5A4";

  # Archival masters: 48-bit colour at 600 dpi with linear gamma. Colour is kept
  # even for monochrome-looking documents because it records paper tone, and
  # pencil versus ink, which grayscale flattens away. Linear gamma keeps the full
  # tonal range for later contrast work; the raw file looks flat on purpose.
  scanArgs = "--mode '48 bits color' --resolution 600 --gamma 1.0 --format=tiff";

  scanLibrary = "$HOME/Pictures/scans";

  coreutils = "${pkgs.coreutils}/bin";

  # Falls back to a timestamped name when none is given, then resolves where the
  # file lands: a bare filename goes to the scan library so masters cannot be
  # scattered across whatever directory the shell happened to be in, while
  # anything containing a slash is an explicit path used exactly as given.
  resolveOut = prefix: ''
    if [ -z "$name" ]; then
      name="${prefix}-$(${coreutils}/date +%Y%m%d-%H%M%S).tif"
    fi
    case "$name" in
      */*) out="$name" ;;
      *)   out="${scanLibrary}/$name" ;;
    esac
    ${coreutils}/mkdir -p "$(${coreutils}/dirname "$out")"
  '';

  scan-doc = pkgs.writeShellScriptBin "scan-doc" ''
    set -euo pipefail
    if [ $# -gt 1 ]; then
      echo "Usage: scan-doc [output.tif]" >&2
      echo "  48-bit colour, 600 dpi, linear gamma, full A4. About 205 MB." >&2
      echo "  No name given: scan-YYYYMMDD-HHMMSS.tif" >&2
      echo "  A bare name goes to ${scanLibrary}/; a path is used as given." >&2
      exit 1
    fi
    name="''${1:-}"
    ${resolveOut "scan"}
    ${pkgs.sane-backends}/bin/scanimage -d '${device}' ${scanArgs} -o "$out"
    echo "Wrote $out"
  '';

  # Photographs use the same quality settings; 600 dpi is the standard for
  # photographic prints. Cropping to the print is what keeps the size sane, since
  # a small print scanned at full A4 wastes most of the file on empty glass.
  # A first argument made only of digits is a width, not a filename, so the size
  # can be given without naming the file.
  scan-photo = pkgs.writeShellScriptBin "scan-photo" ''
    set -euo pipefail
    if [ $# -gt 3 ]; then
      echo "Usage: scan-photo [output.tif] [width_mm] [height_mm]" >&2
      echo "  48-bit colour, 600 dpi, linear gamma. Defaults to full A4." >&2
      echo "  No name given: photo-YYYYMMDD-HHMMSS.tif" >&2
      echo "  Examples: scan-photo 50 68            (auto name, 5x6.8 cm)" >&2
      echo "            scan-photo grandpa.tif 50 68" >&2
      exit 1
    fi
    name=""
    case "''${1:-}" in
      "")       ;;                    # nothing given, auto-name below
      *[!0-9]*) name="$1"; shift ;;   # holds a non-digit, so it is a filename
      *)        ;;                    # all digits, so it is a width
    esac
    ${resolveOut "photo"}
    width="''${1:-216}"
    height="''${2:-297}"
    ${pkgs.sane-backends}/bin/scanimage -d '${device}' ${scanArgs} \
      -l 0 -t 0 -x "$width" -y "$height" -o "$out"
    echo "Wrote $out ($width x $height mm)"
  '';
in
{
  hardware.sane.enable = true;

  # xsane exposes every backend option, including the "48 bits color" and
  # "16 bits gray" modes needed for archival masters. Lighter frontends such as
  # simple-scan hide those modes entirely.
  environment.systemPackages = with pkgs; [
    xsane
    scan-doc
    scan-photo
  ];

  users.users.marcelo.extraGroups = [ "scanner" ];
}
