# Security configuration
{ pkgs, ... }:

let
  # Brave with Wayland flags (used by Firejail wrapper below)
  brave-wayland = pkgs.brave.override {
    commandLineArgs = [
      "--ozone-platform=wayland"
      "--ozone-platform-hint=wayland"
      # The nixpkgs brave wrapper prepends its own --enable/--disable-features;
      # Chromium only honors the LAST occurrence, so these two lists are the
      # effective ones and must carry everything we want.
      # AcceleratedVideoDecodeLinuxGL = VA-API hardware video decode (radeonsi,
      # LIBVA_DRIVER_NAME in amd-optimizations.nix). Without it YouTube/Twitch
      # PiP decodes VP9/AV1 on the CPU; the 780M decodes both in hardware.
      "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL"
      "--disable-features=WaylandWpColorManagerV1,AsyncDns,OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
      "--dns-over-https-mode=off"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--enable-smooth-scrolling"
    ];
  };

  # Daily Brave profile: keep the normal Firejail browser profile strict.
  # Hardware/WebUSB access is split into the explicit brave-hw command below.
  brave-profile = pkgs.writeText "brave-strict.profile" ''
    # Extend firejail's default brave profile
    include ${pkgs.firejail}/etc/firejail/brave.profile

    # Keep common browser upload/download locations available without exposing
    # the full home.
    whitelist ''${HOME}/Downloads
    whitelist ''${HOME}/Documents
    whitelist ''${HOME}/Pictures
    whitelist ''${HOME}/Videos
    whitelist ''${HOME}/Music
  '';

  # Custom Brave wrapper: we can't use programs.firejail.wrappedBinaries
  # because it ALWAYS passes --profile= as a CLI arg, and firejail rejects
  # ANY option (--profile, --whitelist, etc.) when joining an existing
  # sandbox via --join / --join-or-start. That broke Super+Y (YouTube PiP)
  # and every brave webapp launch when brave was already running.
  #
  # This wrapper instead checks if the "brave" sandbox already exists:
  #   - exists  → firejail --join=brave <brave> "$@"   (no profile args)
  #   - absent  → firejail --name=brave --profile=... <brave> "$@"
  brave-wrapper = pkgs.writeShellScriptBin "brave" ''
    FIREJAIL=/run/wrappers/bin/firejail
    BRAVE=${brave-wayland}/bin/brave
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run --user --quiet --scope --slice=app-brave.slice"

    # Check if a sandbox named "brave" is already running.
    # firejail --list format: PID:USER:NAME:COMMAND
    if "$FIREJAIL" --list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q ":brave:"; then
      # Join existing sandbox - no profile/whitelist args allowed here
      # systemd-run --scope places this invocation under app-brave.slice (memory-capped)
      exec $SYSTEMD_RUN "$FIREJAIL" --join=brave "$BRAVE" "$@"
    else
      # Create new sandbox with full profile (whitelists, ignores, etc.)
      exec $SYSTEMD_RUN "$FIREJAIL" --name=brave --profile=${brave-profile} "$BRAVE" "$@"
    fi
  '';

  brave-hw-wrapper = pkgs.writeShellScriptBin "brave-hw" ''
    BRAVE=${brave-wayland}/bin/brave
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run --user --quiet --scope --slice=app-brave.slice"
    USER_DATA_DIR="$HOME/.config/brave-hw"

    ${pkgs.coreutils}/bin/mkdir -p "$USER_DATA_DIR"

    # Hardware/WebSerial flows are intentionally outside Firejail. Firejail's
    # chromium profile can make WebSerial/WebUSB unreliable, and Chromium may
    # hand URLs to the already-running daily Brave instance instead of keeping
    # the hardware profile alive. The separate user-data-dir keeps this browser
    # identity away from routine browsing while allowing device and file access.
    exec $SYSTEMD_RUN "$BRAVE" \
      --user-data-dir="$USER_DATA_DIR" \
      --no-first-run \
      --no-default-browser-check \
      --new-window \
      "$@"
  '';
