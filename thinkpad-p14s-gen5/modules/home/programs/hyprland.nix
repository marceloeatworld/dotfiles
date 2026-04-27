# Hyprland - Using pinned official flake for plugin compatibility
{ config, pkgs, inputs, ... }:

let
  theme = config.theme;
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  scripts = import ./hyprland/scripts.nix {
    inherit pkgs hyprlandPkg;
  };
  inherit (scripts)
    youtube-toggle
    twitch-toggle
    youtube-pip-dock-toggle
    twitch-pip-dock-toggle
    youtube-pip-toggle
    bluelight-toggle
    bluelight-off
    bluelight-auto
    perf-mode
    perf-mode-auto
    perf-mode-daemon
    quick-notes
    hypr-keys
    sysinfo-panel
    wifi-manage
    youtube-opacity-daemon
    twitch-opacity-daemon
    battery-mode
    touchpad-toggle
    hypr-current-workspace-launch
    zapzap-current-workspace
    steam-current-workspace
    vesktop-current-workspace
    spotify-current-workspace
    telegram-current-workspace
    keepassxc-current-workspace
    joplin-current-workspace
    bruno-current-workspace
    rustdesk-current-workspace
    ;
in
{
  # Wofi is used for clipboard history and quick WiFi/password prompts. Keep it
  # visually aligned with the rest of the desktop instead of the GTK default.
  xdg.configFile."wofi/config".text = ''
    insensitive=true
    matching=fuzzy
    no_actions=true
    term=ghostty
    width=640
    height=420
  '';

  xdg.configFile."wofi/style.css".text = ''
    * {
      font-family: "${theme.fonts.mono}", monospace;
      font-size: 12px;
    }

    window {
      margin: 0;
      padding: 0;
      background-color: ${theme.colors.backgroundAlt};
      border: 1px solid ${theme.colors.border};
      border-radius: 8px;
      color: ${theme.colors.foreground};
    }

    #outer-box {
      margin: 0;
      padding: 10px;
      background-color: ${theme.colors.backgroundAlt};
    }

    #input {
      margin: 0 0 8px 0;
      padding: 8px 10px;
      background-color: ${theme.colors.surface};
      border: 1px solid ${theme.colors.border};
      border-radius: 6px;
      color: ${theme.colors.foreground};
    }

    #input:focus {
      border-color: ${theme.colors.accent};
    }

    #scroll {
      margin: 0;
      border: none;
    }

    #inner-box {
      margin: 0;
      padding: 0;
      background-color: transparent;
    }

    #entry {
      padding: 8px 10px;
      border-radius: 6px;
      color: ${theme.colors.foregroundDim};
    }

    #entry:selected {
      background-color: ${theme.colors.selection};
      color: ${theme.colors.foreground};
    }

    #text {
      color: inherit;
    }

    #img {
      margin-right: 8px;
    }
  '';

  xdg.desktopEntries = {
    "com.rtosta.zapzap" = {
      name = "ZapZap";
      genericName = "WhatsApp Client";
      comment = "WhatsApp desktop client";
      exec = "${zapzap-current-workspace}/bin/zapzap-current-workspace %u";
      icon = "com.rtosta.zapzap";
      terminal = false;
      type = "Application";
      categories = [ "Network" "InstantMessaging" "Chat" ];
      mimeType = [ "x-scheme-handler/whatsapp" ];
    };

    steam = {
      name = "Steam";
      genericName = "Game Store";
      comment = "Application for managing and playing games on Steam";
      exec = "${steam-current-workspace}/bin/steam-current-workspace %U";
      icon = "steam";
      terminal = false;
      type = "Application";
      categories = [ "Network" "FileTransfer" "Game" ];
      mimeType = [
        "x-scheme-handler/steam"
        "x-scheme-handler/steamlink"
      ];
    };

    vesktop = {
      name = "Vesktop";
      genericName = "Discord Client";
      comment = "Discord desktop client with Vencord";
      exec = "${vesktop-current-workspace}/bin/vesktop-current-workspace %U";
      icon = "vesktop";
      terminal = false;
      type = "Application";
      categories = [ "Network" "InstantMessaging" "Chat" ];
      mimeType = [ "x-scheme-handler/discord" ];
    };

    spotify = {
      name = "Spotify";
      genericName = "Music Player";
      comment = "Listen to music and podcasts";
      exec = "${spotify-current-workspace}/bin/spotify-current-workspace %U";
      icon = "spotify-client";
      terminal = false;
      type = "Application";
      categories = [ "Audio" "Music" "Player" "AudioVideo" ];
      mimeType = [ "x-scheme-handler/spotify" ];
    };

    "org.telegram.desktop" = {
      name = "Telegram";
      genericName = "Messaging Client";
      comment = "Telegram desktop client";
      exec = "${telegram-current-workspace}/bin/telegram-current-workspace %U";
      icon = "org.telegram.desktop";
      terminal = false;
      type = "Application";
      categories = [ "Chat" "Network" "InstantMessaging" "Qt" ];
      mimeType = [
        "x-scheme-handler/tg"
        "x-scheme-handler/tonsite"
      ];
    };

    "org.keepassxc.KeePassXC" = {
      name = "KeePassXC";
      genericName = "Password Manager";
      comment = "Community-driven port of the Windows application KeePass Password Safe";
      exec = "${keepassxc-current-workspace}/bin/keepassxc-current-workspace %f";
      icon = "keepassxc";
      terminal = false;
      type = "Application";
      categories = [ "Utility" "Security" "Qt" ];
      mimeType = [ "application/x-keepass2" ];
    };

    joplin = {
      name = "Joplin";
      genericName = "Note Taking";
      comment = "Note taking and to-do application";
      exec = "${joplin-current-workspace}/bin/joplin-current-workspace %U";
      icon = "joplin";
      terminal = false;
      type = "Application";
      categories = [ "Office" ];
      mimeType = [ "x-scheme-handler/joplin" ];
    };

    bruno = {
      name = "Bruno";
      genericName = "API Client";
      comment = "Open source API client";
      exec = "${bruno-current-workspace}/bin/bruno-current-workspace %U";
      icon = "bruno";
      terminal = false;
      type = "Application";
      categories = [ "Development" ];
    };

    rustdesk = {
      name = "RustDesk";
      genericName = "Remote Desktop";
      comment = "Remote desktop client";
      exec = "${rustdesk-current-workspace}/bin/rustdesk-current-workspace %u";
      icon = "rustdesk";
      terminal = false;
      type = "Application";
      categories = [ "Network" "RemoteAccess" "GTK" ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprlandPkg; # Official flake
    # Disable home-manager systemd integration - conflicts with UWSM
    systemd.enable = false;

    # Hyprland plugins from official flake (version-matched)
    plugins = [
      # hyprlandPlugins.hyprexpo  # DISABLED: known SEGV on AMD iGPU (hyprwm/hyprland-plugins#475)
    ];

    settings = {
      "debug:disable_logs" = true; # Wiki default, reduces disk I/O
      "debug:vfr" = true; # Lower compositor frame output when nothing changes

      # === PLUGIN CONFIGURATIONS ===
      # hyprexpo disabled - see plugins list above

      monitor = [
        "HDMI-A-1,1920x1080@60,0x0,1"
        "DP-1,1920x1080@60,0x0,1"
        "eDP-1,1920x1200@60,0x1080,1"
        ",preferred,auto,1"
      ];

      exec-once = [
        # NOTE: uwsm app -- launches processes as systemd units for proper session management
        # This ensures clean shutdown and prevents stale graphical-session.target on crash
        # NOTE: waybar is started by its own systemd user service (auto-restart on SIGSEGV)
        "uwsm app -- ${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent"
        "uwsm app -- mako"
        # swayosd-server managed by systemd (services/swayosd.nix)
        "uwsm app -- hyprpaper"
        "uwsm app -- wl-paste --type text --watch cliphist store"
        "uwsm app -- wl-paste --type image --watch cliphist store"
        "uwsm app -- hyprlauncher -d --quiet" # Start hyprlauncher daemon
        "uwsm app -- hypridle"
        "audio-init" # Initialize ALSA mixer for speakers (one-shot)
        "${bluelight-auto}/bin/bluelight-auto" # Auto-enable blue light filter at night (one-shot, no uwsm needed)
        "${perf-mode-auto}/bin/perf-mode-auto" # Auto-enable performance mode on battery (one-shot)
        "uwsm app -- ${perf-mode-daemon}/bin/perf-mode-daemon" # Monitor power state changes (long-running)
        "uwsm app -- ${youtube-opacity-daemon}/bin/youtube-opacity-daemon" # Smart YouTube PiP opacity
        "uwsm app -- ${twitch-opacity-daemon}/bin/twitch-opacity-daemon" # Smart Twitch PiP opacity
        "sleep 2 && uwsm app -- nm-applet" # Delay tray applet to avoid "no icon" errors
      ];

      # Cursor and GDK settings (system-level has the rest via environment.sessionVariables)
      # Hyprcursor uses XCursor themes as fallback - Bibata works natively
      env = [
        "XCURSOR_THEME,${theme.appearance.cursorTheme}"
        "XCURSOR_SIZE,${toString theme.appearance.cursorSize}"
        "GDK_BACKEND,wayland,x11,*"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
      ];

      input = {
        kb_layout = "fr,us"; # French (default) + US English (switch with SUPER+F3 or Waybar)
        kb_variant = ",";
        numlock_by_default = true;
        repeat_rate = 40; # Slightly slower for comfort
        repeat_delay = 600; # Longer delay before repeat
        follow_mouse = 1;

        touchpad = {
          natural_scroll = true; # Natural scrolling enabled
          disable_while_typing = true;
          tap-to-click = true; # Fixed: use hyphens instead of underscores
          clickfinger_behavior = true;
          scroll_factor = 0.4; # Slower, more precise scrolling
          middle_button_emulation = true;
        };

        sensitivity = 0;
      };

      # Gestures
      gestures = {
        workspace_swipe_distance = 300;
        workspace_swipe_cancel_ratio = 0.5;
        workspace_swipe_min_speed_to_force = 30;
        workspace_swipe_create_new = true;
        workspace_swipe_touch = true; # Enable touchscreen workspace swipe (0.54+)
      };

      # Gesture bindings (new 0.53 syntax) - 3-finger horizontal for workspace switching
      gesture = [
        "3, horizontal, workspace"
      ];

      general = {
        gaps_in = 1;
        gaps_out = 2;
        border_size = 1;
        "col.active_border" = "rgb(${theme.stripHash theme.colors.accent})";
        "col.inactive_border" = "rgb(${theme.stripHash theme.colors.surface})";
        layout = "dwindle";
        resize_on_border = true; # Invisible resize zone on edges
        extend_border_grab_area = 15; # 15px grab area for resizing
        allow_tearing = false;

        # Floating window snap (0.54+) - snap to edges and other windows
        snap = {
          enabled = true;
          window_gap = 8; # Snap gap between floating windows
          monitor_gap = 8; # Snap gap to monitor edges
        };
      };

      decoration = {
        rounding = 4;
        dim_modal = true; # Dim parent windows of modal dialogs (0.54+)
        dim_inactive = true;
        dim_strength = 0.12; # Subtle - just enough to highlight focused window

        blur = {
          enabled = true;
          size = 6;
          passes = 2;
          ignore_opacity = true;
          new_optimizations = true;
          xray = true; # Floating windows ignore tiled in blur (perf)
          special = true; # Blur behind scratchpad
          popups = true; # Blur behind right-click menus
        };

        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
          color = "rgba(0000004D)"; # black 30% opacity
          color_inactive = "rgba(00000026)"; # black 15% opacity
          offset = "0 2";
        };

        # Subtle glow on focused window (0.54+)
        glow = {
          enabled = true;
          range = 8;
          render_power = 3;
          color = "rgba(${theme.stripHash theme.colors.accent}26)"; # accent 15% opacity
          color_inactive = "rgba(00000000)"; # No glow on inactive
        };

        active_opacity = 1.0;
        inactive_opacity = 0.97;
        fullscreen_opacity = 1.0;
      };

      animations = {
        enabled = true; # Fast snappy animations for spatial awareness (auto-disabled on battery by perf-mode-daemon)
        bezier = [
          "fluent_decel, 0.0, 0.2, 0.4, 1.0"
          "easeOutCirc, 0, 0.55, 0.45, 1"
          "easeOutCubic, 0.33, 1, 0.68, 1"
          "easeInOutQuart, 0.76, 0, 0.24, 1"
          "snappy, 0.2, 1.0, 0.3, 1.0"
          "overshot, 0.05, 0.9, 0.1, 1.05" # Slight overshoot for organic feel
        ];

        animation = [
          "windows, 1, 3, snappy, popin 90%"
          "windowsOut, 1, 2, fluent_decel, popin 90%"
          "windowsMove, 1, 2, snappy, slide"
          "fade, 1, 3, easeOutCubic"
          "fadeIn, 1, 2, easeOutCubic"
          "fadeOut, 1, 2, easeOutCubic"
          "fadeSwitch, 1, 2, easeOutCubic" # Smooth opacity transition on focus change
          "fadeDim, 1, 3, easeOutCubic" # Smooth dim transition
          "border, 1, 3, easeOutCubic" # Animate border color on focus change
          "borderangle, 0"
          "workspaces, 1, 3, snappy, slidefade 20%" # Slide + fade for spatial awareness
          "specialWorkspace, 1, 3, easeInOutQuart, slidevert"
          "layers, 1, 2, easeOutCubic, fade" # Smooth layer open/close (waybar popups, etc.)
        ];
      };

      dwindle = {
        preserve_split = true;
        smart_split = false; # Disable auto split direction
        force_split = 2; # Always split to the right (horizontal/landscape)
        split_width_multiplier = 1.5; # Prefer horizontal splits
        precise_mouse_move = true; # Drop windows more precisely with mouse (0.54+)
      };

      master = {
        new_status = "master";
        new_on_top = true;
      };

      # Group (tabbed windows) theming (0.54+ expanded options)
      group = {
        "col.border_active" = "rgb(${theme.stripHash theme.colors.accentSecondary})";
        "col.border_inactive" = "rgb(${theme.stripHash theme.colors.border})";
        groupbar = {
          enabled = true;
          height = 18;
          font_size = 10;
          "col.active" = "rgb(${theme.stripHash theme.colors.accentSecondary})";
          "col.inactive" = "rgb(${theme.stripHash theme.colors.surface})";
          text_color = "rgb(${theme.stripHash theme.colors.foreground})";
          text_color_inactive = "rgb(${theme.stripHash theme.colors.foregroundDim})";
          font_weight_active = "bold";
          font_weight_inactive = "normal";
          text_padding = 4;
          round_only_edges = true;
        };
        drag_into_group = 1; # Allow dragging windows into groups
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_watchdog_warning = true; # Suppress UWSM/start-hyprland warning (NixOS official method)
        disable_autoreload = true; # Avoid live config reloads while nh/nixos-rebuild updates the system
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        vrr = 2; # Variable refresh rate: 0=off, 1=on, 2=fullscreen only
        enable_swallow = true;
        swallow_regex = "^(com.mitchellh.ghostty|Alacritty)$";
        force_default_wallpaper = 0;
        focus_on_activate = false; # Prevent windows from stealing focus
        on_focus_under_fullscreen = 2; # 0=ignore, 1=takeover, 2=unfullscreen
        close_special_on_empty = true; # Close special workspace when empty
        render_unfocused_fps = 15; # Default value - 5 was too aggressive, can trigger GPU ring timeouts on AMD
        enable_anr_dialog = true; # Show "App Not Responding" dialog for frozen apps (0.54+)
        anr_missed_pings = 3; # Trigger ANR after 3 missed pings (faster detection)
        disable_xdg_env_checks = true; # UWSM handles XDG env, suppress warning
      };

      # Cursor settings
      cursor = {
        no_hardware_cursors = 2; # 0=off, 1=on, 2=auto (0.54+). Let Hyprland detect AMD RDNA 3 compatibility
        no_break_fs_vrr = 1; # Force-enable for all fullscreen VRR apps (not just games)
        inactive_timeout = 3; # Hide cursor after 3s of inactivity
        hide_on_key_press = true; # Hide cursor when typing
        hide_on_touch = true; # Hide cursor on touch input
        enable_hyprcursor = false; # Disabled: Bibata is XCursor-only, hyprcursor crashes on fallback
        warp_on_toggle_special = 1; # Warp cursor when toggling special workspace (0.54+)
      };

      # Render optimizations
      render = {
        direct_scanout = 0; # 0=off, 1=on, 2=auto/game (0.54+, was bool). Disabled: crash on AMD (hyprwm/Hyprland#9331)
        new_render_scheduling = true; # Auto triple buffering, improves FPS on underpowered iGPU (Radeon 780M)
      };

      # Suppress ecosystem nag popups (0.54+)
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      # Binds behavior
      binds = {
        movefocus_cycles_groupfirst = true; # Tab through group members before moving to next window
        window_direction_monitor_fallback = true; # Focus next monitor when no window in direction
        hide_special_on_workspace_change = true; # Auto-hide scratchpad when switching workspaces
      };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, ghostty"
        # "$mod, Tab, hyprexpo:expo, toggle"  # DISABLED with hyprexpo plugin
        "$mod, B, exec, brave"
        "$mod, E, exec, nemo"
        "$mod, A, exec, hyprpwcenter" # Audio control (Official Hyprland)
        "$mod, Q, killactive"
        "$mod SHIFT, Q, forcekillactive" # Force kill (for frozen apps)
        "$mod, F, fullscreen, 0"
        "$mod SHIFT, F, fullscreen, 1" # Maximize (fake fullscreen)
        "$mod, Space, togglefloating"
        "$mod, P, pin" # Pin window (stays visible on all workspaces)
        "$mod, T, layoutmsg, togglesplit"
        # Window groups (tabbed windows)
        "$mod, G, togglegroup" # Create/dissolve window group
        "$mod, bracketright, changegroupactive, f" # Next tab in group
        "$mod, bracketleft, changegroupactive, b" # Previous tab in group
        "$mod SHIFT, G, lockactivegroup, toggle" # Lock group (prevent changes)
        "$mod CTRL, bracketright, movegroupwindow, f" # Reorder tab forward in group
        "$mod CTRL, bracketleft, movegroupwindow, b" # Reorder tab backward in group
        # Quick window switching
        "$mod, Tab, focuscurrentorlast" # Toggle between current and last focused window
        "ALT, Tab, cyclenext" # Cycle focus through all windows
        "ALT SHIFT, Tab, cyclenext, prev" # Cycle focus backward
        # Swap window positions (tile swap)
        "$mod CTRL SHIFT, left, swapwindow, l"
        "$mod CTRL SHIFT, right, swapwindow, r"
        "$mod CTRL SHIFT, up, swapwindow, u"
        "$mod CTRL SHIFT, down, swapwindow, d"
        "$mod CTRL SHIFT, H, swapwindow, l"
        "$mod CTRL SHIFT, L, swapwindow, r"
        "$mod CTRL SHIFT, K, swapwindow, u"
        "$mod CTRL SHIFT, J, swapwindow, d"
        # Multi-monitor
        "$mod CTRL, M, movecurrentworkspacetomonitor, +1" # Move workspace to next monitor
        # Center floating window
        "$mod, W, centerwindow"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, K, movefocus, u"
        "$mod, J, movefocus, d"
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"
        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, L, movewindow, r"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, J, movewindow, d"
        # Workspaces - switch
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
        # Workspaces - move window to workspace
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
        # Move window to workspace with arrow keys (easy for AZERTY)
        "$mod ALT, left, movetoworkspace, -1"
        "$mod ALT, right, movetoworkspace, +1"
        "$mod ALT, H, movetoworkspace, -1"
        "$mod ALT, L, movetoworkspace, +1"
        # Special workspace (scratchpad)
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
        # Minimize to special workspace
        "$mod, minus, movetoworkspacesilent, special:minimized"
        "$mod SHIFT, minus, togglespecialworkspace, minimized"
        "$mod, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, V, exec, cliphist wipe"
        # DPMS (monitor power) - must use exec+sleep to avoid undefined behavior (wiki warning)
        "$mod CTRL SHIFT, Escape, exec, sleep 1 && hyprctl dispatch dpms off"
        "$mod, C, exec, hyprpicker -a"
        "$mod, N, exec, ${bluelight-toggle}/bin/bluelight-toggle"
        "$mod SHIFT, N, exec, ${bluelight-off}/bin/bluelight-off"
        "$mod, M, exec, ${battery-mode}/bin/battery-mode"
        "$mod SHIFT, M, exec, ${perf-mode}/bin/perf-mode"
        "$mod SHIFT, T, exec, ${touchpad-toggle}/bin/touchpad-toggle" # Toggle trackpad
        "$mod, Y, exec, ${youtube-toggle}/bin/youtube-toggle" # Toggle YouTube PiP (launch/show/hide)
        "$mod, U, exec, ${twitch-toggle}/bin/twitch-toggle" # Toggle Twitch PiP (launch/show/hide)
        "$mod, O, exec, ${quick-notes}/bin/quick-notes" # Quick note-taking
        "$mod, X, exec, lab-menu" # Malware analysis lab menu (FLARE-VM + REMnux)
        "$mod, I, exec, hyprsysteminfo" # System info (official Hyprland)
        "$mod SHIFT, I, exec, ${sysinfo-panel}/bin/sysinfo-panel" # Detailed system info panel
        "$mod, Z, exec, hyprfreeze -a" # Freeze/unfreeze focused window (SIGSTOP/SIGCONT)
        "$mod SHIFT, C, exec, hyprprop" # Inspect window properties (click to select)
        # Screenshots via grimblast (official hyprwm/contrib)
        ", Print, exec, grimblast --freeze copy area" # Region → clipboard
        "$mod, Print, exec, grimblast --freeze save area $SCREENSHOT_DIR/$(date +%Y%m%d_%H%M%S).png" # Region → file
        "SHIFT, Print, exec, grimblast --freeze copy output" # Full screen → clipboard
        "$mod SHIFT, Print, exec, grimblast --freeze save output $SCREENSHOT_DIR/$(date +%Y%m%d_%H%M%S).png" # Full screen → file
        "$mod CTRL, Print, exec, grimblast --freeze copy active" # Window → clipboard
        # Keyboard layout switch (fr ↔ us)
        "$mod, F3, exec, hyprctl switchxkblayout at-translated-set-2-keyboard next"
        # WiFi management
        "$mod, F2, exec, ${wifi-manage}/bin/wifi-manage reconnect" # Reconnect WiFi
        "$mod SHIFT, F2, exec, ${wifi-manage}/bin/wifi-manage scan" # Scan & connect to network
        "$mod CTRL, F2, exec, ${wifi-manage}/bin/wifi-manage toggle" # Toggle WiFi on/off
        # Waybar (restart via systemd user service, not killall)
        "$mod SHIFT, R, exec, systemctl --user restart waybar.service"
        # Focus workspace on current monitor (useful for multi-monitor, 0.54+)
        "$mod CTRL, 1, focusworkspaceoncurrentmonitor, 1"
        "$mod CTRL, 2, focusworkspaceoncurrentmonitor, 2"
        "$mod CTRL, 3, focusworkspaceoncurrentmonitor, 3"
        "$mod CTRL, 4, focusworkspaceoncurrentmonitor, 4"
        "$mod CTRL, 5, focusworkspaceoncurrentmonitor, 5"
        # Swap workspaces between monitors (multi-monitor)
        "$mod SHIFT, Tab, swapactiveworkspaces, eDP-1 HDMI-A-1"
      ];

      # Bypass app shortcut inhibition for escape/system keys, especially
      # fullscreen Steam games.
      bindp = [
        "$mod, D, exec, hyprlauncher --quiet" # Toggle hyprlauncher (instant with daemon)
        # System controls
        "$mod, Escape, exec, hyprlock"
        # Graceful shutdown via hyprshutdown (official Hyprland tool)
        # Asks apps to close gracefully, then quits Hyprland, then runs post-cmd
        "$mod SHIFT, Escape, exec, hyprshutdown -t 'Shutting down...' --post-cmd 'systemctl poweroff'"
        "$mod CTRL, Escape, exec, hyprshutdown -t 'Restarting...' --post-cmd 'systemctl reboot'"
        "$mod ALT, Escape, exec, systemctl suspend" # Suspend to RAM (no need to stop session)
        "$mod, F1, exec, ${hypr-keys}/bin/hypr-keys" # Show keybindings cheatsheet (SUPER+F1)
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Window resize (binde = repeat when held)
      binde = [
        "$mod CTRL, left, resizeactive, -40 0"
        "$mod CTRL, right, resizeactive, 40 0"
        "$mod CTRL, up, resizeactive, 0 -40"
        "$mod CTRL, down, resizeactive, 0 40"
        "$mod CTRL, H, resizeactive, -40 0"
        "$mod CTRL, L, resizeactive, 40 0"
        "$mod CTRL, K, resizeactive, 0 -40"
        "$mod CTRL, J, resizeactive, 0 40"
      ];

      # Audio/Brightness controls using SwayOSD (native OSD)
      bindl = [
        ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        # Media controls
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"
      ];

      bindle = [
        ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];

      # Window rules - Hyprland 0.53+ new syntax
      windowrule = [
        # === GENERIC RULES ===
        "suppress_event maximize, match:class .*"

        # === FLOAT WINDOWS ===
        # System tools & dialogs
        "float on, match:class ^(hyprpwcenter)$"
        "float on, match:class ^(hyprsysteminfo)$"
        "float on, match:class ^(hyprpolkitagent)$"
        "float on, match:class ^(nm-connection-editor)$"
        "float on, match:class ^(blueman-manager)$"
        "float on, match:class ^(pavucontrol)$"
        "float on, match:class ^(org.gnome.Calculator)$"
        "float on, match:class ^(file-roller)$"
        "float on, match:class ^(xdg-desktop-portal-gtk)$"
        "float on, match:class ^(org.gnome.FileRoller)$"
        "float on, match:class ^(gparted|GParted|gpartedbin)$"
        "float on, match:class ^(com\\.system76\\.Popsicle|popsicle-gtk)$"
        "float on, match:class ^(nwg-displays)$"
        "float on, match:class ^(com\\.gabm\\.satty|satty)$"
        "float on, match:class ^(confirm)$"
        "float on, match:class ^(dialog)$"
        "float on, match:class ^(download)$"
        "float on, match:class ^(notification)$"
        "float on, match:class ^(error)$"
        "float on, match:class ^(splash)$"
        "float on, match:title ^(Open File)$"
        "float on, match:title ^(Save File)$"
        "float on, match:title ^(Open Folder)$"
        "float on, match:title ^(Confirm)$"
        "float on, match:title ^(File Operation Progress)$"
        "center on, match:class ^(gparted|GParted|gpartedbin|com\\.system76\\.Popsicle|popsicle-gtk|nwg-displays|com\\.gabm\\.satty|satty)$"

        # === OPACITY RULES ===
        # Terminals handle background alpha themselves so text stays fully opaque.
        "opacity 1.0 override 1.0 override, match:class ^(com.mitchellh.ghostty)$"
        "opacity 1.0 override 1.0 override, match:class ^(Alacritty)$"

        # File managers - slight transparency
        "opacity 0.95, match:class ^(thunar)$"
        "opacity 0.95, match:class ^(nemo)$"

        # Browsers - full opacity (important for video)
        "tile on, match:class ^(brave-browser|Brave-browser)$"
        "opacity 1.0 override, match:class ^(brave-browser|Brave-browser)$"
        "opacity 1.0 override, match:class ^(firefox)$"
        "opacity 1.0 override, match:class ^(chromium)$"

        # Media content - full opacity
        "opacity 1.0 override, match:title .*(YouTube|Netflix|Twitch|Zoom|Meet|Discord).*"

        # IDEs - full opacity
        "opacity 1.0 override, match:class ^(code-url-handler)$"
        "opacity 1.0 override, match:class ^(code|Code)$"
        "opacity 1.0 override, match:class ^(jetbrains-.*)$"

        # Messaging and single-instance productivity apps - keep text/QR codes fully opaque
        "opacity 1.0 override, match:class ^(com\\.rtosta\\.zapzap|vesktop|Vesktop|telegram-desktop|org\\.telegram\\.desktop|TelegramDesktop|Telegram|spotify|Spotify|joplin|Joplin|@joplin/app-desktop|bruno|Bruno)$"

        # Creative/document apps - avoid transparency while editing or reading
        "opacity 1.0 override, match:class ^(Gimp|gimp|gimp-3\\.0|org\\.gimp\\.GIMP|org\\.inkscape\\.Inkscape|Inkscape|Blender|blender|com\\.obsproject\\.Studio|obs|Audacity|com\\.github\\.xournalpp\\.xournalpp|org\\.pwmt\\.zathura|libreoffice|soffice|Soffice|org\\.kde\\.kdenlive|kdenlive|flowblade|swayimg)$"

        # Password manager - keep opaque and hide from screen shares
        "opacity 1.0 override, match:class ^(org\\.keepassxc\\.KeePassXC|keepassxc|KeePassXC)$"
        "no_screen_share on, match:class ^(org\\.keepassxc\\.KeePassXC|keepassxc|KeePassXC)$"

        # Steam - avoid focus/input edge cases and classify games correctly
        "opacity 1.0 override, match:class ^(steam|Steam)$"
        "allows_input on, match:class ^(steam|Steam)$"
        "no_shortcuts_inhibit on, match:class ^(steam|Steam)$"
        "stay_focused on, match:class ^(steam|Steam)$, match:title ^$"
        "min_size 1 1, match:class ^(steam|Steam)$, match:title ^$"
        "content game, match:class ^(steam_app_.*)$"
        "no_shortcuts_inhibit on, match:class ^(steam_app_.*)$"
        "opaque on, match:class ^(steam_app_.*)$"
        "force_rgbx on, match:class ^(steam_app_.*)$"
        "content game, match:class ^(gamescope)$"
        "no_shortcuts_inhibit on, match:class ^(gamescope)$"

        # Native/Linux legacy games sometimes expose the engine binary as the
        # class instead of steam_app_*. Keep compositor optimizations, but let
        # the game's own video mode decide whether it is fullscreen or windowed.
        "float on, match:class ^(hl_linux|hl2_linux)$"
        "center on, match:class ^(hl_linux|hl2_linux)$"
        "content game, match:class ^(hl_linux|hl2_linux)$"
        "no_shortcuts_inhibit on, match:class ^(hl_linux|hl2_linux)$"
        "opaque on, match:class ^(hl_linux|hl2_linux)$"
        "force_rgbx on, match:class ^(hl_linux|hl2_linux)$"
        "allows_input on, match:class ^(hl_linux|hl2_linux)$"
        "no_blur on, match:class ^(hl_linux|hl2_linux)$"
        "no_shadow on, match:class ^(hl_linux|hl2_linux)$"
        "no_dim on, match:class ^(hl_linux|hl2_linux)$"
        "no_anim on, match:class ^(hl_linux|hl2_linux)$"
        "rounding 0, match:class ^(hl_linux|hl2_linux)$"
        "border_size 0, match:class ^(hl_linux|hl2_linux)$"
        "idle_inhibit focus, match:class ^(hl_linux|hl2_linux)$"

        # === SPECIAL WINDOWS ===
        # Picture-in-Picture
        "float on, match:title ^(Picture-in-Picture)$"
        "pin on, match:title ^(Picture-in-Picture)$"
        "size 640 360, match:title ^(Picture-in-Picture)$"
        "move 100%-650 100%-370, match:title ^(Picture-in-Picture)$"
        "opacity 1.0 override, match:title ^(Picture-in-Picture)$"

        # YouTube webapp - floating PiP style
        # Smart opacity: transparent when focused window is underneath, opaque otherwise
        # Managed by youtube-opacity-daemon (IPC events)
        # SUPER+Y = toggle show/hide entirely
        "float on, match:class ^(brave-youtube\\.com__-Default)$"
        "pin on, match:class ^(brave-youtube\\.com__-Default)$"
        "size (monitor_w*0.5-5) ((monitor_h-32)*0.5-5), match:class ^(brave-youtube\\.com__-Default)$"
        "move (monitor_w*0.5+2) (32+((monitor_h-32)*0.5)+2), match:class ^(brave-youtube\\.com__-Default)$"
        "opacity 1.0 override 1.0 override, match:class ^(brave-youtube\\.com__-Default)$"
        "render_unfocused on, match:class ^(brave-youtube\\.com__-Default)$"
        "content video, match:class ^(brave-youtube\\.com__-Default)$"
        "no_initial_focus on, match:class ^(brave-youtube\\.com__-Default)$"
        "no_blur on, match:class ^(brave-youtube\\.com__-Default)$"

        # Twitch webapp - floating PiP style (mirror of YouTube, bottom-left)
        # Managed by twitch-opacity-daemon (IPC events)
        # SUPER+U = toggle show/hide entirely
        "float on, match:class ^(brave-twitch\\.tv__-Default)$"
        "pin on, match:class ^(brave-twitch\\.tv__-Default)$"
        "size 960 540, match:class ^(brave-twitch\\.tv__-Default)$"
        "move 10 100%-550, match:class ^(brave-twitch\\.tv__-Default)$"
        "opacity 1.0 override 0.85, match:class ^(brave-twitch\\.tv__-Default)$"
        "render_unfocused on, match:class ^(brave-twitch\\.tv__-Default)$"
        "content video, match:class ^(brave-twitch\\.tv__-Default)$"
        "no_initial_focus on, match:class ^(brave-twitch\\.tv__-Default)$"
        "no_blur on, match:class ^(brave-twitch\\.tv__-Default)$"

        # Hyprlauncher
        "float on, match:class ^(hyprlauncher)$"
        "center on, match:class ^(hyprlauncher)$"
        "stay_focused on, match:class ^(hyprlauncher)$"

        # Quick notes - floating centered window
        "float on, match:class ^(quick-notes)$"
        "size 800 600, match:class ^(quick-notes)$"
        "center on, match:class ^(quick-notes)$"

        # Prevent idle when watching video
        "idle_inhibit fullscreen, match:class .*"
        "idle_inhibit focus, match:class ^(vlc)$"

        # Keep rendering when unfocused (prevents stream/video stutter, 0.54+)
        "render_unfocused on, match:class ^(vlc)$"
        "render_unfocused on, match:class ^(mpv)$"
        "render_unfocused on, match:title .*(YouTube|Netflix|Twitch).*"

        # Dim background when polkit/auth dialogs appear
        "dim_around on, match:class ^(hyprpolkitagent)$"
        "dim_around on, match:class ^(org.kde.polkit-kde-authentication-agent-1)$"

        # Tag windows for easy batch operations (0.54+)
        "tag +media, match:class ^(vlc|mpv|spotify)$"
        "tag +browser, match:class ^(brave-browser|Brave-browser|firefox|chromium)$"
        "tag +code, match:class ^(code|Code|code-url-handler|jetbrains-.*)$"
        "tag +terminal, match:class ^(com.mitchellh.ghostty|Alacritty)$"
        "tag +messaging, match:class ^(com\\.rtosta\\.zapzap|vesktop|Vesktop|telegram-desktop|org\\.telegram\\.desktop|TelegramDesktop|Telegram)$"
        "tag +creative, match:class ^(Gimp|gimp|org\\.inkscape\\.Inkscape|Inkscape|Blender|blender|com\\.obsproject\\.Studio|obs|Audacity|org\\.kde\\.kdenlive|kdenlive|flowblade)$"
        "tag +documents, match:class ^(libreoffice|soffice|Soffice|com\\.github\\.xournalpp\\.xournalpp|org\\.pwmt\\.zathura|joplin|Joplin|@joplin/app-desktop)$"
        "tag +security, match:class ^(org\\.keepassxc\\.KeePassXC|keepassxc|KeePassXC|Bruno|bruno|org\\.wireshark\\.Wireshark|wireshark|Ghidra|ghidra)$"
        "tag +gaming, match:class ^(steam|Steam|steam_app_.*|hl_linux|hl2_linux)$"
      ];

    };

  };

  # Hyprland-specific packages (core Wayland tools are in system/hyprland.nix)
  home.packages = with pkgs; [
    # ── Hypr ecosystem ──
    hyprpaper # Wallpaper daemon
    inputs.hyprshutdown.packages.${pkgs.stdenv.hostPlatform.system}.default # Graceful shutdown GUI
    hypridle # Idle daemon
    hyprlock # Screen locker
    hyprcursor # Native Hyprland cursor library
    hyprsunset # Blue light filter
    hyprsysteminfo # System info display (GPU, CPU, Hyprland version)
    hyprfreeze # Freeze window (SIGSTOP) — pause/resume resource-heavy apps
    grimblast # Screenshots (region, window, output) — official hyprwm/contrib
    hyprprop # Window property inspector (click to inspect, like xprop)
    hyprmagnifier # Screen magnifier/zoom (accessibility)
    hyprmon # TUI monitor configuration (native, replaces nwg-displays)
    # ── Wayland tools ──
    cliphist # Clipboard history manager
    brightnessctl # Brightness control (for hypridle dim)
    wofi # dmenu-like picker for clipboard history
    # ── Custom scripts ──
    bluelight-toggle # Blue light cycle (SUPER+N)
    bluelight-off # Blue light off (SUPER+SHIFT+N)
    bluelight-auto # Auto-enable at night (boot)
    battery-mode # Battery charge mode (SUPER+M)
    perf-mode # Performance mode (SUPER+SHIFT+M)
    touchpad-toggle # Toggle trackpad (SUPER+SHIFT+T)
    hypr-current-workspace-launch # Shared launcher: focus existing app on current workspace
    zapzap-current-workspace # ZapZap launcher that stays on the active workspace
    steam-current-workspace # Steam launcher that stays on the active workspace
    vesktop-current-workspace # Vesktop launcher that stays on the active workspace
    spotify-current-workspace # Spotify launcher that stays on the active workspace
    telegram-current-workspace # Telegram launcher that stays on the active workspace
    keepassxc-current-workspace # KeePassXC launcher that stays on the active workspace
    joplin-current-workspace # Joplin launcher that stays on the active workspace
    bruno-current-workspace # Bruno launcher that stays on the active workspace
    rustdesk-current-workspace # RustDesk launcher that stays on the active workspace
    perf-mode-auto # Auto battery saver (boot)
    perf-mode-daemon # Monitor power state changes
    wifi-manage # WiFi management (SUPER+F2)
    youtube-toggle # YouTube PiP toggle (SUPER+Y)
    youtube-pip-dock-toggle # YouTube attach/detach from explicit controls
    youtube-pip-toggle # YouTube attach/detach from waybar (double-click mpris)
    youtube-opacity-daemon # Smart YouTube PiP opacity (IPC daemon)
    twitch-toggle # Twitch PiP toggle (SUPER+U)
    twitch-pip-dock-toggle # Twitch attach/detach from explicit controls
    twitch-opacity-daemon # Smart Twitch PiP opacity (IPC daemon)
    quick-notes # Quick note-taking (SUPER+O)
    sysinfo-panel # System info panel (SUPER+I)
    hypr-keys # Keybindings cheatsheet (SUPER+F1)
  ];
}
