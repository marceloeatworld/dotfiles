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

      # Wrangler (Cloudflare Workers CLI) - sandboxed
      # Needs network access and project directories only
      wrangler = {
        executable = "${pkgs.wrangler}/bin/wrangler";
        profile = "${pkgs.firejail}/etc/firejail/default.profile";
        extraArgs = [
          # Network access required for Cloudflare API
          "--net"
          # Allow access to common project directories
          "--whitelist=~/Projects"
          "--whitelist=~/dev"
          "--whitelist=~/code"
          "--whitelist=~/work"
          # Allow current directory (for running in project folders)
          "--private-cwd"
          # Node.js config
          "--whitelist=~/.npm"
          "--whitelist=~/.wrangler"
          "--whitelist=~/.config/wrangler"
          # Disable unnecessary features
          "--no-sound"
          "--no-video"
        ];
      };

      # Spotify - sandboxed (Electron app with telemetry)
      spotify = {
        executable = "${pkgs.spotify}/bin/spotify";
        profile = "${pkgs.firejail}/etc/firejail/spotify.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/.config/spotify"
          "--whitelist=~/.cache/spotify"
          "--whitelist=~/Music"
        ];
      };

      # VLC - sandboxed (media player, external files)
      vlc = {
        executable = "${pkgs.vlc}/bin/vlc";
        profile = "${pkgs.firejail}/etc/firejail/vlc.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/Videos"
          "--whitelist=~/Music"
          "--whitelist=~/Downloads"
        ];
      };

      # Transmission - sandboxed (P2P torrent client)
      transmission-gtk = {
        executable = "${pkgs.transmission_4-gtk}/bin/transmission-gtk";
        profile = "${pkgs.firejail}/etc/firejail/transmission-gtk.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/transmission"
        ];
      };

      # LibreOffice - sandboxed (external documents)
      libreoffice = {
        executable = "${pkgs.libreoffice-fresh}/bin/libreoffice";
        profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--env=SAL_USE_VCLPLUGIN"
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/Templates"
        ];
      };

      # GIMP - sandboxed (external images)
      gimp = {
        executable = "${pkgs.gimp3}/bin/gimp-3.0";
        profile = "${pkgs.firejail}/etc/firejail/gimp.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/Pictures"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/GIMP"
        ];
      };

      # Inkscape - sandboxed (external vector files)
      inkscape = {
        executable = "${pkgs.inkscape}/bin/inkscape";
        profile = "${pkgs.firejail}/etc/firejail/inkscape.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/Pictures"
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/inkscape"
        ];
      };

      # KeePassXC - sandboxed (sensitive password database)
      keepassxc = {
        executable = "${pkgs.keepassxc}/bin/keepassxc";
        profile = "${pkgs.firejail}/etc/firejail/keepassxc.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          # Very restrictive - only config and Documents for .kdbx files
          "--whitelist=~/.config/keepassxc"
          "--whitelist=~/Documents"
          "--no-sound"
          "--no-video"
        ];
      };

      # Zathura - sandboxed (PDF viewer, potential attack vector)
      zathura = {
        executable = "${pkgs.zathura}/bin/zathura";
        profile = "${pkgs.firejail}/etc/firejail/zathura.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/zathura"
          "--whitelist=~/.local/share/zathura"
          "--no-sound"
        ];
      };

      # mpv - sandboxed (media player)
      mpv = {
        executable = "${pkgs.mpv}/bin/mpv";
        profile = "${pkgs.firejail}/etc/firejail/mpv.profile";
        extraArgs = [
          "--env=WAYLAND_DISPLAY"
          "--env=XDG_RUNTIME_DIR"
          "--whitelist=~/Videos"
          "--whitelist=~/Music"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/mpv"
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
