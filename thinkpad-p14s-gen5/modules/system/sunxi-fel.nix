# Allwinner FEL-mode USB access for sunxi-fel (PocketCHIP, SoC R8)
# Grants non-root access to the device so sunxi-fel works WITHOUT sudo.
# (Running sunxi-fel under sudo strips the env and breaks libusb enumeration.)
{ ... }:

{
  services.udev.extraRules = ''
    # Allwinner FEL bootrom (PocketCHIP, idVendor 1f3a / idProduct efe8)
    SUBSYSTEM=="usb", ATTR{idVendor}=="1f3a", ATTR{idProduct}=="efe8", MODE="0666"
  '';
}
