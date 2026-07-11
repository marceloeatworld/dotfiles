# Keybindings: mod variable and all hl.bind() calls.
{ hyprScripts, ... }:

{
  xdg.configFile."hypr/keybinds.lua".text = ''
    local mod = "SUPER"

    -----------------------------------------------------------------------
    -- Apps & window management
    -----------------------------------------------------------------------
    hl.bind(mod .. " + Return",       hl.dsp.exec_cmd("ghostty"))
    hl.bind(mod .. " + B",            hl.dsp.exec_cmd("brave"))
    hl.bind(mod .. " + E",            hl.dsp.exec_cmd("nemo"))
    hl.bind(mod .. " + A",            hl.dsp.exec_cmd("hyprpwcenter")) -- Audio control (Official Hyprland)
    hl.bind(mod .. " + Q",            hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + Q",    hl.dsp.window.kill()) -- Force kill (for frozen apps)
    hl.bind(mod .. " + F",            hl.dsp.window.fullscreen({ mode = "fullscreen" }))
    hl.bind(mod .. " + SHIFT + F",    hl.dsp.window.fullscreen({ mode = "maximized" })) -- Fake fullscreen
    hl.bind(mod .. " + Space",        hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mod .. " + P",            hl.dsp.window.pin()) -- Pin window (stays visible on all workspaces)
    hl.bind(mod .. " + T",            hl.dsp.layout("togglesplit"))

    -----------------------------------------------------------------------
    -- Window groups (tabbed windows)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + G",                   hl.dsp.group.toggle()) -- Create/dissolve window group
    hl.bind(mod .. " + bracketright",        hl.dsp.group.next()) -- Next tab in group
    hl.bind(mod .. " + bracketleft",         hl.dsp.group.prev()) -- Previous tab in group
    hl.bind(mod .. " + SHIFT + G",           hl.dsp.group.lock_active({ action = "toggle" })) -- Lock group
    hl.bind(mod .. " + CTRL + bracketright", hl.dsp.group.move_window({ forward = true }))
    hl.bind(mod .. " + CTRL + bracketleft",  hl.dsp.group.move_window({ forward = false }))

    -----------------------------------------------------------------------
    -- Quick window switching
    -----------------------------------------------------------------------
    hl.bind(mod .. " + Tab",      hl.dsp.focus({ last = true })) -- Toggle between current and last focused
    hl.bind("ALT + Tab",          hl.dsp.window.cycle_next())
    hl.bind("ALT + SHIFT + Tab",  hl.dsp.window.cycle_next({ next = false }))

    -----------------------------------------------------------------------
    -- Tile swap (swapwindow)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + CTRL + SHIFT + left",  hl.dsp.window.swap({ direction = "l" }))
    hl.bind(mod .. " + CTRL + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
    hl.bind(mod .. " + CTRL + SHIFT + up",    hl.dsp.window.swap({ direction = "u" }))
    hl.bind(mod .. " + CTRL + SHIFT + down",  hl.dsp.window.swap({ direction = "d" }))
    hl.bind(mod .. " + CTRL + SHIFT + H",     hl.dsp.window.swap({ direction = "l" }))
    hl.bind(mod .. " + CTRL + SHIFT + L",     hl.dsp.window.swap({ direction = "r" }))
    hl.bind(mod .. " + CTRL + SHIFT + K",     hl.dsp.window.swap({ direction = "u" }))
    hl.bind(mod .. " + CTRL + SHIFT + J",     hl.dsp.window.swap({ direction = "d" }))

    -----------------------------------------------------------------------
    -- Multi-monitor + window centering
    -----------------------------------------------------------------------
    hl.bind(mod .. " + CTRL + M", hl.dsp.workspace.move({ monitor = "+1" })) -- Move workspace to next monitor
    hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("${hyprScripts.monitor-toggle}/bin/monitor-toggle")) -- Toggle laptop screen (eDP-1) on/off
    hl.bind(mod .. " + W",        hl.dsp.window.center())

    -----------------------------------------------------------------------
    -- Move focus (arrows + hjkl)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "l" }))
    hl.bind(mod .. " + right", hl.dsp.focus({ direction = "r" }))
    hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "u" }))
    hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "d" }))
    hl.bind(mod .. " + H",     hl.dsp.focus({ direction = "l" }))
    hl.bind(mod .. " + L",     hl.dsp.focus({ direction = "r" }))
    hl.bind(mod .. " + K",     hl.dsp.focus({ direction = "u" }))
    hl.bind(mod .. " + J",     hl.dsp.focus({ direction = "d" }))

    -----------------------------------------------------------------------
    -- Move window (arrows + hjkl)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "l" }))
    hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
    hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "u" }))
    hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "d" }))
    hl.bind(mod .. " + SHIFT + H",     hl.dsp.window.move({ direction = "l" }))
    hl.bind(mod .. " + SHIFT + L",     hl.dsp.window.move({ direction = "r" }))
    hl.bind(mod .. " + SHIFT + K",     hl.dsp.window.move({ direction = "u" }))
    hl.bind(mod .. " + SHIFT + J",     hl.dsp.window.move({ direction = "d" }))

    -----------------------------------------------------------------------
    -- Workspaces 1-10: switch and move-window
    -----------------------------------------------------------------------
    for i = 1, 10 do
      local key = i % 10 -- 10 maps to key 0
      hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
      hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    -----------------------------------------------------------------------
    -- Move window to previous/next workspace (easy for AZERTY)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + ALT + left",  hl.dsp.window.move({ workspace = "-1" }))
    hl.bind(mod .. " + ALT + right", hl.dsp.window.move({ workspace = "+1" }))
    hl.bind(mod .. " + ALT + H",     hl.dsp.window.move({ workspace = "-1" }))
    hl.bind(mod .. " + ALT + L",     hl.dsp.window.move({ workspace = "+1" }))

    -----------------------------------------------------------------------
    -- Special workspaces (scratchpad + minimized)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
    hl.bind(mod .. " + minus",         hl.dsp.window.move({ workspace = "special:minimized", follow = false }))
    hl.bind(mod .. " + SHIFT + minus", hl.dsp.workspace.toggle_special("minimized"))

    -----------------------------------------------------------------------
    -- Clipboard history (cliphist + wofi)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + V",         hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
    hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))

    -----------------------------------------------------------------------
    -- DPMS (monitor power) - exec+sleep to avoid undefined behavior (wiki warning)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + CTRL + SHIFT + Escape", hl.dsp.exec_cmd([[sleep 1 && hyprctl eval "hl.dispatch(hl.dsp.dpms({ action = 'off' }))"]]))

    -----------------------------------------------------------------------
    -- Quick tools
    -----------------------------------------------------------------------
    hl.bind(mod .. " + C",         hl.dsp.exec_cmd("hyprpicker -a"))
    hl.bind(mod .. " + N",         hl.dsp.exec_cmd("${hyprScripts.bluelight-toggle}/bin/bluelight-toggle"))
    hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("${hyprScripts.bluelight-off}/bin/bluelight-off"))
    hl.bind(mod .. " + M",         hl.dsp.exec_cmd("${hyprScripts.battery-mode}/bin/battery-mode"))
    hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("${hyprScripts.perf-mode}/bin/perf-mode"))
    hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("${hyprScripts.touchpad-toggle}/bin/touchpad-toggle"))
    hl.bind(mod .. " + Y",         hl.dsp.exec_cmd("${hyprScripts.youtube-toggle}/bin/youtube-toggle")) -- YouTube PiP
    hl.bind(mod .. " + U",         hl.dsp.exec_cmd("${hyprScripts.twitch-toggle}/bin/twitch-toggle")) -- Twitch PiP
    hl.bind(mod .. " + O",         hl.dsp.exec_cmd("${hyprScripts.quick-notes}/bin/quick-notes"))
    hl.bind(mod .. " + X",         hl.dsp.exec_cmd("lab-menu")) -- Malware analysis lab (FLARE-VM + REMnux)
    hl.bind(mod .. " + I",         hl.dsp.exec_cmd("hyprsysteminfo"))
    hl.bind(mod .. " + SHIFT + I", hl.dsp.exec_cmd("${hyprScripts.sysinfo-panel}/bin/sysinfo-panel"))
    hl.bind(mod .. " + Z",         hl.dsp.exec_cmd("wl-freeze -a")) -- Freeze/unfreeze window (SIGSTOP/SIGCONT)
    hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprprop")) -- Inspect window properties

    -----------------------------------------------------------------------
    -- Screenshots (grimblast - official hyprwm/contrib)
    -----------------------------------------------------------------------
    hl.bind("Print",                 hl.dsp.exec_cmd("grimblast --freeze copy area")) -- Region -> clipboard
    hl.bind(mod .. " + Print",       hl.dsp.exec_cmd("grimblast --freeze save area $SCREENSHOT_DIR/$(date +%Y%m%d_%H%M%S).png")) -- Region -> file
    hl.bind("SHIFT + Print",         hl.dsp.exec_cmd("grimblast --freeze copy output")) -- Full screen -> clipboard
    hl.bind(mod .. " + SHIFT + Print", hl.dsp.exec_cmd("grimblast --freeze save output $SCREENSHOT_DIR/$(date +%Y%m%d_%H%M%S).png"))
    hl.bind(mod .. " + CTRL + Print", hl.dsp.exec_cmd("grimblast --freeze copy active")) -- Window -> clipboard

    -----------------------------------------------------------------------
    -- Keyboard layout switch (fr <-> us)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + F3", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

    -----------------------------------------------------------------------
    -- WiFi management
    -----------------------------------------------------------------------
    hl.bind(mod .. " + F2",         hl.dsp.exec_cmd("${hyprScripts.wifi-manage}/bin/wifi-manage reconnect"))
    hl.bind(mod .. " + SHIFT + F2", hl.dsp.exec_cmd("${hyprScripts.wifi-manage}/bin/wifi-manage scan"))
    hl.bind(mod .. " + CTRL + F2",  hl.dsp.exec_cmd("${hyprScripts.wifi-manage}/bin/wifi-manage toggle"))

    -----------------------------------------------------------------------
    -- Waybar (restart via systemd user service, not killall)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("systemctl --user restart waybar.service"))

    -----------------------------------------------------------------------
    -- Focus workspace on current monitor (multi-monitor, 0.54+)
    -----------------------------------------------------------------------
    for i = 1, 5 do
      hl.bind(mod .. " + CTRL + " .. i, hl.dsp.focus({ workspace = i, on_current_monitor = true }))
    end

    -----------------------------------------------------------------------
    -- Swap workspaces between monitors
    -----------------------------------------------------------------------
    hl.bind(mod .. " + SHIFT + Tab", hl.dsp.workspace.swap_monitors({ monitor1 = "eDP-1", monitor2 = "HDMI-A-1" }))

    -----------------------------------------------------------------------
    -- Mouse wheel cycles through existing workspaces (e = existing)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -----------------------------------------------------------------------
    -- Bypass app shortcut inhibition (was bindp) - for escape/system keys,
    -- especially fullscreen games
    -----------------------------------------------------------------------
    -- Wofi drun: full app list with icons on open. Replaces hyprlauncher
    -- (v0.1.6 fuzzy-only, cannot list/browse apps); switch back when upstream
    -- gains a browse view.
    hl.bind(mod .. " + D",            hl.dsp.exec_cmd("wofi --show drun --allow-images"),                                       { bypass = true })
    hl.bind(mod .. " + Escape",       hl.dsp.exec_cmd("hyprlock"),                                                              { bypass = true })
    -- Graceful shutdown via hyprshutdown: asks apps to close gracefully, quits Hyprland, runs post-cmd
    hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'"), { bypass = true })
    hl.bind(mod .. " + CTRL + Escape",  hl.dsp.exec_cmd("hyprshutdown -t 'Restarting...' --post-cmd 'systemctl reboot'"),      { bypass = true })
    hl.bind(mod .. " + ALT + Escape",   hl.dsp.exec_cmd("systemctl suspend"),                                                   { bypass = true })
    hl.bind(mod .. " + F1",             hl.dsp.exec_cmd("${hyprScripts.hypr-keys}/bin/hypr-keys"),                              { bypass = true }) -- Keybindings cheatsheet

    -----------------------------------------------------------------------
    -- Mouse binds (was bindm)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -----------------------------------------------------------------------
    -- Resize active window when held (was binde)
    -----------------------------------------------------------------------
    hl.bind(mod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + H",     hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + L",     hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + K",     hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
    hl.bind(mod .. " + CTRL + J",     hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

    -----------------------------------------------------------------------
    -- Audio/media controls when locked (was bindl) - use SwayOSD (native OSD)
    -----------------------------------------------------------------------
    hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle && pkill -RTMIN+10 waybar"), { locked = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"),  { locked = true })
    hl.bind("XF86AudioPlay",    hl.dsp.exec_cmd("playerctl play-pause"),                       { locked = true })
    hl.bind("XF86AudioPause",   hl.dsp.exec_cmd("playerctl play-pause"),                       { locked = true })
    hl.bind("XF86AudioNext",    hl.dsp.exec_cmd("playerctl next"),                             { locked = true })
    hl.bind("XF86AudioPrev",    hl.dsp.exec_cmd("playerctl previous"),                         { locked = true })
    hl.bind("XF86AudioStop",    hl.dsp.exec_cmd("playerctl stop"),                             { locked = true })

    -----------------------------------------------------------------------
    -- Volume / brightness, locked + repeat (was bindle)
    -----------------------------------------------------------------------
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise && pkill -RTMIN+10 waybar"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower && pkill -RTMIN+10 waybar"), { locked = true, repeating = true })
    -- brightness-sync = swayosd OSD + laptop backlight, then mirrors the level
    -- to the external monitor over DDC/CI (debounced, see waybar-scripts).
    hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("$HOME/.config/waybar/scripts/brightness-sync.sh raise"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("$HOME/.config/waybar/scripts/brightness-sync.sh lower"), { locked = true, repeating = true })
  '';
}
