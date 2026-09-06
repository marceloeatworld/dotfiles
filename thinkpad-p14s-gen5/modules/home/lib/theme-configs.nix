# Theme-derived config files shared by the build-time fallbacks
# (hyprlauncher.nix, mako.nix, hyprlock.nix) and the runtime theme assets
# (runtime-theme.nix writes one copy per theme and theme-switch relinks them).
{ lib }:

let
  keymap = import ../programs/hyprland/keymap.nix { inherit lib; };

  # "#RRGGBB" -> hyprtoolkit 0xAARRGGBB
  hyprColor = hex: "0xFF${builtins.substring 1 6 hex}";

  # "#RRGGBB" -> hyprlock rgba(R, G, B, A)
  hexToRgba = hex: alpha:
    let
      hexDigit = c:
        if c == "0" then 0 else if c == "1" then 1 else if c == "2" then 2
        else if c == "3" then 3 else if c == "4" then 4 else if c == "5" then 5
        else if c == "6" then 6 else if c == "7" then 7 else if c == "8" then 8
        else if c == "9" then 9 else if c == "a" || c == "A" then 10
        else if c == "b" || c == "B" then 11 else if c == "c" || c == "C" then 12
        else if c == "d" || c == "D" then 13 else if c == "e" || c == "E" then 14
        else if c == "f" || c == "F" then 15 else 0;
      h = builtins.substring 1 6 hex;
      r = hexDigit (builtins.substring 0 1 h) * 16 + hexDigit (builtins.substring 1 1 h);
      g = hexDigit (builtins.substring 2 1 h) * 16 + hexDigit (builtins.substring 3 1 h);
      b = hexDigit (builtins.substring 4 1 h) * 16 + hexDigit (builtins.substring 5 1 h);
    in
    "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";
