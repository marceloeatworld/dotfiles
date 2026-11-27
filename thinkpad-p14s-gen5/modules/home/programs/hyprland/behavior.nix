# Runtime behavior: compositor misc, rendering, ecosystem nag, bind behavior.
{ config, ... }:

let
  inherit (config) theme;
in
{
  xdg.configFile."hypr/behavior.lua".text = ''
    local theme_colors = {
      background = "${theme.stripHash theme.colors.background}",
    }

    local config_home = os.getenv("XDG_CONFIG_HOME")
    if config_home == nil or config_home == "" then
      config_home = (os.getenv("HOME") or ".") .. "/.config"
    end

    local ok, runtime_theme = pcall(dofile, config_home .. "/theme/current/hypr.lua")
    if ok and type(runtime_theme) == "table" and type(runtime_theme.colors) == "table" then
      theme_colors.background = runtime_theme.colors.background or theme_colors.background
    end

    hl.config({
      misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_watchdog_warning = true, -- Suppress UWSM/start-hyprland warning (NixOS official method)
        disable_autoreload = true, -- Avoid live config reloads while nh/nixos-rebuild updates the system
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        vrr = 3, -- 0=off, 1=on, 2=fullscreen only, 3=fullscreen with content type 'video'/'game'
        enable_swallow = true,
        swallow_regex = "^(com.mitchellh.ghostty|Alacritty)$",
        force_default_wallpaper = 0,
        background_color = "rgb(" .. theme_colors.background .. ")", -- Themed instead of default grey
        animate_manual_resizes = false, -- Border tracks the cursor directly during drag-resize
        focus_on_activate = false, -- Prevent windows from stealing focus
        on_focus_under_fullscreen = 2, -- 0=ignore, 1=takeover, 2=unfullscreen
        close_special_on_empty = true,
        allow_session_lock_restore = true, -- If hyprlock crashes, allow restarting it (don't expose desktop)
        render_unfocused_fps = 10, -- Matches perf-mode battery/balanced (5 was too aggressive, GPU ring timeouts on AMD)
        enable_anr_dialog = true, -- Show "App Not Responding" dialog for frozen apps (0.54+)
        anr_missed_pings = 3,
        disable_xdg_env_checks = true, -- UWSM handles XDG env, suppress warning
      },

      render = {
        direct_scanout = 0, -- 0=off, 1=on, 2=auto/game (0.54+). Disabled: crash on AMD (hyprwm/Hyprland#9331)
        new_render_scheduling = true, -- Auto triple buffering, improves FPS on Radeon 780M
      },

      ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
      },

      binds = {
        movefocus_cycles_groupfirst = true, -- Tab through group members before moving to next window
        window_direction_monitor_fallback = true, -- Focus next monitor when no window in direction
        hide_special_on_workspace_change = true, -- Auto-hide scratchpad when switching workspaces
        workspace_center_on = 1, -- Cursor lands on last active window of target workspace (pairs with cursor.warp_on_change_workspace)
      },
    })
  '';
}
