# Walker - Modern application launcher
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    walker
  ];

  # Walker configuration - Simplified for reliability
  xdg.configFile."walker/config.toml".text = ''
    force_keyboard_focus = true
    close_when_open = true
    selection_wrap = true
    click_to_close = true
    theme = "ristretto"
    disable_mouse = false

    # Window positioning (centered, not fullscreen)
    [shell]
    width = 800
    height = 600

    [placeholders]
    "default" = { input = " Search...", list = "No Results" }

    [keybinds]
    close = ["Escape"]
    next = ["Down"]
    previous = ["Up"]
    toggle_exact = ["ctrl e"]
    resume_last_query = ["ctrl r"]
    quick_activate = []

    [providers]
    default = [
      "desktopapplications",
      "websearch",
    ]
    empty = ["desktopapplications"]
    max_results = 50

    [providers.sets]
    [providers.max_results_provider]

    # Prefix-based provider activation
    [[providers.prefixes]]
    prefix = "/"
    provider = "providerlist"

    [[providers.prefixes]]
    prefix = "."
    provider = "files"

    [[providers.prefixes]]
    prefix = ":"
    provider = "symbols"

    [[providers.prefixes]]
    prefix = "="
    provider = "calc"

    [[providers.prefixes]]
    prefix = "@"
    provider = "websearch"

    [[providers.prefixes]]
    prefix = "$"
    provider = "clipboard"

    # Provider actions
    [providers.actions]
    dmenu = [{ action = "select", default = true, bind = "Return" }]

    providerlist = [
      { action = "activate", default = true, bind = "Return", after = "ClearReload" },
    ]

    bluetooth = [
      { action = "find", global = true, bind = "ctrl f", after = "AsyncClearReload" },
      { action = "trust", bind = "ctrl t", after = "AsyncReload" },
      { action = "untrust", bind = "ctrl t", after = "AsyncReload" },
      { action = "pair", bind = "Return", after = "AsyncReload" },
      { action = "remove", bind = "ctrl d", after = "AsyncReload" },
      { action = "connect", bind = "Return", after = "AsyncReload" },
      { action = "disconnect", bind = "Return", after = "AsyncReload" },
    ]

    calc = [
      { action = "copy", default = true, bind = "Return" },
      { action = "delete", bind = "ctrl d", after = "AsyncReload" },
      { action = "save", bind = "ctrl s", after = "AsyncClearReload" },
    ]

    websearch = [
      { action = "search", default = true, bind = "Return" },
      { action = "erase_history", label = "clear hist", bind = "ctrl h", after = "Reload" },
    ]

    desktopapplications = [
      { action = "start", default = true, bind = "Return" },
      { action = "start:keep", label = "open+next", bind = "shift Return", after = "KeepOpen" },
      { action = "erase_history", label = "clear hist", bind = "ctrl h", after = "AsyncReload" },
      { action = "pin", bind = "ctrl p", after = "AsyncReload" },
      { action = "unpin", bind = "ctrl p", after = "AsyncReload" },
      { action = "pinup", bind = "ctrl n", after = "AsyncReload" },
      { action = "pindown", bind = "ctrl m", after = "AsyncReload" },
    ]

    files = [
      { action = "open", default = true, bind = "Return" },
      { action = "opendir", label = "open dir", bind = "ctrl Return" },
      { action = "copypath", label = "copy path", bind = "ctrl shift c" },
      { action = "copyfile", label = "copy file", bind = "ctrl c" },
    ]

    todo = [
      { action = "save", default = true, bind = "Return", after = "ClearReload" },
      { action = "delete", bind = "ctrl d", after = "ClearReload" },
      { action = "active", bind = "Return", after = "ClearReload" },
      { action = "inactive", bind = "Return", after = "ClearReload" },
      { action = "done", bind = "ctrl f", after = "ClearReload" },
      { action = "clear", bind = "ctrl x", after = "ClearReload", global = true },
    ]

    runner = [
      { action = "run", default = true, bind = "Return" },
      { action = "runterminal", label = "run in terminal", bind = "shift Return" },
      { action = "erase_history", label = "clear hist", bind = "ctrl h", after = "Reload" },
    ]

    symbols = [
      { action = "run_cmd", label = "select", default = true, bind = "Return" },
      { action = "erase_history", label = "clear hist", bind = "ctrl h", after = "Reload" },
    ]

    unicode = [
      { action = "run_cmd", label = "select", default = true, bind = "Return" },
      { action = "erase_history", label = "clear hist", bind = "ctrl h", after = "Reload" },
    ]

    clipboard = [
      { action = "copy", default = true, bind = "Return" },
      { action = "remove", bind = "ctrl d", after = "ClearReload" },
      { action = "remove_all", global = true, label = "clear", bind = "ctrl shift d", after = "ClearReload" },
      { action = "toggle_images", global = true, label = "toggle images", bind = "ctrl i", after = "ClearReload" },
      { action = "edit", bind = "ctrl o" },
    ]
  '';

  # Elephant (Walker provider) configurations
  xdg.configFile."walker/calc.toml".text = ''
    async = false
  '';

  xdg.configFile."walker/desktopapplications.toml".text = ''
    show_actions = false
    only_search_title = true
    history = false
  '';

  # Ristretto theme CSS
  xdg.configFile."walker/themes/ristretto.css".text = ''
    @define-color selected-text #fabd2f;
    @define-color text #e6d9db;
    @define-color base #2c2525;
    @define-color border #e6d9db;
    @define-color foreground #e6d9db;
    @define-color background #2c2525;
  '';
}