in
{
  # Hyprtoolkit apps: hyprlauncher, hyprpwcenter, hyprsysteminfo
  hyprtoolkitConf = theme: ''
    background = ${hyprColor theme.colors.background}
    base = ${hyprColor theme.colors.background}
    alternate_base = ${hyprColor theme.colors.surface}

    text = ${hyprColor theme.colors.foreground}
    bright_text = ${hyprColor theme.colors.brightWhite}

    accent = ${hyprColor theme.colors.accent}
    accent_secondary = ${hyprColor theme.colors.accentSecondary}

    font_size = 12
    h1_size = 17
    h2_size = 14
    h3_size = 12
    small_font_size = 10

    # Hyprtoolkit crashes if the configured icon theme cannot be resolved.
    # hicolor is always present in the system profile and is enough here.
    icon_theme = hicolor
  '';

  # Mako notification daemon; radius matches wofi, swayosd and the waybar islands
  makoConf = theme: ''
    background-color=${theme.colors.backgroundAlt}
    text-color=${theme.colors.foreground}
    border-color=${theme.colors.accent}
    progress-color=over ${theme.colors.surface}
    border-radius=8
    border-size=2
    width=360
    height=150
    max-visible=3
    margin=8
    padding=14
    default-timeout=4000
    ignore-timeout=false
    font=${theme.fonts.mono} 10
    icons=true
    max-icon-size=32
    icon-location=left
    actions=true
    group-by=app-name
    format=<b>%s</b>\n%b
    layer=overlay
    anchor=top-right

    [urgency=low]
    default-timeout=2000
    border-color=${theme.colors.border}

    [urgency=high]
    border-color=${theme.colors.red}
    default-timeout=0

    [app-name=SwayOSD]
    default-timeout=1000
    group-by=app-name
  '';

  # Hyprlock: clock and password in the center, keybindings on the left,
  # ASCII/HEX and other reference tables on the right and bottom.
  hyprlockConf = theme:
    let
      bg = hexToRgba theme.colors.background "1.0";
      fg = hexToRgba theme.colors.foreground "1.0";
      dim = hexToRgba theme.colors.comment "1.0";
      accent = hexToRgba theme.colors.accent "1.0";
      green = hexToRgba theme.colors.green "1";
      red = hexToRgba theme.colors.red "1";
      border = hexToRgba theme.colors.border "1";
      muted = hexToRgba theme.colors.foregroundDim "1.0";

      lockLabels = lib.concatStringsSep "\n" (lib.imap0
        (index: line: ''
          label {
            monitor =
            text = ${line}
            color = ${dim}
            font_size = 12
            font_family = ${theme.fonts.mono}
            position = 60, ${toString (310 - 25 * index)}
            halign = left
            valign = center
          }
        '')
        keymap.lockLines);
    in
    ''
    # Hyprlock - Informative Lock Screen

    # hyprlock 0.9.5: disable_loading_bar/grace/no_fade_in/no_fade_out removed;
    # grace = 0 is the default (--grace CLI arg otherwise), fades moved to animations
    general {
      hide_cursor = true
    }

    animations {
      enabled = false
    }

    background {
      monitor =
      color = ${bg}
    }

    # ═══════════════════════════════════════════════════════════
    # CENTER - Clock and Password
    # ═══════════════════════════════════════════════════════════

    # Clock - Large
    label {
      monitor =
      text = $TIME
      color = ${fg}
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
      color = ${dim}
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
      outer_color = ${border}
      inner_color = ${bg}
      font_color = ${fg}
      fade_on_empty = false
      placeholder_text =
      hide_input = false
      rounding = 0
      check_color = ${green}
      fail_color = ${red}
      fail_text = $FAIL
      capslock_color = ${accent}
      position = 0, 20
      halign = center
      valign = center
    }

    # ═══════════════════════════════════════════════════════════
    # LEFT SIDE - Hyprland Keybindings (keymap.nix, lock = true)
    # ═══════════════════════════════════════════════════════════

    label {
      monitor =
      text = ┌─ HYPRLAND KEYBINDINGS ─┐
      color = ${accent}
      font_size = 14
      font_family = ${theme.fonts.mono}
      position = 60, 350
      halign = left
      valign = center
    }

${lockLabels}
    # ═══════════════════════════════════════════════════════════
    # RIGHT SIDE - ASCII/HEX Reference Table
    # ═══════════════════════════════════════════════════════════

    # Title
    label {
      monitor =
      text = ┌─ ASCII / HEX TABLE ─┐
      color = ${accent}
      font_size = 14
      font_family = ${theme.fonts.mono}
      position = -60, 350
      halign = right
      valign = center
    }

    label {
      monitor =
      text = DEC  HEX  CHAR    DEC  HEX  CHAR
      color = ${green}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 315
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  32  0x20  ␣       48  0x30  0
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 290
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  33  0x21  !       65  0x41  A
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 265
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  34  0x22  "       66  0x42  B
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 240
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  35  0x23  #       97  0x61  a
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 215
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  36  0x24  $       98  0x62  b
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 190
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  37  0x25  %       10  0x0A  LF
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 165
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  38  0x26  &       13  0x0D  CR
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 140
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  42  0x2A  *        9  0x09  TAB
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 115
      halign = right
      valign = center
    }

    label {
      monitor =
      text =  47  0x2F  /       27  0x1B  ESC
      color = ${dim}
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
      color = ${accent}
      font_size = 14
      font_family = ${theme.fonts.mono}
      position = -60, 50
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2⁰=1    2⁴=16    2⁸=256
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 25
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2¹=2    2⁵=32    2⁹=512
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, 0
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2²=4    2⁶=64    2¹⁰=1024
      color = ${dim}
      font_size = 11
      font_family = ${theme.fonts.mono}
      position = -60, -25
      halign = right
      valign = center
    }

    label {
      monitor =
      text = 2³=8    2⁷=128   2¹⁶=65536
      color = ${dim}
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
      color = ${muted}
      font_size = 10
      font_family = ${theme.fonts.mono}
      position = 0, -280
      halign = center
      valign = center
    }

    label {
      monitor =
      text = SIGNALS: SIGHUP(1) │ SIGINT(2) │ SIGQUIT(3) │ SIGKILL(9) │ SIGTERM(15) │ SIGSTOP(19) │ SIGCONT(18)
      color = ${muted}
      font_size = 10
      font_family = ${theme.fonts.mono}
      position = 0, -305
      halign = center
      valign = center
    }

    label {
      monitor =
      text = CHMOD: 755 rwxr-xr-x │ 644 rw-r--r-- │ 600 rw------- │ 777 rwxrwxrwx │ 400 r--------
      color = ${muted}
      font_size = 10
      font_family = ${theme.fonts.mono}
      position = 0, -330
      halign = center
      valign = center
    }
    '';
}
