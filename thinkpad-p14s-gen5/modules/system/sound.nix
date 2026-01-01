# Sound configuration
{ pkgs, ... }:

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
  };

  # Disable PulseAudio (PipeWire replaces it)
  # NixOS 25.05: hardware.pulseaudio renamed to services.pulseaudio
  services.pulseaudio.enable = false;

  # Audio tools
  environment.systemPackages = with pkgs; [
    hyprpwcenter  # Official Hyprland PipeWire control center (GUI)
    pamixer       # CLI volume control (used by scripts)
    playerctl     # Media player control (play/pause/next)
    alsa-utils    # For amixer, alsamixer - needed for speaker override
  ];

  # Enable real-time priority for audio processes
  security.rtkit.enable = true;
}
