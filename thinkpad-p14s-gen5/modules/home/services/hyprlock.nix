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
      after_sleep_cmd = sleep 1 && hyprctl dispatch dpms on
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

    # Suspend after 35 minutes (no DPMS off step — avoids AMD GPU crash)
    listener {
      timeout = 2100
      on-timeout = systemctl suspend
    }
  '';

  # Hyprlock configuration - Informative lock screen with cool info
  xdg.configFile."hypr/hyprlock.conf".text = ''
    # Hyprlock - Informative Lock Screen

    general {
      disable_loading_bar = true
      hide_cursor = true
      grace = 0
      no_fade_in = true
      no_fade_out = true
    }

    background {
      monitor =
      color = rgba(30, 30, 30, 1.0)
    }

    # ═══════════════════════════════════════════════════════════
    # CENTER - Clock and Password
    # ═══════════════════════════════════════════════════════════

    # Clock - Large
    label {
      monitor =
      text = $TIME
      color = rgba(212, 212, 212, 1.0)
      font_size = 96
      font_family = ${theme.fonts.mono}
      position = 0, 200
      halign = center
      valign = center
    }

    # Date
    label {
      monitor =
      text = cmd[update:60000] date '+%A %d %B %Y'
      color = rgba(128, 128, 128, 1.0)
      font_size = 18
      font_family = ${theme.fonts.mono}
      position = 0, 120
      halign = center
      valign = center
    }

    # Password input
    input-field {
      monitor =
      size = 300, 45
      outline_thickness = 2
      dots_size = 0.25
      dots_spacing = 0.2
      dots_center = true
      outer_color = rgba(62, 62, 66, 1)
      inner_color = rgba(30, 30, 30, 1)
      font_color = rgba(212, 212, 212, 1)
      fade_on_empty = false
      placeholder_text =
      hide_input = false
      rounding = 0
      check_color = rgba(106, 153, 85, 1)
      fail_color = rgba(200, 120, 120, 1)
      fail_text = $FAIL
      capslock_color = rgba(200, 176, 112, 1)
      position = 0, 20
      halign = center
      valign = center
    }

    # ═══════════════════════════════════════════════════════════
    # LEFT SIDE - Hyprland Keybindings
    # ═══════════════════════════════════════════════════════════

    # Title
    label {
      monitor =
      text = ┌─ HYPRLAND KEYBINDINGS ─┐
      color = rgba(200, 176, 112, 1.0)
      font_size = 14
      font_family = ${theme.fonts.mono}
      position = 60, 350
      halign = left
      valign = center
    }

    # Keybindings content
    label {
      monitor =
      text = SUPER + Return    Terminal
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 310
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + D         Launcher
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 285
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + B         Browser
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 260
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + E         Files
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 235
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + Q         Kill Window
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 210
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + F         Fullscreen
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 185
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + Space     Float
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 160
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + H/J/K/L   Focus
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 135
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + 1-9       Workspace
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 110
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + S         Scratchpad
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 85
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + V         Clipboard
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 60
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + N         Blue Light
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 35
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + M         Battery Mode
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, 10
      halign = left
      valign = center
    }

    label {
      monitor =
      text = SUPER + Escape    Lock
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, -15
      halign = left
      valign = center
    }

    label {
      monitor =
      text = Print              Screenshot
      color = rgba(128, 128, 128, 1.0)
      font_size = 12
      font_family = ${theme.fonts.mono}
      position = 60, -40
      halign = left
      valign = center
    }

    # ═══════════════════════════════════════════════════════════
    # RIGHT SIDE - ASCII/HEX Reference Table
    # ═══════════════════════════════════════════════════════════

    # Title
    label {
      monitor =
      text = ┌─ ASCII / HEX TABLE ─┐
      color = rgba(200, 176, 112, 1.0)
      font_size = 14
      font_family = ${theme.fonts.mono}
      position = -60, 350
      halign = right
      valign = center
    }

    label {
      monitor =
      text = DEC  HEX  CHAR    DEC  HEX  CHAR
      color = rgba(106, 153, 85, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 315
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  32  0x20  ␣       48  0x30  0
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 290
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  33  0x21  !       65  0x41  A
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 265
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  34  0x22  "       66  0x42  B
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 240
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  35  0x23  #       97  0x61  a
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 215
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  36  0x24  $       98  0x62  b
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 190
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  37  0x25  %       10  0x0A  LF
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 165
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  38  0x26  &       13  0x0D  CR
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 140
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  42  0x2A  *        9  0x09  TAB
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 115
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  47  0x2F  /       27  0x1B  ESC
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 90
      halign = right
      valign = center
    }

    # Powers of 2
    label {
      monitor =
      text = ┌─ POWERS OF 2 ─┐
      color = rgba(200, 176, 112, 1.0)
      font_size = 14
      font_family = ${theme.fonts.mono}
      position = -60, 50
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2⁰=1    2⁴=16    2⁸=256
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 25
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2¹=2    2⁵=32    2⁹=512
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 0
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2²=4    2⁶=64    2¹⁰=1024
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, -25
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2³=8    2⁷=128   2¹⁶=65536
      color = rgba(128, 128, 128, 1.0)
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, -50
      halign = right
      valign = center
    }

    # ═══════════════════════════════════════════════════════════
    # BOTTOM - HTTP Status Codes & Unix Signals
    # ═══════════════════════════════════════════════════════════

    label {
      monitor =
      text = HTTP: 200 OK │ 301 Redirect │ 400 Bad Request │ 401 Unauthorized │ 403 Forbidden │ 404 Not Found │ 500 Server Error
      color = rgba(100, 100, 100, 1.0)
      font_size = 10
      font_family = ${theme.fonts.mono}
      position = 0, -280
      halign = center
      valign = center
    }

    label {
      monitor =
      text = SIGNALS: SIGHUP(1) │ SIGINT(2) │ SIGQUIT(3) │ SIGKILL(9) │ SIGTERM(15) │ SIGSTOP(19) │ SIGCONT(18)
      color = rgba(100, 100, 100, 1.0)
      font_size = 10
      font_family = ${theme.fonts.mono}
      position = 0, -305
      halign = center
      valign = center
    }

    label {
      monitor =
      text = CHMOD: 755 rwxr-xr-x │ 644 rw-r--r-- │ 600 rw------- │ 777 rwxrwxrwx │ 400 r--------
      color = rgba(100, 100, 100, 1.0)
      font_size = 10
      font_family = ${theme.fonts.mono}
      position = 0, -330
      halign = center
      valign = center
    }
  '';
}
