# Security configuration
{ pkgs, lib, ... }:

let
  # Brave Wayland/VA-API flags, passed as CLI args by the wrappers below.
  # pkgs.brave lost .override { commandLineArgs = ...; } when nixpkgs
  # restructured it into make-brave.nix (the exported attr is a plain
  # derivation now), so the flags moved from an override to wrapper argv.
  # The nixpkgs brave wrapper prepends its own --enable/--disable-features;
  # Chromium only honors the LAST occurrence, so these two lists are the
  # effective ones and must carry everything we want.
  # AcceleratedVideoDecodeLinuxGL = VA-API hardware video decode (radeonsi,
  # LIBVA_DRIVER_NAME in amd-optimizations.nix). Without it YouTube/Twitch
  # PiP decodes VP9/AV1 on the CPU; the 780M decodes both in hardware.
  brave-flags = lib.escapeShellArgs [
    "--ozone-platform=wayland"
    "--ozone-platform-hint=wayland"
    "--enable-features=TouchpadOverscrollHistoryNavigation,UseOzonePlatform,WaylandWindowDecorations,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
    "--disable-features=WaylandWpColorManagerV1,AsyncDns,OutdatedBuildDetector,UseChromeOSDirectVideoDecoder"
    "--dns-over-https-mode=off"
    "--enable-gpu-rasterization"
    "--enable-zero-copy"
    "--enable-smooth-scrolling"
  ];

  # Daily Brave profile: firejail's brave profile (seccomp, caps, private-dev,
  # no ptrace, no suid) with the home whitelist disabled so uploads and the
  # Claude Code browser extension's native host (~/.claude/chrome) work from
  # anywhere in ~. Whitelisting also hid ~/.config/theme, so the GTK and
  # Kvantum config links dangled inside the sandbox and Brave rendered text
  # selections with Kvantum's fallback palette (invisible on dark pages).
  # Credentials stay hidden: disable-common.inc blacklists ~/.ssh, ~/.aws and
  # ~/.netrc; the sops age key, the decrypted sops-nix secrets (symlink in
  # ~/.config plus the tmpfs target under /run/user) and the wallet zpub file
  # are added here. `ignore` must precede the include.
  # Hardware/WebUSB access is split into the explicit brave-hw command below.
  brave-profile = pkgs.writeText "brave-strict.profile" ''
    ignore whitelist
    include ${pkgs.firejail}/etc/firejail/brave.profile

    blacklist ''${HOME}/.config/sops
    blacklist ''${HOME}/.config/sops-nix
    blacklist ''${RUNUSER}/secrets.d
    blacklist ''${HOME}/.config/waybar/.env
    # Agent and GitHub OAuth tokens (not covered by disable-*.inc). File-level
    # for ~/.claude so the Chrome native host in ~/.claude/chrome keeps working.
    blacklist ''${HOME}/.claude/.credentials.json
    blacklist ''${HOME}/.codex
    blacklist ''${HOME}/.local/share/opencode
    blacklist ''${HOME}/.config/gh
  '';

  # The other sandboxed GUI apps keep their home whitelists, so they need
  # ~/.config/theme explicitly: their GTK settings.ini, gtk.css imports and
  # Kvantum config are symlinks into it (runtime-theme.nix) and dangle
  # otherwise, leaving them on the default GTK/Kvantum look.
  themeWhitelist = "--whitelist=~/.config/theme";

  # Spotify streams into ~/.cache/spotify (2.5 GB found on 2026-09-06). Drop
  # the stream cache once the client exits. Users/ keeps login and settings.
  # Runs inside the jail; ~/.cache/spotify is whitelisted read-write there.
  # Vesktop (Vencord Discord client). Same shape as the Brave wrapper below:
  # upstream vesktop.profile has "join-or-start vesktop", and firejail rejects
  # every CLI option (--profile, --whitelist, --apparmor) when joining, so a
  # wrappedBinaries entry broke any second launch (tray click, discord:// URL)
  # with "invalid option ... after --join". All hardening lives in the profile.
  # --no-sandbox: Chromium's own zygote sandbox cannot be created inside a
  # firejail jail (no new privileges, seccomp) and Electron aborts with
  # "zygote_host_impl_linux.cc: Check failed"; firejail plus AppArmor confine
  # it instead, as for every other firejail Electron profile.
  vesktop-profile = pkgs.writeText "vesktop-jail.profile" ''
    include ${pkgs.firejail}/etc/firejail/vesktop.profile

    whitelist ''${HOME}/.config/theme
    whitelist ''${HOME}/.config/vesktop
    whitelist ''${HOME}/.cache/vesktop
    caps.drop all
    nonewprivs
    noroot
    seccomp
    private-dev
    private-tmp
    dbus-user.talk org.freedesktop.Notifications
    dbus-user.talk org.kde.StatusNotifierWatcher
    dbus-user.talk org.freedesktop.portal.Desktop
    apparmor
  '';
  # Links clicked in Vesktop go through xdg-open inside the jail, which
  # resolves brave-browser.desktop to the Brave wrapper below. That wrapper
  # cannot run there (systemd-run is denied, firejail refuses to nest), so
  # every link silently died. This shim hands the URL to the host through
  # the desktop portal (OpenURI), which the profile already allows, and the
  # host side launches the real default browser. Electron finds xdg-open
  # via PATH, so the wrapper simply puts this directory first.
  vesktop-xdg-open = pkgs.writeShellScriptBin "xdg-open" ''
    exec ${pkgs.glib.bin}/bin/gdbus call --session \
      --dest org.freedesktop.portal.Desktop \
      --object-path /org/freedesktop/portal/desktop \
      --method org.freedesktop.portal.OpenURI.OpenURI "" "$1" "{}" >/dev/null
  '';
  vesktop-wrapper = pkgs.writeShellScriptBin "vesktop" ''
    FIREJAIL=/run/wrappers/bin/firejail
    VESKTOP=${pkgs.vesktop}/bin/vesktop
    export PATH=${vesktop-xdg-open}/bin:$PATH
    if "$FIREJAIL" --list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q ":vesktop:"; then
      exec "$FIREJAIL" --join=vesktop "$VESKTOP" --no-sandbox "$@"
    else
      exec "$FIREJAIL" --name=vesktop --profile=${vesktop-profile} "$VESKTOP" --no-sandbox "$@"
    fi
  '';

  spotify-clean-exit = pkgs.writeShellScriptBin "spotify-clean-exit" ''
    ${pkgs.spotify}/bin/spotify "$@"
    rc=$?
    ${pkgs.coreutils}/bin/rm -rf "$HOME/.cache/spotify/Data" "$HOME/.cache/spotify/Storage"
    exit $rc
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
    BRAVE=${pkgs.brave}/bin/brave
    SYSTEMD_RUN="${pkgs.systemd}/bin/systemd-run --user --quiet --scope --slice=app-brave.slice"

    # Check if a sandbox named "brave" is already running.
    # firejail --list format: PID:USER:NAME:COMMAND
    if "$FIREJAIL" --list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q ":brave:"; then
      # Join existing sandbox - no profile/whitelist args allowed here
      # systemd-run --scope places this invocation under app-brave.slice (memory-capped)
      exec $SYSTEMD_RUN "$FIREJAIL" --join=brave "$BRAVE" ${brave-flags} "$@"
    else
      # Create new sandbox with full profile (whitelists, ignores, etc.)
      exec $SYSTEMD_RUN "$FIREJAIL" --name=brave --apparmor --profile=${brave-profile} "$BRAVE" ${brave-flags} "$@"
    fi
  '';

  brave-hw-wrapper = pkgs.writeShellScriptBin "brave-hw" ''
    BRAVE=${pkgs.brave}/bin/brave
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
      ${brave-flags} \
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
    # Every wrapper also confines with the generic firejail-default AppArmor
    # profile (loaded by security.apparmor below): a second, kernel-side layer
    # that blocks ptrace, raw mounts and most capabilities without any
    # per-application rules to maintain.
    wrappedBinaries = lib.mapAttrs (_: w: w // { extraArgs = [ "--apparmor" ] ++ w.extraArgs; }) {
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

      # NOTE: vesktop is NOT listed here either, see vesktop-wrapper above.

      # Spotify - sandboxed (Electron app with telemetry)
      spotify = {
        executable = "${spotify-clean-exit}/bin/spotify-clean-exit";
        profile = "${pkgs.firejail}/etc/firejail/spotify.profile";
        extraArgs = [
          themeWhitelist
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
          themeWhitelist
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
          themeWhitelist
          "--whitelist=~/Downloads"
          "--whitelist=~/.config/transmission"
        ];
      };

      # LibreOffice - sandboxed (external documents)
      libreoffice = {
        executable = "${pkgs.libreoffice-stable}/bin/libreoffice";
        profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
        extraArgs = [
          themeWhitelist
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          "--whitelist=~/Templates"
        ];
      };

      # GIMP - sandboxed (external images)
      gimp = {
        executable = "${pkgs.gimp3}/bin/gimp";
        profile = "${pkgs.firejail}/etc/firejail/gimp.profile";
        extraArgs = [
          themeWhitelist
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
          themeWhitelist
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
          themeWhitelist
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
          themeWhitelist
          "--whitelist=~/Documents"
          "--whitelist=~/Downloads"
          # A PDF anywhere else was invisible inside the jail (empty window).
          # Project trees, pictures and removable disks are visible read-only.
          # Desktop and PDFs dropped at the top of $HOME are common too.
          "--whitelist=~/Desktop"
          "--whitelist=~/*.pdf"
          "--whitelist=~/codes"
          "--read-only=~/codes"
          "--whitelist=~/Pictures"
          "--read-only=~/Pictures"
          "--whitelist=/run/media/marcelo"
          "--read-only=/run/media/marcelo"
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
          themeWhitelist
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
          themeWhitelist
          "--whitelist=~/Videos"
          "--whitelist=~/.config/obs-studio"
        ];
      };

      # Xournalpp - sandboxed (PDF annotation, external documents)
      xournalpp = {
        executable = "${pkgs.xournalpp}/bin/xournalpp";
        profile = "${pkgs.firejail}/etc/firejail/xournalpp.profile";
        extraArgs = [
          themeWhitelist
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
          themeWhitelist
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
          themeWhitelist
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
          themeWhitelist
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

  # scdaemon: go through pcscd (smartcard.nix) instead of probing USB readers
  # with the built-in CCID driver, which logged "ccid open error: skip" on
  # every SSH connection. Read from /etc/gnupg like gpg-agent.conf above.
  environment.etc."gnupg/scdaemon.conf".text = ''
    disable-ccid
  '';

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

  # AppArmor. Enabling it alone loads no policy (the service ran a teardown
  # and nothing else). Load firejail's generic profile so every firejail
  # sandbox above gets kernel-side confinement; the firejail package is added
  # to the include path for its local/firejail-default stub.
  security.apparmor = {
    enable = true;
    packages = [ pkgs.firejail ];
    # Upstream firejail-default only allows exec from FHS paths (/bin, /lib,
    # /opt...). On NixOS every program lives in /nix/store, so the second exec
    # inside a jail (bin/brave -> brave-browser, spotify-clean-exit -> spotify,
    # any makeWrapper script) was denied with "Permission denied". Allow the
    # store; ptrace, mount, capability and sensitive-path rules still apply.
    policies.firejail-default = {
      state = "enforce";
      path = pkgs.runCommand "firejail-default-apparmor" { } ''
        ${pkgs.gnused}/bin/sed \
          's|^#/{,run/firejail/mnt/oroot/}home/\*\* ix,$|/{,run/firejail/mnt/oroot/}nix/store/** ix,|' \
          ${pkgs.firejail}/etc/apparmor.d/firejail-default > $out
        ${pkgs.gnugrep}/bin/grep -q 'nix/store/\*\* ix,' $out
      '';
    };
    # Brave (in firejail-default) must start the Claude in Chrome extension's
    # native messaging host, a wrapper script Claude Code writes under
    # ~/.claude/chrome; AppArmor denied that exec after the first rebuild.
    includes."local/firejail-default" = ''
      owner @{HOME}/.claude/chrome/chrome-native-host ix,
    '';
  };

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
    vesktop-wrapper
    pkgs.libsecret # secret-tool for debugging GNOME Keyring/libsecret
  ];
}
