# Hyprland configuration via Home Manager
{ pkgs, inputs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # Use the Hyprland package from the flake
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

    # Import Omarchy theme (choose one from the list below)
    # Available themes: catppuccin, catppuccin-latte, everforest, flexoki-light,
    #                   gruvbox, kanagawa, matte-black, nord, osaka-jade,
    #                   ristretto, rose-pine, tokyo-night
    extraConfig = ''
      source = ${inputs.omarchy}/themes/catppuccin/hyprland.conf
    '';

    settings = {
      # Monitor configuration
      # eDP-1: Built-in Lenovo screen (1920x1200)
      # HDMI-A-1/DP-1: External monitor (1920x1080) - primary when connected
      monitor = [
        # External monitor (primary when connected) - positioned at top
        "HDMI-A-1,1920x1080@60,0x0,1"
        "DP-1,1920x1080@60,0x0,1"

        # Built-in laptop screen - positioned below external
        # When external connected: at 0x1080 (below external)
        # When no external: at 0x0
        "eDP-1,1920x1200@60,0x1080,1"

        # Fallback for unknown monitors
        ",preferred,auto,1"
      ];

      # Autostart applications
      exec-once = [
        "waybar"
        "mako"
        "swaylock -f"
        "hyprpaper"
      ];

      # Environment variables
      env = [
        # Cursor
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"

        # Wayland backend selection (force native Wayland for better performance)
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "SDL_VIDEODRIVER,wayland"

        # Browser Wayland support (Brave, VS Code, Electron apps)
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"

        # Session identification (tells apps which compositor is running)
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
      ];

      # Input configuration
      input = {
        kb_layout = "fr";
        numlock_by_default = true;

        # Keyboard responsiveness
        repeat_rate = 40;
        repeat_delay = 600;

        follow_mouse = 1;

        touchpad = {
          natural_scroll = true;
          disable_while_typing = true;
          tap-to-click = true;
          clickfinger_behavior = true;
          scroll_factor = 0.4;  # Adjust for touchpad scroll speed (0.4 = slower, 1.0 = normal)
        };

        sensitivity = 0;
      };

      # General window settings
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "rgba(cba6f7ee) rgba(94e2d5ee) 45deg";
        "col.inactive_border" = "rgba(585b70aa)";
        layout = "dwindle";
        resize_on_border = true;
      };

      # Decorations
      decoration = {
        rounding = 8;

        blur = {
          enabled = true;
          size = 6;
          passes = 3;
          new_optimizations = true;
          xray = true;
          ignore_opacity = true;
        };

        drop_shadow = true;
        shadow_range = 20;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";

        active_opacity = 1.0;
        inactive_opacity = 0.95;
        fullscreen_opacity = 1.0;
      };

      # Animations
      animations = {
        enabled = true;
        bezier = [
          "fluent_decel, 0.0, 0.2, 0.4, 1.0"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
        ];

        animation = [
          "windows, 1, 4, easeOutCubic, popin 70%"
          "windowsOut, 1, 4, fluent_decel, popin 80%"
          "windowsMove, 1, 3, easeOutCubic"
          "fade, 1, 4, easeOutCubic"
          "fadeIn, 1, 4, easeOutCubic"
          "fadeOut, 1, 4, easeOutCubic"
          "border, 1, 3, easeOutCubic"  # Animated border color transitions
          "workspaces, 1, 4, easeOutCubic, fade"
          "specialWorkspace, 1, 4, easeOutCubic, slidevert"
        ];
      };

      # Dwindle layout
      dwindle = {
        pseudotile = true;
        preserve_split = true;
        no_gaps_when_only = false;
      };

      # Master layout
      master = {
        new_status = "master";
      };

      # Gestures
      gestures = {
        workspace_swipe = true;
        workspace_swipe_fingers = 3;
        workspace_swipe_cancel_ratio = 0.15;
      };

      # Misc settings
      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 1;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
      };

      # Keybindings
      "$mod" = "SUPER";

      bind = [
        # Applications
        "$mod, Return, exec, kitty"
        "$mod, B, exec, brave"
        "$mod, E, exec, nemo"
        "$mod, D, exec, wofi --show drun"

        # Window management
        "$mod, Q, killactive"
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1"
        "$mod, Space, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"

        # Focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"

        # Move windows
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        # Utilities
        "$mod, Escape, exec, swaylock"
        "$mod SHIFT, Escape, exec, systemctl poweroff"
        "$mod, C, exec, hyprpicker -a"
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Media keys
      bindl = [
        ", XF86AudioMute, exec, pamixer -t"
        ", XF86AudioMicMute, exec, pamixer --default-source -t"
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, pamixer -i 5"
        ", XF86AudioLowerVolume, exec, pamixer -d 5"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      # Window rules
      windowrule = [
        "float, ^(pavucontrol)$"
        "float, ^(nm-connection-editor)$"
        "float, ^(blueman-manager)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
      ];

      windowrulev2 = [
        # Terminal opacity
        "opacity 0.95 0.95,class:^(kitty)$"
        "opacity 0.95 0.95,class:^(thunar)$"

        # Suppress maximize events (tiling WM best practice)
        "suppressevent maximize, class:.*"

        # Global opacity (Omarchy-inspired: 97% active, 90% inactive)
        "opacity 0.97 0.90,class:.*"

        # Browser improvements
        "tile,class:^(Brave-browser)$"  # Force tiling (fixes Chromium bugs)
        "opacity 1.0 0.97,class:^(Brave-browser)$"

        # Full opacity for video streaming/calls (no dimming)
        "opacity 1.0 1.0,title:^.*(YouTube|Netflix|Twitch|Zoom|Meet).*$"

        # XWayland focus fix (prevents focus on empty XWayland windows)
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

        # IDE/Editor opacity
        "opacity 1.0 0.95,class:^(code-url-handler)$"  # VS Code
        "opacity 1.0 0.95,class:^(jetbrains-.*)$"      # JetBrains IDEs

        # Picture-in-Picture improvements
        "float,title:^(Picture-in-Picture)$"
        "pin,title:^(Picture-in-Picture)$"
        "size 640 360,title:^(Picture-in-Picture)$"
        "move 100%-650 100%-370,title:^(Picture-in-Picture)$"  # Bottom-right corner
      ];
    };
  };

  # Additional Hyprland-related packages
  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprlock
    brightnessctl
  ];
}
