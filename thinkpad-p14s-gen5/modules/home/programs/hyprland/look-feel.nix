# Visual styling: layout, decoration, animations, cursor.
{ config, ... }:

let
  theme = config.theme;
in
{
  xdg.configFile."hypr/look-feel.lua".text = ''
    local theme_colors = {
      accent = "${theme.stripHash theme.colors.accent}",
      accentSecondary = "${theme.stripHash theme.colors.accentSecondary}",
      surface = "${theme.stripHash theme.colors.surface}",
      foreground = "${theme.stripHash theme.colors.foreground}",
      foregroundDim = "${theme.stripHash theme.colors.foregroundDim}",
      border = "${theme.stripHash theme.colors.border}",
    }

    local config_home = os.getenv("XDG_CONFIG_HOME")
    if config_home == nil or config_home == "" then
      config_home = (os.getenv("HOME") or ".") .. "/.config"
    end

    local ok, runtime_theme = pcall(dofile, config_home .. "/theme/current/hypr.lua")
    if ok and type(runtime_theme) == "table" and type(runtime_theme.colors) == "table" then
      for key, value in pairs(runtime_theme.colors) do
        if theme_colors[key] ~= nil then
          theme_colors[key] = value
        end
      end
    end

    hl.config({
      general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
          active_border = { colors = {"rgb(" .. theme_colors.accent .. ")", "rgb(" .. theme_colors.accentSecondary .. ")"}, angle = 45 },
          inactive_border = "rgb(" .. theme_colors.surface .. ")",
        },
        layout = "dwindle",
        resize_on_border = true, -- Invisible resize zone on edges
        extend_border_grab_area = 15,
        allow_tearing = false,

        -- Floating window snap (0.54+) - snap to edges and other windows
        snap = {
          enabled = true,
          window_gap = 8,
          monitor_gap = 8,
        },
      },

      decoration = {
        rounding = 10, -- Rounded corners
        rounding_power = 2.3, -- Squircle curve (2.0 = circle, 4.0 = squircle)
        dim_modal = true, -- Dim parent windows of modal dialogs (0.54+)
        dim_inactive = true,
        dim_strength = 0.16, -- Subtle - just enough to highlight focused window

        blur = {
          enabled = true,
          size = 4,
          passes = 1, -- 6/2 was a heavy combo on the 780M iGPU; 4/1 looks close for far less GPU heat

          ignore_opacity = true,
          new_optimizations = true,
          xray = true, -- Floating windows ignore tiled in blur (perf)
          special = true, -- Blur behind scratchpad
          popups = true, -- Blur behind right-click menus
        },

        shadow = {
          enabled = true,
          range = 20,
          render_power = 3,
          color = "rgba(0000004D)", -- black 30% opacity
          color_inactive = "rgba(00000026)", -- black 15% opacity
          offset = {0, 2},
        },

        -- Subtle glow on focused window (0.54+)
        glow = {
          enabled = true,
          range = 8,
          render_power = 3,
          color = "rgba(" .. theme_colors.accent .. "26)", -- accent 15% opacity
          color_inactive = "rgba(00000000)", -- No glow on inactive
        },

        active_opacity = 1.0,
        inactive_opacity = 1.0, -- 0.94 forced alpha+blur compositing on every unfocused window; most apps overrode it to 1.0 anyway
        fullscreen_opacity = 1.0,
      },

      animations = {
        enabled = true, -- Fast snappy animations (auto-disabled on battery by perf-mode-daemon)
      },

      dwindle = {
        preserve_split = true,
        smart_split = false,
        force_split = 2, -- Always split to the right (horizontal/landscape)
        split_width_multiplier = 1.5, -- Prefer horizontal splits
        precise_mouse_move = true, -- Drop windows more precisely with mouse (0.54+)
      },

      master = {
        new_status = "master",
        new_on_top = true,
      },

      group = {
        col = {
          border_active = "rgb(" .. theme_colors.accentSecondary .. ")",
          border_inactive = "rgb(" .. theme_colors.border .. ")",
        },
        groupbar = {
          enabled = true,
          height = 18,
          font_size = 10,
          col = {
            active = "rgb(" .. theme_colors.accentSecondary .. ")",
            inactive = "rgb(" .. theme_colors.surface .. ")",
          },
          text_color = "rgb(" .. theme_colors.foreground .. ")",
          text_color_inactive = "rgb(" .. theme_colors.foregroundDim .. ")",
          font_weight_active = "bold",
          font_weight_inactive = "normal",
          text_padding = 4,
          round_only_edges = true,
        },
        drag_into_group = 1,
      },

      cursor = {
        no_hardware_cursors = 2, -- 0=off, 1=on, 2=auto (disable hw cursors only when tearing)
        no_break_fs_vrr = 2, -- Auto: enabled for fullscreen apps with content type 'game'
        inactive_timeout = 3,
        hide_on_key_press = true,
        hide_on_touch = true,
        enable_hyprcursor = false, -- Disabled: Bibata is XCursor-only, hyprcursor crashes on fallback
        warp_on_toggle_special = 1,
        warp_on_change_workspace = 1, -- Cursor follows to last focused window when switching workspace
        persistent_warps = true, -- Cursor returns to its last position relative to a refocused window
      },
    })

    -- Bezier curves (must be defined before animations reference them)
    hl.curve("fluent_decel",   { type = "bezier", points = { {0.0,  0.2 }, {0.4,  1.0 } } })
    hl.curve("easeOutCirc",    { type = "bezier", points = { {0,    0.55}, {0.45, 1   } } })
    hl.curve("easeOutCubic",   { type = "bezier", points = { {0.33, 1   }, {0.68, 1   } } })
    hl.curve("easeInOutQuart", { type = "bezier", points = { {0.76, 0   }, {0.24, 1   } } })
    hl.curve("linear",         { type = "bezier", points = { {0,    0   }, {1,    1   } } })
    hl.curve("snappy",         { type = "bezier", points = { {0.2,  1.0 }, {0.3,  1.0 } } })
    hl.curve("overshot",       { type = "bezier", points = { {0.13, 0.99}, {0.29, 1.2 } } }) -- Pronounced overshoot for workspace slides
    hl.curve("bounce",         { type = "bezier", points = { {0.05, 0.9 }, {0.1,  1.35} } }) -- Bouncy entry for window open/move

    -- Animation rules
    hl.animation({ leaf = "windows",          enabled = true,  speed = 5, bezier = "bounce",         style = "popin 90%" })
    hl.animation({ leaf = "windowsOut",       enabled = true,  speed = 2, bezier = "fluent_decel",   style = "popin 90%" })
    hl.animation({ leaf = "windowsMove",      enabled = true,  speed = 4, bezier = "bounce",         style = "slide" })
    hl.animation({ leaf = "fade",             enabled = true,  speed = 3, bezier = "easeOutCubic" })
    hl.animation({ leaf = "fadeIn",           enabled = true,  speed = 2, bezier = "easeOutCubic" })
    hl.animation({ leaf = "fadeOut",          enabled = true,  speed = 2, bezier = "easeOutCubic" })
    hl.animation({ leaf = "fadeSwitch",       enabled = true,  speed = 2, bezier = "easeOutCubic" }) -- Focus change opacity transition
    hl.animation({ leaf = "fadeDim",          enabled = true,  speed = 3, bezier = "easeOutCubic" }) -- Smooth dim transition
    hl.animation({ leaf = "fadeShadow",       enabled = true,  speed = 3, bezier = "easeOutCubic" }) -- Shadow fade on focus change
    hl.animation({ leaf = "border",           enabled = true,  speed = 3, bezier = "easeOutCubic" }) -- Animate border color on focus change
    hl.animation({ leaf = "workspaces",       enabled = true,  speed = 5, bezier = "overshot",       style = "slidefade 20%" })
    hl.animation({ leaf = "specialWorkspace", enabled = true,  speed = 3, bezier = "easeInOutQuart", style = "slidevert" })
    hl.animation({ leaf = "layers",           enabled = true,  speed = 2, bezier = "easeOutCubic",   style = "fade" }) -- Waybar popups etc.
  '';
}
