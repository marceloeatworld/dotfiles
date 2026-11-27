# Monitor configuration and smart-gaps workspace rules.
_:

{
  xdg.configFile."hypr/monitors.lua".text = ''
    local external_monitor = "desc:Dell Inc. DELL G2723HN H42C3H3"
    -- Second Dell of the same model, attached through the Belkin USB-C adapter
    -- (shows up as DP-1). The description includes the panel serial, so it
    -- needs its own rule; it sits to the left of the first Dell.
    local external_left = "desc:Dell Inc. DELL G2723HN 452C3H3"

    -- Monitors: explicit configs for known outputs, fallback for any other.
    -- 165 Hz blanks out the HDMI link (bandwidth/cable limit).
    -- 120 Hz caused reboot/poweroff hangs since 2026-07-01: amdgpu wedges the
    -- final hardware reset with a high-refresh HDMI stream active (upstream
    -- drm/amd #4922, #4838). 60 Hz avoids the trigger; retry 120 on a fixed kernel.
    -- Match the Dell by description so HDMI and DisplayPort use one rule.
    hl.monitor({ output = external_monitor, mode = "1920x1080@60", position = "0x0", scale = 1 })
    hl.monitor({ output = external_left,    mode = "1920x1080@60", position = "-1920x0", scale = 1 })
    hl.monitor({ output = "eDP-1",    mode = "1920x1200@60", position = "0x1080", scale = 1 })
    hl.monitor({ output = "",         mode = "preferred",    position = "auto",   scale = 1 })

    -- Smart gaps: remove gaps when only one tiled or fullscreen window (borders/rounding kept).
    hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
    hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })

    -- Workspace -> monitor binding: WS 1 lives on the left Dell, WS 2-5 on the
    -- right Dell, WS 6 on the laptop (eDP-1). When a monitor is unplugged,
    -- Hyprland falls its workspaces back to a connected one. persistent keeps
    -- them visible in waybar even when empty.
    hl.workspace_rule({ workspace = "1", monitor = external_left,    default = true, persistent = true })
    hl.workspace_rule({ workspace = "2", monitor = external_monitor, default = true, persistent = true })
    hl.workspace_rule({ workspace = "3", monitor = external_monitor,                 persistent = true })
    hl.workspace_rule({ workspace = "4", monitor = external_monitor,                 persistent = true })
    hl.workspace_rule({ workspace = "5", monitor = external_monitor,                 persistent = true })
    hl.workspace_rule({ workspace = "6", monitor = "eDP-1",          default = true, persistent = true })
  '';
}
