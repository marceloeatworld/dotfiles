# Sound configuration
{ pkgs, ... }:

let
  # Script to restart PipeWire + WirePlumber and reset audio to working state
  audio-restart = pkgs.writeShellScriptBin "audio-restart" ''
    set -u

    echo "Restarting PipeWire and WirePlumber..."
    ${pkgs.systemd}/bin/systemctl --user restart pipewire wireplumber pipewire-pulse
    sleep 2

    # Set Ryzen HD Audio as default (not HDMI)
    # Match sink ID by looking for "Ryzen" in the sink name (resilient to WirePlumber output format changes)
    SINK=$(${pkgs.wireplumber}/bin/wpctl status 2>/dev/null | ${pkgs.gnugrep}/bin/grep -i "ryzen.*speaker" | ${pkgs.gnugrep}/bin/grep -oP '^\s*\K\d+' | head -1)
    if [ -n "''${SINK:-}" ]; then
      ${pkgs.wireplumber}/bin/wpctl set-default "$SINK"
      echo "Default sink set to Ryzen HD Audio (ID: $SINK)"
    else
      echo "Warning: Could not find Ryzen HD Audio sink, default unchanged"
    fi

    # Reset ALSA mixer to sane defaults: Auto-Mute enabled, speakers unmuted
    CARD=""
    for c in 0 1 2 3; do
      if ${pkgs.alsa-utils}/bin/amixer -c "$c" scontrols 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Speaker"; then
        CARD="$c"
        break
      fi
    done
    if [ -n "$CARD" ]; then
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Master" unmute 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Capture" "75%" cap 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Mic Boost" 1 2>/dev/null
      echo "ALSA mixer reset: Auto-Mute Enabled, speakers/mic unmuted"
    fi

    # Clear stale audio-switch state
    rm -f "$HOME/.config/audio-output-state"

    echo "Audio restarted."
    ${pkgs.wireplumber}/bin/wpctl status | ${pkgs.gnused}/bin/sed -n '/Audio/,/Video/p'
  '';

  # Script to initialize audio at session start
  audio-init = pkgs.writeShellScriptBin "audio-init" ''
    set -u

    # Wait for PipeWire/WirePlumber to be ready (poll up to 10s)
    for i in $(seq 1 10); do
      ${pkgs.wireplumber}/bin/wpctl status >/dev/null 2>&1 && break
      sleep 1
    done

    # Find the ALSA card with Speaker control
    CARD=""
    for c in 0 1 2 3; do
      if ${pkgs.alsa-utils}/bin/amixer -c "$c" scontrols 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "Speaker"; then
        CARD="$c"
        break
      fi
    done
    if [ -n "$CARD" ]; then
      # Enable Auto-Mute: jack plugged → headphones, jack unplugged → speakers
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Auto-Mute Mode" "Enabled" 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Speaker" unmute 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Master" unmute 2>/dev/null
      # Set capture (microphone) to usable level - fixes 0%/8% default
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Capture" "75%" cap 2>/dev/null
      ${pkgs.alsa-utils}/bin/amixer -c "$CARD" sset "Mic Boost" 1 2>/dev/null
    fi

    # Clear stale toggle state
    rm -f "$HOME/.config/audio-output-state"
  '';
in
{
  # PipeWire for audio (modern replacement for PulseAudio)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;

    # Low latency configuration
    extraConfig.pipewire = {
      "92-low-latency" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 1024;
          default.clock.min-quantum = 512;
          default.clock.max-quantum = 2048;
        };
      };
    };

    # WirePlumber configuration
    wireplumber.extraConfig = {
      # Prioritize Ryzen HD Audio (analog) over HDMI output
      # Priority capped at 1500 to avoid sink monitor being selected as default source
      "50-alsa-default" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.pci-0000_c4_00.6.*"; }
            ];
            actions = {
              update-props = {
                "priority.driver" = 1500;
                "priority.session" = 1500;
              };
            };
          }
          {
            matches = [
              { "node.name" = "~alsa_output.pci-0000_c4_00.1.*"; }
            ];
            actions = {
              update-props = {
                "priority.driver" = 100;
                "priority.session" = 100;
              };
            };
          }
        ];
      };

      # Disable suspend timeout to prevent audio pops on ALC257
      # WirePlumber suspends sinks after 5s of silence by default, causing
      # an audible pop when audio resumes and interfering with Auto-Mute state
      "51-disable-suspend" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "~alsa_output.*"; }
              { "node.name" = "~alsa_input.*"; }
            ];
            actions = {
              update-props = {
                "session.suspend-timeout-seconds" = 0;
              };
            };
          }
        ];
      };

      # Prevent Bluetooth auto-switch to HFP (low-quality headset profile)
      "52-bluetooth-policy" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };

      # Microphone priority: prefer analog/headset mic over internal when jack plugged
      # Internal digital mic is default; headset mic takes over on jack detection
      "53-mic-priority" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "node.name" = "alsa_input.pci-0000_c4_00.6.HiFi__Mic1__source"; }
            ];
            actions = {
              update-props = {
                "priority.driver" = 1900;
                "priority.session" = 1900;
              };
            };
          }
          {
            matches = [
              { "node.name" = "alsa_input.pci-0000_c4_00.6.HiFi__Mic2__source"; }
            ];
            actions = {
              update-props = {
                "priority.driver" = 2100;
                "priority.session" = 2100;
              };
            };
          }
        ];
      };

      # Default microphone volume for new/unrecognized sources (75%)
      "54-default-source-volume" = {
        "wireplumber.settings" = {
          "device.routes.default-source-volume" = 0.75;
        };
      };
    };
  };

  # Audio tools
  environment.systemPackages = with pkgs; [
    hyprpwcenter      # Official Hyprland PipeWire control center (GUI)
    pamixer           # CLI volume control (used by scripts)
    pulseaudio        # For pactl (PulseAudio CLI tools, used by some apps)
    playerctl         # Media player control (play/pause/next)
    alsa-utils        # For amixer, alsamixer - needed for speaker override
    audio-restart     # Restart PipeWire/WirePlumber when audio misbehaves
    audio-init        # Initialize audio at session start
  ];

  # Enable real-time priority for audio processes
  security.rtkit.enable = true;
}
