# Window rules (Hyprland 0.55+ Lua format).
{ ... }:

{
  xdg.configFile."hypr/window-rules.lua".text = ''
    --------------------------------------------------------------------------
    -- Generic
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

    --------------------------------------------------------------------------
    -- Float: system tools & dialogs
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = "^(hyprpwcenter)$" },                                    float = true })
    hl.window_rule({ match = { class = "^(hyprsysteminfo)$" },                                  float = true })
    hl.window_rule({ match = { class = "^(hyprpolkitagent)$" },                                 float = true })
    hl.window_rule({ match = { class = "^(nm-connection-editor)$" },                            float = true })
    hl.window_rule({ match = { class = "^(blueman-manager)$" },                                 float = true })
    hl.window_rule({ match = { class = "^(pavucontrol)$" },                                     float = true })
    hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" },                            float = true })
    hl.window_rule({ match = { class = "^(file-roller)$" },                                     float = true })
    hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" },                          float = true })
    hl.window_rule({ match = { class = "^(org.gnome.FileRoller)$" },                            float = true })
    hl.window_rule({ match = { class = "^(gparted|GParted|gpartedbin)$" },                      float = true })
    hl.window_rule({ match = { class = "^(com\\.system76\\.Popsicle|popsicle-gtk)$" },          float = true })
    hl.window_rule({ match = { class = "^(nwg-displays)$" },                                    float = true })
    hl.window_rule({ match = { class = "^(com\\.gabm\\.satty|satty)$" },                        float = true })
    hl.window_rule({ match = { class = "^(confirm)$" },                                         float = true })
    hl.window_rule({ match = { class = "^(dialog)$" },                                          float = true })
    hl.window_rule({ match = { class = "^(download)$" },                                        float = true })
    hl.window_rule({ match = { class = "^(notification)$" },                                    float = true })
    hl.window_rule({ match = { class = "^(error)$" },                                           float = true })
    hl.window_rule({ match = { class = "^(splash)$" },                                          float = true })
    hl.window_rule({ match = { title = "^(Open File)$" },                                       float = true })
    hl.window_rule({ match = { title = "^(Save File)$" },                                       float = true })
    hl.window_rule({ match = { title = "^(Open Folder)$" },                                     float = true })
    hl.window_rule({ match = { title = "^(Confirm)$" },                                         float = true })
    hl.window_rule({ match = { title = "^(File Operation Progress)$" },                         float = true })
    hl.window_rule({ match = { class = "^(gparted|GParted|gpartedbin|com\\.system76\\.Popsicle|popsicle-gtk|nwg-displays|com\\.gabm\\.satty|satty)$" }, center = true })

    --------------------------------------------------------------------------
    -- Opacity
    -- Global inactive_opacity is 1.0 (look-feel.nix), so windows are opaque by
    -- default and only deliberate transparency needs a rule here.
    --------------------------------------------------------------------------
    -- File managers - slight transparency
    hl.window_rule({ match = { class = "^(thunar)$" }, opacity = "0.95" })
    hl.window_rule({ match = { class = "^(nemo)$" },   opacity = "0.95" })

    hl.window_rule({ match = { class = "^(brave-browser|Brave-browser)$" }, tile = true })

    -- Password manager - hide from screen shares
    hl.window_rule({ match = { class = "^(org\\.keepassxc\\.KeePassXC|keepassxc|KeePassXC)$" }, no_screen_share = true })

    --------------------------------------------------------------------------
    -- Gamescope micro-compositor (games launched through gamescope)
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = "^(gamescope)$" }, content = "game" })
    hl.window_rule({ match = { class = "^(gamescope)$" }, no_shortcuts_inhibit = true })

    --------------------------------------------------------------------------
    -- Picture-in-Picture
    --------------------------------------------------------------------------
    hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })
    hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true })
    hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, size = {640, 360} })
    hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = {"100%-650", "100%-370"} })
    hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = "1.0 override" })

    --------------------------------------------------------------------------
    -- YouTube webapp - floating PiP (top-right quadrant), opacity by daemon,
    -- SUPER+Y toggles show/hide
    --------------------------------------------------------------------------
    local ytClass = { class = "^(brave-youtube\\.com__-Default)$" }
    hl.window_rule({ match = ytClass, float = true })
    hl.window_rule({ match = ytClass, pin = true })
    hl.window_rule({ match = ytClass, size = {"monitor_w*0.5-5", "(monitor_h-32)*0.5-5"} })
    hl.window_rule({ match = ytClass, move = {"monitor_w*0.5+2", "32+((monitor_h-32)*0.5)+2"} })
    hl.window_rule({ match = ytClass, opacity = "1.0 override 1.0 override" })
    hl.window_rule({ match = ytClass, render_unfocused = true })
    hl.window_rule({ match = ytClass, content = "video" })
    hl.window_rule({ match = ytClass, no_initial_focus = true })
    hl.window_rule({ match = ytClass, no_blur = true })

    --------------------------------------------------------------------------
    -- Twitch webapp - floating PiP (bottom-left, mirror of YouTube)
    --------------------------------------------------------------------------
    local twClass = { class = "^(brave-twitch\\.tv__-Default)$" }
    hl.window_rule({ match = twClass, float = true })
    hl.window_rule({ match = twClass, pin = true })
    hl.window_rule({ match = twClass, size = {960, 540} })
    hl.window_rule({ match = twClass, move = {10, "100%-550"} })
    hl.window_rule({ match = twClass, opacity = "1.0 override 0.85" })
    hl.window_rule({ match = twClass, render_unfocused = true })
    hl.window_rule({ match = twClass, content = "video" })
    hl.window_rule({ match = twClass, no_initial_focus = true })
    hl.window_rule({ match = twClass, no_blur = true })

    --------------------------------------------------------------------------
    -- Hyprlauncher
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = "^(hyprlauncher)$" }, float = true })
    hl.window_rule({ match = { class = "^(hyprlauncher)$" }, center = true })
    hl.window_rule({ match = { class = "^(hyprlauncher)$" }, stay_focused = true })

    --------------------------------------------------------------------------
    -- Quick notes - floating centered
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = "^(quick-notes)$" }, float = true })
    hl.window_rule({ match = { class = "^(quick-notes)$" }, size = {800, 600} })
    hl.window_rule({ match = { class = "^(quick-notes)$" }, center = true })

    --------------------------------------------------------------------------
    -- Idle inhibit / unfocused rendering for video apps
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = ".*" },                                       idle_inhibit = "fullscreen" })
    hl.window_rule({ match = { class = "^(vlc)$" },                                   idle_inhibit = "focus" })
    hl.window_rule({ match = { class = "^(vlc)$" },                                   render_unfocused = true })
    hl.window_rule({ match = { class = "^(mpv)$" },                                   render_unfocused = true })
    -- No title-based render_unfocused rule: ".*(YouTube|Netflix|Twitch).*"
    -- matched every browser window with such a tab, keeping it rendering at
    -- render_unfocused_fps on hidden workspaces (battery cost). The PiP
    -- webapp class rules above already cover the intended windows.

    --------------------------------------------------------------------------
    -- Dim background around polkit/auth dialogs
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = "^(hyprpolkitagent)$" },                                dim_around = true })
    hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },      dim_around = true })

    --------------------------------------------------------------------------
    -- Tag windows for batch operations (0.54+)
    --------------------------------------------------------------------------
    hl.window_rule({ match = { class = "^(vlc|mpv|spotify)$" },                                            tag = "+media" })
    hl.window_rule({ match = { class = "^(brave-browser|Brave-browser|firefox|chromium)$" },               tag = "+browser" })
    hl.window_rule({ match = { class = "^(code|Code|code-url-handler|jetbrains-.*)$" },                    tag = "+code" })
    hl.window_rule({ match = { class = "^(com.mitchellh.ghostty|Alacritty)$" },                            tag = "+terminal" })
    hl.window_rule({
      match = { class = "^(ferdium|Ferdium|vesktop|Vesktop|telegram-desktop|org\\.telegram\\.desktop|TelegramDesktop|Telegram)$" },
      tag = "+messaging",
    })
    hl.window_rule({
      match = { class = "^(Gimp|gimp|org\\.inkscape\\.Inkscape|Inkscape|Blender|blender|com\\.obsproject\\.Studio|obs|Audacity|org\\.kde\\.kdenlive|kdenlive|flowblade)$" },
      tag = "+creative",
    })
    hl.window_rule({
      match = { class = "^(libreoffice|soffice|Soffice|com\\.github\\.xournalpp\\.xournalpp|org\\.pwmt\\.zathura|joplin|Joplin|@joplin/app-desktop)$" },
      tag = "+documents",
    })
    hl.window_rule({
      match = { class = "^(org\\.keepassxc\\.KeePassXC|keepassxc|KeePassXC|Bruno|bruno|org\\.wireshark\\.Wireshark|wireshark|Ghidra|ghidra)$" },
      tag = "+security",
    })
    hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+gaming" })

    --------------------------------------------------------------------------
    -- Layer rules: backdrop blur for transparent Wayland layer surfaces.
    -- No-op if the namespace doesn't match. Inspect live names with
    -- `hyprctl layers` if a target doesn't take effect.
    --------------------------------------------------------------------------
    hl.layer_rule({ match = { namespace = "^(waybar)$" },        blur = true })
    hl.layer_rule({ match = { namespace = "^(wofi)$" },          blur = true })
    hl.layer_rule({ match = { namespace = "^(hyprlauncher)$" },  blur = true })
    hl.layer_rule({ match = { namespace = "^(swayosd)$" },       blur = true })
  '';
}
