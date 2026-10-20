# Single source for the Hyprland keybinding documentation. Rendered three
# ways: the `keys` terminal cheatsheet (keys.nix), the Super+F1 notification
# (hypr-keys in scripts.nix) and the hyprlock lock-screen labels
# (lib/theme-configs.nix, binds marked `lock = true`). The binds themselves
# live in keybinds.nix; keep the two in sync when adding or changing a bind.
{ lib }:

let
  sections = [
    {
      title = "APPS";
      binds = [
        { keys = "Super+Enter"; desc = "Terminal (Ghostty)"; lock = true; }
        { keys = "Super+B"; desc = "Browser (Brave)"; lock = true; }
        { keys = "Super+E"; desc = "File manager (Nemo)"; lock = true; }
        { keys = "Super+D"; desc = "Launcher (Vicinae: apps, calc, emoji, windows)"; lock = true; }
        { keys = "Super+A"; desc = "Audio control panel"; }
        { keys = "Super+Y"; desc = "YouTube PiP (toggle show/hide)"; }
        { keys = "Super+U"; desc = "Twitch PiP (toggle show/hide)"; }
        { keys = "Super+R"; desc = "XFeed panel (toggle show/hide)"; }
        { keys = "2xClick media"; desc = "Dock/undock PiP on waybar (YT/Twitch)"; }
        { keys = "Super+O"; desc = "Quick notes"; }
        { keys = "Copilot key"; desc = "Voice: speak; instructions run, text is typed"; }
        { keys = "Super+I"; desc = "System info panel"; }
        { keys = "Super+Shift+I"; desc = "Detailed system info"; }
        { keys = "Super+X"; desc = "Malware lab menu (FLARE-VM + REMnux)"; }
        { keys = "Super+Z"; desc = "Freeze/unfreeze focused app"; }
        { keys = "Super+F1"; desc = "Keybindings cheatsheet"; }
      ];
      notes = [
        "Lab menu: start/stop/revert VMs, killswitch, snapshots"
        "Right Super alone also toggles voice dictation (external keyboards)"
      ];
    }
    {
      title = "WINDOWS";
      binds = [
        { keys = "Super+Q"; desc = "Close window"; lock = true; }
        { keys = "Super+Shift+Q"; desc = "Force kill window"; }
        { keys = "Super+F"; desc = "Fullscreen"; lock = true; }
        { keys = "Super+Shift+F"; desc = "Fullscreen (keep bar)"; }
        { keys = "Super+Space"; desc = "Toggle floating"; lock = true; }
        { keys = "Super+P"; desc = "Pin (all workspaces)"; }
        { keys = "Super+W"; desc = "Center floating window"; }
        { keys = "Super+T"; desc = "Toggle split (H/V)"; }
        { keys = "Super+Tab"; desc = "Last focused window"; }
        { keys = "Alt+Tab"; desc = "Next window"; }
        { keys = "Alt+Shift+Tab"; desc = "Previous window"; }
        { keys = "Super+H/J/K/L"; desc = "Move focus"; lock = true; }
        { keys = "Super+Shift+HJKL"; desc = "Move window"; }
        { keys = "Super+Ctrl+HJKL"; desc = "Resize window (40px)"; }
        { keys = "Super+Ctrl+Shift+HJKL"; desc = "Swap tiled windows"; }
        { keys = "Super+Mouse L"; desc = "Move window (drag)"; }
        { keys = "Super+Mouse R"; desc = "Resize window (drag)"; }
      ];
      notes = [
        "Floating windows snap to edges/other windows"
        "Touchpad: 3 fingers left/right = workspace, down = scratchpad, up = float"
        "Nemo: Space = Quick Look preview"
      ];
    }
    {
      title = "GROUPS (TABS)";
      binds = [
        { keys = "Super+G"; desc = "Toggle group"; }
        { keys = "Super+Shift+G"; desc = "Lock group"; }
        { keys = "Super+[ / ]"; desc = "Prev/next tab in group"; }
        { keys = "Super+Ctrl+[ / ]"; desc = "Reorder tab in group"; }
      ];
      notes = [ "Drag windows into groups to tab them" ];
    }
    {
      title = "WORKSPACES";
      binds = [
        { keys = "Super+1-9/0"; desc = "Workspace 1-10"; lock = true; }
        { keys = "Super+Shift+1-9/0"; desc = "Move window to WS 1-10"; }
        { keys = "Super+Ctrl+1-6"; desc = "Focus WS on current monitor"; }
        { keys = "Super+Shift+Tab"; desc = "Swap workspaces between monitors"; }
        { keys = "Super+Ctrl+M"; desc = "Move current WS to next monitor"; }
        { keys = "Super+Shift+P"; desc = "Toggle laptop screen (eDP-1)"; }
        { keys = "Super+Scroll"; desc = "Cycle existing workspaces"; }
        { keys = "Super+Alt+H/L"; desc = "Move window to prev/next WS"; }
        { keys = "Super+S"; desc = "Special workspace"; lock = true; }
        { keys = "Super+Shift+S"; desc = "Move to special WS"; }
        { keys = "Super+minus"; desc = "Minimize to special"; }
        { keys = "Super+Shift+minus"; desc = "Show minimized"; }
        { keys = "3-finger swipe"; desc = "Switch workspace (touchpad+touch)"; }
      ];
    }
    {
      title = "UTILS";
      binds = [
        { keys = "Super+V"; desc = "Clipboard history (Vicinae, images too)"; lock = true; }
        { keys = "Super+Shift+V"; desc = "Clear clipboard"; }
        { keys = "Super+C"; desc = "Color picker"; }
        { keys = "Super+N"; desc = "Blue light filter (cycle 8 levels)"; lock = true; dynamic = "$BL_ICON"; }
        { keys = "Super+Shift+N"; desc = "Blue light off"; }
        { keys = "Super+M"; desc = "Battery mode (55-60/95-100%)"; lock = true; dynamic = "$BAT_ICON"; }
        { keys = "Super+Shift+M"; desc = "Performance mode (battery/balanced/max)"; dynamic = "$PERF_ICON $PERF_STATE"; }
        { keys = "Super+Shift+T"; desc = "Toggle touchpad"; }
        { keys = "Super+Shift+C"; desc = "Window inspector (hyprprop)"; }
        { keys = "Super+Shift+R"; desc = "Restart Waybar"; }
        { keys = "Super+Shift+D"; desc = "Do Not Disturb toggle (critical still shows)"; }
        { keys = "Super+Ctrl+D"; desc = "Do Not Disturb for 60 min"; }
        { keys = "Super+Alt+R"; desc = "Resize mode (HJKL/arrows, Esc exits)"; }
        { keys = "Super+Alt+T"; desc = "Jump to window by tag (B/C/T/M/V/A/D/S/G)"; }
      ];
      notes = [ "Waybar bell: left invoke, middle restore last, right dismiss all" ];
    }
    {
      title = "SCREENSHOTS";
      binds = [
        { keys = "Print"; desc = "Region -> clipboard"; lock = true; }
        { keys = "Super+Print"; desc = "Region -> annotate (satty) -> file + clipboard"; }
        { keys = "Shift+Print"; desc = "Full screen -> clipboard"; }
        { keys = "Super+Shift+Print"; desc = "Full screen -> file"; }
        { keys = "Super+Ctrl+Print"; desc = "Active window -> clipboard"; }
      ];
    }
    {
      title = "SYSTEM";
      binds = [
        { keys = "Super+Esc"; desc = "Lock screen"; lock = true; }
        { keys = "Super+Shift+Esc"; desc = "Power off"; }
        { keys = "Super+Ctrl+Esc"; desc = "Reboot"; }
        { keys = "Super+Alt+Esc"; desc = "Suspend to RAM"; }
        { keys = "Super+Ctrl+Shift+Esc"; desc = "Monitors off"; }
      ];
    }
    {
      title = "KEYBOARD";
      binds = [
        { keys = "Super+F3"; desc = "Switch layout (FR <-> US)"; }
      ];
      notes = [ "Waybar: click language indicator" ];
    }
    {
      title = "WIFI";
      binds = [
        { keys = "Super+F2"; desc = "Reconnect WiFi"; }
        { keys = "Super+Shift+F2"; desc = "Scan & connect (wofi menu)"; }
        { keys = "Super+Ctrl+F2"; desc = "Toggle WiFi on/off"; }
        { keys = "captive-on"; desc = "Bypass DNS (portals)"; }
        { keys = "captive-off"; desc = "Restore secure DNS"; }
      ];
    }
    {
      title = "MEDIA";
      binds = [
        { keys = "Volume keys"; desc = "Volume up/down/mute (SwayOSD)"; }
        { keys = "Brightness keys"; desc = "Brightness up/down (SwayOSD)"; }
        { keys = "Play/Pause"; desc = "Media play/pause"; }
        { keys = "Next/Prev"; desc = "Media next/prev"; }
        { keys = "Stop"; desc = "Media stop"; }
        { keys = "Mic Mute"; desc = "Microphone toggle"; }
      ];
    }
  ];

  keyColumn = 16;
  padRight = s: s + lib.concatStrings (lib.replicate (lib.max 1 (keyColumn - lib.stringLength s)) " ");

  bindLine = bind: "${padRight bind.keys}${bind.desc}";

  sectionText = section: lib.concatStringsSep "\n" (
    [ "━━━━━━━━━━━━ ${section.title} ━━━━━━━━━━━━" ]
    ++ map bindLine section.binds
    ++ map (note: "  ${note}") (section.notes or [ ])
  );

  # Pango markup for notify-send; `dynamic` is a shell fragment expanded by
  # hypr-keys at runtime (current battery/performance/blue-light state).
  bindPango = bind:
    "<tt>${lib.escapeXML bind.keys}</tt>"
    + lib.concatStrings (lib.replicate (lib.max 1 (keyColumn - lib.stringLength bind.keys)) " ")
    + lib.escapeXML bind.desc
    + lib.optionalString (bind ? dynamic) " → ${bind.dynamic}";

  sectionPango = section: lib.concatStringsSep "\n" (
    [ "<b>═══ ${lib.escapeXML section.title} ═══</b>" ]
    ++ map bindPango section.binds
    ++ map (note: "  ${lib.escapeXML note}") (section.notes or [ ])
  );
in
{
  inherit sections;

  cheatsheet = lib.concatStringsSep "\n\n" (map sectionText sections);
  pango = lib.concatStringsSep "\n\n" (map sectionPango sections);

  # Binds shown on the lock screen, in section order (hyprlock has room for 15).
  lockLines = map bindLine (lib.filter (bind: bind.lock or false) (lib.concatMap (s: s.binds) sections));
}
