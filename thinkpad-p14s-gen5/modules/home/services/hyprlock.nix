# Hyprlock (screen locker) and hypridle (idle daemon) configuration.
{ config, lib, ... }:

let
  theme = config.theme;
  themeConfigs = import ../lib/theme-configs.nix { inherit lib; };
in
{
  # Hypridle configuration (Official Hyprland idle daemon)
  # References:
  #   - https://wiki.hypr.land/Hypr-Ecosystem/hypridle/
  #   - https://github.com/hyprwm/Hyprland/issues/7700 (hyprctl reload SEGV)
  #   - https://github.com/hyprwm/hyprlock/issues/953 (DPMS off crash on AMD)
  #   - https://github.com/hyprwm/Hyprland/issues/6082 (DPMS on crash)
  xdg.configFile."hypr/hypridle.conf".text = ''
    # Hypridle Configuration
    # NOTE: DPMS off is NOT used — known crash vector on AMD RDNA 3 iGPU
    # NOTE: hyprctl reload is NOT used — causes SEGV during resume (issue #7700)

    general {
      lock_cmd = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      # After resume: only turn DPMS on (official wiki recommendation)
      # Small delay gives GPU/DRM time to reinitialize after s2idle
      after_sleep_cmd = sleep 4 && hyprctl eval "hl.dispatch(hl.dsp.dpms({ action = 'on' }))"
    }

    # Screen dim after 25 minutes
    listener {
      timeout = 1500
      on-timeout = brightnessctl -s set 10
      on-resume = brightnessctl -r
    }

    # Lock screen after 30 minutes
    listener {
      timeout = 1800
      on-timeout = loginctl lock-session
    }

    # On battery: suspend after 45 minutes idle. Fullscreen/video windows can
    # still inhibit idle through the Hyprland window rules.
    listener {
      timeout = 2700
      on-timeout = sh -c '[ "$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)" = "Discharging" ] && systemctl suspend'
    }
  '';

  # Hyprlock configuration - Informative lock screen with cool info
  # Build-time fallback; theme-switch relinks ~/.config/hypr/hyprlock.conf to
  # the runtime theme's copy (runtime-theme.nix). Read by hyprlock at lock time.
  xdg.configFile."hypr/hyprlock.conf" = {
    force = true;
    text = themeConfigs.hyprlockConf theme;
  };
}
