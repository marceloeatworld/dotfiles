# Security configuration
{ pkgs, ... }:

let
  # Brave with Wayland flags (must match browsers.nix)
  brave-wayland = pkgs.brave.override {
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--ozone-platform-hint=wayland"
      "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,WaylandWindowDecorations"
      "--disable-features=WaylandWpColorManagerV1,AsyncDns"
      "--dns-over-https-mode=off"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--enable-smooth-scrolling"
    ];
  };
in
{
  # === FIREJAIL SANDBOXING ===
  # Isolates applications to limit their access to the system
  # When enabled, running "brave" actually runs "firejail brave"
  programs.firejail = {
    enable = true;

    # Wrap these applications with firejail automatically
    wrappedBinaries = {
      # Brave browser - sandboxed with Wayland flags
      # Limits file access, network isolation optional, GPU allowed
      brave = {
        executable = "${brave-wayland}/bin/brave";
        profile = "${pkgs.firejail}/etc/firejail/brave.profile";
        extraArgs = [
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
          "--whitelist=~/.config/spotify"
          "--whitelist=~/.cache/spotify"
          "--whitelist=~/Music"
        ];
      };

      # VLC - sandboxed (media player)
      vlc = {
        executable = "${pkgs.vlc}/bin/vlc";
        profile = "${pkgs.firejail}/etc/firejail/vlc.profile";
        extraArgs = [
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
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/transmission"
        ];
      };

      # LibreOffice - sandboxed (external documents)
      libreoffice = {
        executable = "${pkgs.libreoffice-fresh}/bin/libreoffice";
        profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
        extraArgs = [
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
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/zathura"
          "--whitelist=~/.local/share/zathura"
          "--no-sound"
        ];
      };


      # Blender - sandboxed (3D modelling, external files)
      blender = {
        executable = "${pkgs.blender}/bin/blender";
        profile = "${pkgs.firejail}/etc/firejail/blender.profile";
        extraArgs = [
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/Pictures"
          "--whitelist=~/Videos"
          "--whitelist=~/.config/blender"
        ];
      };

      # OBS Studio - sandboxed (screen recording)
      obs = {
        executable = "${pkgs.obs-studio}/bin/obs";
        profile = "${pkgs.firejail}/etc/firejail/obs.profile";
        extraArgs = [
          "--whitelist=~/Videos"
          "--whitelist=~/.config/obs-studio"
        ];
      };

      # MuseScore - sandboxed (music notation)
      musescore = {
        executable = "${pkgs.musescore}/bin/mscore";
        profile = "${pkgs.firejail}/etc/firejail/musescore.profile";
        extraArgs = [
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/Music"
          "--whitelist=~/.local/share/MuseScore"
          "--whitelist=~/.config/MuseScore"
        ];
      };

      # Audacity - sandboxed (audio editor)
      audacity = {
        executable = "${pkgs.audacity}/bin/audacity";
        profile = "${pkgs.firejail}/etc/firejail/audacity.profile";
        extraArgs = [
          "--whitelist=~/Music"
          "--whitelist=~/Downloads"
          "--whitelist=~/Documents"
          "--whitelist=~/.config/audacity"
          "--whitelist=~/.audacity-data"
        ];
      };

      # Xournalpp - sandboxed (PDF annotation, external documents)
      xournalpp = {
        executable = "${pkgs.xournalpp}/bin/xournalpp";
        profile = "${pkgs.firejail}/etc/firejail/xournalpp.profile";
        extraArgs = [
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/xournalpp"
          "--whitelist=~/.local/share/xournalpp"
        ];
      };

      # Joplin - sandboxed (Electron note-taking app)
      joplin-desktop = {
        executable = "${pkgs.joplin-desktop}/bin/joplin-desktop";
        profile = "${pkgs.firejail}/etc/firejail/default.profile";
        extraArgs = [
          "--whitelist=~/.config/joplin-desktop"
          "--whitelist=~/.config/Joplin"
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
        ];
      };

      # Wireshark - sandboxed (network analyzer)
      wireshark = {
        executable = "${pkgs.wireshark}/bin/wireshark";
        profile = "${pkgs.firejail}/etc/firejail/wireshark.profile";
        extraArgs = [
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/wireshark"
          "--no-sound"
        ];
      };

      # Zeal - sandboxed (offline documentation browser)
      zeal = {
        executable = "${pkgs.zeal}/bin/zeal";
        profile = "${pkgs.firejail}/etc/firejail/zeal.profile";
        extraArgs = [
          "--whitelist=~/.config/Zeal"
          "--whitelist=~/.local/share/Zeal"
          "--no-sound"
        ];
      };

      # Ghidra - sandboxed (reverse engineering, external binaries)
      ghidra = {
        executable = "${pkgs.ghidra}/bin/ghidra";
        profile = "${pkgs.firejail}/etc/firejail/default.profile";
        extraArgs = [
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/.ghidra"
          "--no-sound"
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
