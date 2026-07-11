# Auto-switch default microphone on headset jack plug/unplug.
# Jack plugged  -> Mic2 (Stereo Microphone, headset jack)
# Jack unplugged -> Mic1 (Digital Microphone, internal)
# Event-driven via `pactl subscribe`; only acts on plug/unplug transitions,
# so a manual choice (waybar mic-switch.sh) is respected until the next event.
{ pkgs, ... }:

let
  micJackAutoswitch = pkgs.writeShellScript "mic-jack-autoswitch" ''
    PACTL=${pkgs.pulseaudio}/bin/pactl
    GREP=${pkgs.gnugrep}/bin/grep
    AWK=${pkgs.gawk}/bin/awk

    # Wait for pipewire-pulse to be up
    until "$PACTL" info >/dev/null 2>&1; do
      ${pkgs.coreutils}/bin/sleep 1
    done

    # "in" when the Mic2 jack port exists and is not "not available"
    jack_state() {
      local port_line
      port_line=$("$PACTL" list sources | "$GREP" -F '[In] Mic2:')
      if [ -n "$port_line" ] && ! echo "$port_line" | "$GREP" -q 'not available'; then
        echo in
      else
        echo out
      fi
    }

    # apply <in|out> [notify]
    apply() {
      local target label
      if [ "$1" = "in" ]; then
        target=$("$PACTL" list sources short | "$AWK" '/Mic2/ {print $2; exit}')
        label="Jack mic (headset)"
      else
        target=$("$PACTL" list sources short | "$AWK" '/Mic1/ {print $2; exit}')
        label="Internal mic"
      fi
      [ -n "$target" ] || return 0
      "$PACTL" set-default-source "$target"
      if [ "$2" = "notify" ]; then
        ${pkgs.libnotify}/bin/notify-send "Microphone" "$label" -i audio-input-microphone
      fi
    }

    last=$(jack_state)
    apply "$last"   # initial sync at login, silent

    "$PACTL" subscribe | "$GREP" --line-buffered -E "'change' on (card|source)" | while read -r _; do
      ${pkgs.coreutils}/bin/sleep 0.2   # let port availability settle
      cur=$(jack_state)
      if [ "$cur" != "$last" ]; then
        last=$cur
        apply "$cur" notify
      fi
    done
  '';

in
{
  systemd.user.services.mic-jack-autoswitch = {
    Unit = {
      Description = "Switch default microphone on headset jack plug/unplug";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${micJackAutoswitch}";
      # "always": pactl subscribe exits 0 when pipewire-pulse restarts
      # (e.g. audio-restart), and on-failure would leave the service dead.
      Restart = "always";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
