# Portuguese Cartao de Cidadao authentication (Autenticacao.Gov), sandboxed.
#
# The official "plugin" is not a browser extension: it is a closed-source
# local Java app serving a WebSocket on 127.0.0.1:35153 that the
# autenticacao.gov.pt pages connect to. It reaches the card reader through
# the pcscd daemon (modules/system/smartcard.nix), never through USB
# directly, so the jail only needs the pcscd socket.
#
# Because the binary is untrusted it runs in a bubblewrap jail (jail-nix):
# private tmpfs home, its own xwayland-satellite for the Java Swing PIN
# dialog (cannot see other X11 clients), pcscd socket read-only, network
# for the localhost WebSocket. `cc-gov` starts the jailed plugin together
# with a dedicated Brave profile window and kills it when Brave exits, so
# the localhost port is only exposed while that window is open.
{ inputs, pkgs, lib, ... }:

let
  jail = inputs.jail-nix.lib.init pkgs;

  # Unversioned upstream URL: when AMA ships a new build the hash breaks.
  # Fix with: nix-prefetch-url <url>, then nix hash convert --hash-algo sha256 --from nix32 <hash>
  pluginJar = pkgs.fetchurl {
    url = "https://aplicacoes.autenticacao.gov.pt/plugin/plugin-autenticacao-gov.jar";
    hash = "sha256-LIwCw4NRSChxCMMPVL1jqe8dR8EQ79iifZayGMbpYkQ=";
  };

  pluginBin = pkgs.writeShellScriptBin "plugin-autenticacao-gov" ''
    # Java Swing renders a gray window on non-reparenting WMs without this.
    export _JAVA_AWT_WM_NONREPARENTING=1
    # The jar extracts a bundled JNI lib (libPCSC4Java) to /tmp that links
    # against libpcsclite.so.1, so pcsclite must be on the linker path.
    export LD_LIBRARY_PATH=${lib.getLib pkgs.pcsclite}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    exec ${pkgs.jre}/bin/java -jar ${pluginJar}
  '';

  jailedPlugin = jail "jailed-autenticacao-gov" pluginBin (
    with jail.combinators;
    [
      network
      time-zone
      gui
      xwayland
      (readonly (noescape "/run/pcscd"))
    ]
  );

  # Same pattern as brave-hw (modules/system/security.nix): dedicated
  # user-data-dir outside the shared firejail "brave" sandbox, so the gov
  # session never joins or contaminates the daily browsing profile.
  # Usage: cc-gov [url]. Opens a regular window (address bar included) because
  # card logins start on third-party sites (e.g. digitarq.arquivos.pt) that
  # redirect to autenticacao.gov.pt, where the page talks to the plugin.
  ccGov = pkgs.writeShellScriptBin "cc-gov" ''
    ${jailedPlugin}/bin/jailed-autenticacao-gov &
    PLUGIN_PID=$!
    trap 'kill "$PLUGIN_PID" 2>/dev/null' EXIT

    ${pkgs.brave}/bin/brave \
      --user-data-dir="$HOME/.config/brave-gov" \
      --no-first-run \
      --no-default-browser-check \
      --new-window \
      --ozone-platform=wayland \
      --ozone-platform-hint=wayland \
      "''${1:-https://autenticacao.gov.pt/}"
  '';
in
{
  home.packages = [ jailedPlugin ccGov ];

  xdg.desktopEntries.cc-gov = {
    name = "Autenticacao.Gov";
    genericName = "Citizen Card Authentication";
    comment = "Cartao de Cidadao authentication (jailed plugin + dedicated Brave profile)";
    exec = "cc-gov";
    terminal = false;
    categories = [ "Network" ];
  };
}
