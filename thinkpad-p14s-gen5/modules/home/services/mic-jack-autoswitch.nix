# Auto-switch audio devices on jack plug/unplug.
# Microphone: jack plugged -> Mic2 (headset), unplugged -> Mic1 (internal).
# Output: in auto mode (waybar audio-switch state), keep the analog card
# profile matched to the headphone jack. PipeWire split profiles make
# Headphones/Speaker separate card profiles, and WirePlumber persists any
# manually-set profile, which would otherwise block auto-switching after a
# manual override (forced speakers / HDMI).
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

    # Analog card (ALC257) and its split profiles
    CARD="alsa_card.pci-0000_c4_00.6"
    HEADPHONES_PROFILE="HiFi (Headphones, Mic1, Mic2)"
    SPEAKER_PROFILE="HiFi (Mic1, Mic2, Speaker)"

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

    # "in" when the Headphones output port is available (headphone jack plugged).
    # Tracked separately from the mic jack: TRS headphones have no mic.
    hp_state() {
      local port_line
      port_line=$("$PACTL" list cards | "$GREP" -F '[Out] Headphones:')
      if [ -n "$port_line" ] && ! echo "$port_line" | "$GREP" -q 'not available'; then
        echo in
      else
        echo out
      fi
    }

    # sync_output_profile <in|out>: only in auto mode, match profile to jack
    sync_output_profile() {
      local state
      state=$(${pkgs.coreutils}/bin/cat "$HOME/.config/audio-output-state" 2>/dev/null)
      [ "''${state:-auto}" = "auto" ] || return 0
      if [ "$1" = "in" ]; then
        "$PACTL" set-card-profile "$CARD" "$HEADPHONES_PROFILE"
      else
        "$PACTL" set-card-profile "$CARD" "$SPEAKER_PROFILE"
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
    last_hp=$(hp_state)
    apply "$last"                    # initial sync at login, silent
    sync_output_profile "$last_hp"   # also heals a stale profile preference

    "$PACTL" subscribe | "$GREP" --line-buffered -E "'change' on (card|source)" | while read -r _; do
      ${pkgs.coreutils}/bin/sleep 0.2   # let port availability settle
      cur=$(jack_state)
      if [ "$cur" != "$last" ]; then
        last=$cur
        apply "$cur" notify
      fi
      cur_hp=$(hp_state)
      if [ "$cur_hp" != "$last_hp" ]; then
        last_hp=$cur_hp
        sync_output_profile "$cur_hp"
      fi
    done
  '';

in
{
  systemd.user.services.mic-jack-autoswitch = {
    Unit = {
      Description = "Switch default microphone and output profile on jack plug/unplug";
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
