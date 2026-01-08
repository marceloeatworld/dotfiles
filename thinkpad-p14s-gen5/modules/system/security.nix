# Security configuration
{ pkgs, ... }:

{
  # === FIREJAIL SANDBOXING ===
  # Isolates applications to limit their access to the system
  # When enabled, running "brave" actually runs "firejail brave"
  programs.firejail = {
    enable = true;

    # Wrap these applications with firejail automatically
    wrappedBinaries = {
      # Brave browser - sandboxed
      # Limits file access, network isolation optional, GPU allowed
      brave = {
        executable = "${pkgs.brave}/bin/brave";
        profile = "${pkgs.firejail}/etc/firejail/brave.profile";
        extraArgs = [
          # Wayland support
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          # GPU acceleration (AMD)
          "--env=LIBVA_DRIVER_NAME"
          "--env=__GLX_VENDOR_LIBRARY_NAME"
          # Allow downloads to ~/Downloads only
          "--whitelist=~/Downloads"
          "--whitelist=~/Pictures"
        ];
      };
    };
  };

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
    # Allow hyprlock to unlock (Official Hyprland screen locker)
    hyprlock = {};

    # Fingerprint authentication (disabled - not available)
    # login.fprintAuth = true;
    # sudo.fprintAuth = true;
  };

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

  # Sudo rule for TLP battery threshold commands (passwordless)
  security.sudo.extraRules = [
    {
      users = [ "marcelo" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/tlp";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # USB Guard for USB device authorization (optional, can be strict)
  # services.usbguard.enable = true;
}