in
{
  # === FIREJAIL SANDBOXING ===
  # Isolates applications to limit their access to the system
  # When enabled, running "brave" actually runs "firejail brave"
  programs.firejail = {
    enable = true;

    # Wrap these applications with firejail automatically
    # NOTE: brave is NOT listed here - it uses the custom brave-wrapper
    # script below (in environment.systemPackages) because wrappedBinaries
    # can't conditionally decide between --join and --profile args.
    wrappedBinaries = {
      # Google Cloud SDK - sandboxed (cloud CLI with credentials)
      # Uses noprofile to avoid default.profile blacklists conflicting with whitelists
      gcloud = {
        executable = "${pkgs.google-cloud-sdk}/bin/gcloud";
        extraArgs = [
          "--noprofile"
          "--whitelist=~/.config/gcloud"
          "--whitelist=~/codes"
          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--nosound"
          "--novideo"
          "--seccomp"
          "--private-dev"
          "--private-tmp"
          "--protocol=unix,inet,inet6"
        ];
      };

      # Vesktop (Vencord) - sandboxed Discord client
      # vesktop.profile is minimal (private-bin only), so add hardening
      vesktop = {
        executable = "${pkgs.vesktop}/bin/vesktop";
        profile = "${pkgs.firejail}/etc/firejail/vesktop.profile";
        extraArgs = [
          "--whitelist=~/.config/vesktop"
          "--whitelist=~/.cache/vesktop"
          "--caps.drop=all"
          "--nonewprivs"
          "--noroot"
          "--seccomp"
          "--private-dev"
          "--private-tmp"
          "--dbus-user.talk=org.freedesktop.Notifications"
          "--dbus-user.talk=org.kde.StatusNotifierWatcher"
          "--dbus-user.talk=org.freedesktop.portal.Desktop"
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
          "--nosound"
          "--novideo"
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
          "--nosound"
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
          "--nosound"
        ];
      };

      # Ghidra - sandboxed (reverse engineering, external binaries)
      # No network needed for local RE analysis
      ghidra = {
        executable = "${pkgs.ghidra}/bin/ghidra";
        profile = "${pkgs.firejail}/etc/firejail/default.profile";
        extraArgs = [
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/.ghidra"
          "--nosound"
          "--net=none"
        ];
      };
    };
  };

  # Enable GnuPG agent
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Secret Service provider for VS Code/Electron credential storage under
  # Hyprland. This avoids VS Code falling back to weaker local encryption.
  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;

  # Fingerprint reader support (disabled - not available on this model)
  # services.fprintd = {
  #   enable = true;
  # };

  # PAM configuration
  security.pam.services = {
    # Unlock/start the GNOME Keyring from the TTY login session.
    login.enableGnomeKeyring = true;
    passwd.enableGnomeKeyring = true;

    # Allow hyprlock to unlock (Official Hyprland screen locker)
    hyprlock = { };

    # Fingerprint authentication (disabled - not available)
    # login.fprintAuth = true;
    # sudo.fprintAuth = true;
  };

  # AppArmor for additional security (optional)
  security.apparmor.enable = true;

  # Polkit rules for TLP battery threshold management
  security.polkit.adminIdentities = [ "unix-user:marcelo" ];

  # Allow the fwupd-refresh timer to update LVFS metadata non-interactively.
  # nixpkgs' fwupd module no longer ships this rule, and fwupd 2.1.x renamed the
  # action to "refresh-remote" (defaults to auth_admin for non-session users).
  # Without this, fwupd-refresh.service fails with "Failed to obtain auth", which
  # also makes every nixos-rebuild report an activation failure.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.fwupd.refresh-remote" &&
          subject.user == "fwupd-refresh") {
        return polkit.Result.YES;
      }
    });
  '';

  # Sudo rule for TLP battery threshold commands only (passwordless)
  # Restricted to setcharge subcommand - prevents escalation via other tlp commands
  security.sudo.extraRules = [
    {
      users = [ "marcelo" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/tlp setcharge *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # USB Guard for USB device authorization (optional, can be strict)
  # services.usbguard.enable = true;

  # Custom brave wrapper (replaces firejail.wrappedBinaries.brave)
  # See brave-wrapper definition at the top of this file for rationale.
  environment.systemPackages = [
    brave-wrapper
    brave-hw-wrapper
    pkgs.libsecret # secret-tool for debugging GNOME Keyring/libsecret
  ];
}
