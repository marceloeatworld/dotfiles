# Vicinae - Spotlight/Raycast-style launcher (Super+D) and clipboard history
# (Super+V): apps, clipboard with image thumbnails, calculator, emoji, window
# switcher and file search in one window. Wofi stays for the dmenu scripts.
#
# Theming: one Vicinae theme per config.theme definition (ids match the theme
# names). Vicinae picks the dark/light entry from the system color scheme,
# which theme-switch sets; theme-switch also runs `vicinae theme set` so the
# exact runtime theme is active (runtime-theme.nix).
{ config, lib, ... }:

let
  inherit (config) theme;
  definitions = theme.definitions;
  current = definitions.${theme.name};

  # Dark/light map for Vicinae's appearance switch. The runtime pair is
  # neobrutalist / neobrutalist-light (runtime-theme.nix schedule).
  darkName = if current.appearance.preferDark then theme.name else "neobrutalist";
  lightName = if current.appearance.preferDark then "neobrutalist-light" else theme.name;

  vicinaeTheme = _name: t:
    let
      c = t.colors;
      dark = t.appearance.preferDark;
    in
    {
      meta = {
        version = 1;
        name = t.name;
        description = t.description;
        variant = if dark then "dark" else "light";
        inherits = if dark then "vicinae-dark" else "vicinae-light";
      };
      colors = {
        core = {
          accent = c.accent;
          accent_foreground = c.background;
          background = c.backgroundAlt;
          foreground = c.foreground;
          secondary_background = c.surface;
          border = c.border;
        };
        main_window.border = c.border;
        settings_window.border = c.border;
        accents = {
          blue = c.blue;
          green = c.green;
          magenta = c.magenta;
          orange = c.orange;
          red = c.red;
          yellow = c.yellow;
          cyan = c.cyan;
          purple = c.magenta;
        };
        text = {
          muted = c.foregroundDim;
          placeholder = c.comment;
          danger = c.red;
          success = c.green;
          selection = { background = c.selection; foreground = c.foreground; };
          links = { default = c.blue; visited = c.magenta; };
        };
        input = {
          border = c.border;
          border_focus = c.accent;
          border_error = c.red;
        };
        list.item.selection = {
          background = c.surface;
          foreground = c.foreground;
          secondary_background = c.surface;
          secondary_foreground = c.foregroundDim;
        };
      };
    };
in
{
  programs.vicinae = {
    enable = true;
    systemd.enable = true; # graphical-session.target, same as mako/waybar under UWSM

    themes = lib.mapAttrs vicinaeTheme definitions;

    settings = {
      telemetry.system_info = false;
      tray.enabled = false;
      # Paste-to-active-window needs /dev/input access (input group); without
      # it the server logs a permission error per device. Copy fallback is fine.
      input_server.enabled = false;
      pop_to_root_on_close = true;
      close_on_focus_loss = true;
      search_files_in_root = false; # keep CPU low; the File Search command still exists

      font.normal.family = theme.fonts.sans;

      theme = {
        dark = { name = darkName; icon_theme = definitions.${darkName}.appearance.iconTheme; };
        light = { name = lightName; icon_theme = definitions.${lightName}.appearance.iconTheme; };
      };

      launcher_window = {
        rounding = 10; # matches decoration.rounding in look-feel.nix
        opacity = 0.96;
        material = "blur"; # Hyprland blurs the layer (window-rules.lua)
        client_side_decorations = {
          enabled = true;
          border_width = 1;
          shadow_size = 12;
        };
        layer_shell = {
          enabled = true;
          # "exclusive" breaks mouse input on popups under Hyprland (upstream note)
          keyboard_interactivity = "on_demand";
          layer = "top";
        };
      };
    };
  };
}
