# Hyprlock configuration (Official Hyprland screen locker)
# Replaces swaylock - uses hyprtoolkit theme
{ pkgs, ... }:

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

  # Hyprlock configuration with Ristretto theme
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Hyprlock Configuration - Ristretto Theme

    general {
      disable_loading_bar = false
      hide_cursor = true
      grace = 0
      no_fade_in = false
      no_fade_out = false
    }

    background {
      monitor =
      path = screenshot
      blur_passes = 3
      blur_size = 8
      noise = 0.0117
      contrast = 0.8916
      brightness = 0.7
      vibrancy = 0.1696
      vibrancy_darkness = 0.0
    }

    # Clock
    label {
      monitor =
      text = $TIME
      color = rgba(230, 217, 219, 1.0)
      font_size = 90
      font_family = JetBrainsMono Nerd Font
      position = 0, 200
      halign = center
      valign = center
    }

    # Date
    label {
      monitor =
      text = cmd[update:3600000] date +"%A, %d %B %Y"
      color = rgba(230, 217, 219, 0.8)
      font_size = 24
      font_family = JetBrainsMono Nerd Font
      position = 0, 100
      halign = center
      valign = center
    }

    # User greeting (Ristretto yellow)
    label {
      monitor =
      text = Hi, $USER
      color = rgba(249, 204, 108, 1.0)
      font_size = 20
      font_family = JetBrainsMono Nerd Font
      position = 0, -50
      halign = center
      valign = center
    }

    # Password input
    input-field {
      monitor =
      size = 300, 50
      outline_thickness = 3
      dots_size = 0.33
      dots_spacing = 0.15
      dots_center = true
      dots_rounding = -1
      outer_color = rgba(64, 62, 65, 1)
      inner_color = rgba(44, 37, 37, 0.9)
      font_color = rgba(230, 217, 219, 1)
      fade_on_empty = false
      fade_timeout = 1000
      placeholder_text = <i>Password...</i>
      hide_input = false
      rounding = 8
      check_color = rgba(133, 218, 204, 1)
      fail_color = rgba(253, 104, 131, 1)
      fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
      fail_timeout = 2000
      fail_transition = 300
      capslock_color = rgba(249, 204, 108, 1)
      numlock_color = -1
      bothlock_color = -1
      invert_numlock = false
      swap_font_color = false
      position = 0, -150
      halign = center
      valign = center
    }
  '';
}
