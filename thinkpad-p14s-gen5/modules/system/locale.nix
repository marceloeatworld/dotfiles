# Locale and internationalization
{ pkgs, ... }:

{
  # Time zone
  time.timeZone = "Europe/Lisbon";

  # Locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  # All LC_* categories follow i18n.defaultLocale (en_US.UTF-8); the explicit
  # per-category block was a no-op and has been removed.

  # Console configuration - Terminus 20px (28px was too big on the 1920x1200
  # panel), loaded from the initrd so kernel/LUKS output uses it early at boot.
  console = {
    earlySetup = true;
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v20n.psf.gz";
    packages = [ pkgs.terminus_font ];
    keyMap = "fr";
  };

  # X11 keyboard layout
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };
}
