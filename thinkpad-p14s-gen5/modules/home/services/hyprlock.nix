# Hyprlock configuration (Official Hyprland screen locker)
# Replaces swaylock - uses hyprtoolkit theme
{ config, ... }:

let
  theme = config.theme;
in
{
  # DISABLED - swaylock replaced by hyprlock
  programs.swaylock.enable = false;

  # DISABLED - swayidle replaced by hypridle
  services.swayidle.enable = false;

  # Hypridle configuration (Official Hyprland idle daemon)
  xdg.configFile."hypr/hypridle.conf".text = ''
    # Hypridle Configuration

    general {
      lock_cmd = pidof hyprlock || hyprlock
      before_sleep_cmd = loginctl lock-session
      after_sleep_cmd = hyprctl dispatch dpms on
    }

    # Screen dim after 2.5 minutes
    listener {
      timeout = 150
      on-timeout = brightnessctl -s set 10
      on-resume = brightnessctl -r
    }

    # Lock screen after 5 minutes
    listener {
      timeout = 300
      on-timeout = loginctl lock-session
    }

    # Turn off screen after 5.5 minutes
    listener {
      timeout = 330
      on-timeout = hyprctl dispatch dpms off
      on-resume = hyprctl dispatch dpms on
    }

    # Suspend after 15 minutes
    listener {
      timeout = 900
      on-timeout = systemctl suspend
    }
  '';

  # Hyprlock configuration - Ultra minimal
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Hyprlock - Minimal

    general {
      disable_loading_bar = true
      hide_cursor = true
      grace = 0
      no_fade_in = true
      no_fade_out = true
    }

    background {
      monitor =
      color = rgba(10, 10, 10, 1.0)
    }

    # Clock only
    label {
      monitor =
      text = $TIME
      color = rgba(200, 200, 200, 1.0)
      font_size = 72
      font_family = ${theme.fonts.mono}
      position = 0, 100
      halign = center
      valign = center
    }

    # Password input - minimal
    input-field {
      monitor =
      size = 250, 40
      outline_thickness = 1
      dots_size = 0.25
      dots_spacing = 0.2
      dots_center = true
      outer_color = rgba(51, 51, 51, 1)
      inner_color = rgba(26, 26, 26, 1)
      font_color = rgba(200, 200, 200, 1)
      fade_on_empty = false
      placeholder_text =
      hide_input = false
      rounding = 0
      check_color = rgba(200, 200, 200, 1)
      fail_color = rgba(200, 200, 200, 1)
      fail_text = $FAIL
      capslock_color = rgba(184, 160, 112, 1)
      position = 0, -50
      halign = center
      valign = center
    }
  '';
}
