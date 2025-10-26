# Security configuration
{ pkgs, ... }:

{
  # Enable GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Fingerprint reader support (disabled - not available on this model)
  # services.fprintd = {
  #   enable = true;
  # };

  # PAM configuration
  security.pam.services = {
    # Allow swaylock to unlock
    swaylock = {};

    # Fingerprint authentication (disabled - not available)
    # login.fprintAuth = true;
    # sudo.fprintAuth = true;
  };

  # Gnome Keyring for secrets management
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.marcelo.enableGnomeKeyring = true;

  # AppArmor for additional security (optional)
  security.apparmor.enable = true;

  # Polkit rules for TLP battery threshold management
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program") == "/run/current-system/sw/bin/tlp" &&
          subject.user == "marcelo") {
        return polkit.Result.YES;
      }
    });
  '';

  # USB Guard for USB device authorization (optional, can be strict)
  # services.usbguard.enable = true;
}
