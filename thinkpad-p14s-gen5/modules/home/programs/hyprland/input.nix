# Keyboard, touchpad and gesture configuration.
{ ... }:

{
  xdg.configFile."hypr/input.lua".text = ''
    hl.config({
      input = {
        kb_layout = "fr,us", -- French (default) + US English (switch with SUPER+F3 or Waybar)
        kb_variant = ",",
        numlock_by_default = true,
        repeat_rate = 40, -- Slightly slower for comfort
        repeat_delay = 600, -- Longer delay before repeat
        follow_mouse = 1,
        mouse_refocus = true, -- Refocus window under cursor after layout/workspace changes
        focus_on_close = 2, -- After close, focus most recently used window (less jarring than next-in-layout)
        sensitivity = 0,
        scroll_factor = 1.5, -- Faster mouse wheel scrolling

        touchpad = {
          natural_scroll = true,
          disable_while_typing = true,
          tap_to_click = true,
          clickfinger_behavior = true,
          scroll_factor = 0.4, -- Slower, more precise scrolling
          middle_button_emulation = true,
        },
      },

      gestures = {
        workspace_swipe_distance = 300,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_create_new = true,
        workspace_swipe_touch = true,
      },
    })

    -- 3-finger horizontal swipe = workspace switch
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
  '';
}
