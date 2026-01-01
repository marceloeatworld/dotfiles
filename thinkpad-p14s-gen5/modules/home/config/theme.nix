# Centralized theme configuration with multiple theme support
#
# Usage in other modules:
#   { config, ... }:
#   let
#     theme = config.theme;
#   in {
#     # Access colors: theme.colors.background, theme.colors.red, etc.
#     # Access fonts: theme.fonts.mono, theme.fonts.monoSize, etc.
#   }
#
# To change theme:
#   - GUI: Run `theme-selector` or press SUPER+T
#   - CLI: Run `theme-selector <theme-name>`
#   - Manual: Edit ~/.config/theme/current and rebuild
#
{ lib, config, ... }:

let
  # ══════════════════════════════════════════════════════════════════════════
  # THEME DEFINITIONS
  # ══════════════════════════════════════════════════════════════════════════

  themes = {
    # ── Monokai Pro Ristretto ──────────────────────────────────────────────
    # Warm coffee-inspired dark theme with soft colors
    ristretto = {
      name = "Ristretto";
      description = "Warm coffee-inspired (Monokai Pro)";
      icon = "☕";
      colors = {
        # Base
        background = "#2c2421";
        backgroundAlt = "#2c2525";
        surface = "#403e41";
        foreground = "#e6d9db";
        foregroundDim = "#c3b7b8";
        # Accents
        red = "#fd6883";
        orange = "#fc9867";
        yellow = "#f9cc6c";
        green = "#adda78";
        cyan = "#85dacc";
        blue = "#85dacc";
        magenta = "#a8a9eb";
        # UI
        border = "#5b595c";
        selection = "#72696a";
        comment = "#72696a";
        # Terminal bright variants
        brightBlack = "#72696a";
        brightWhite = "#fff1f3";
      };
      fonts = {
        mono = "JetBrainsMono Nerd Font";
        monoSize = 11;
        sans = "Inter";
        sansSize = 11;
      };
    };

    # ── Neobrutalist ───────────────────────────────────────────────────────
    # Neobrutalist style inspired by Tavus design
    # Sharp edges, solid shadows, warm cream/beige palette with Catppuccin accents
    neobrutalist = {
      name = "Neobrutalist";
      description = "Tavus-inspired neobrutalist with Catppuccin accents";
      icon = "◼";
      colors = {
        # Base - Warm dark with cream undertones (Tavus-inspired)
        background = "#1a1720";      # Deep purple-black (slate-like)
        backgroundAlt = "#221f2b";   # Slightly lighter (from Tavus CSS)
        surface = "#2a2735";         # Surface for cards/panels
        foreground = "#F3EEE7";      # Warm cream text (Tavus)
        foregroundDim = "#92897a";   # Muted warm gray (Tavus)
        # Accents - Catppuccin Mocha pastels (soft but vibrant)
        red = "#f38ba8";             # Catppuccin Red
        orange = "#fab387";          # Catppuccin Peach
        yellow = "#f9e2af";          # Catppuccin Yellow
        green = "#a6e3a1";           # Catppuccin Green
        cyan = "#94e2d5";            # Catppuccin Teal
        blue = "#89b4fa";            # Catppuccin Blue
        magenta = "#cba6f7";         # Catppuccin Mauve
        # UI - Strong borders for neobrutalist feel
        border = "#3d3a47";          # Visible border
        selection = "#45475a";       # Catppuccin Surface1
        comment = "#6c7086";         # Catppuccin Overlay0
        # Terminal bright variants
        brightBlack = "#585b70";     # Catppuccin Surface2
        brightWhite = "#F7F4EF";     # Warm white (Tavus)
      };
      fonts = {
        mono = "JetBrainsMono Nerd Font";
        monoSize = 11;
        sans = "Inter";              # Clean geometric sans (similar to Suisse Intl)
        sansSize = 11;
      };
    };

    # ── Nord ───────────────────────────────────────────────────────────────
    # Arctic, north-bluish color palette
    nord = {
      name = "Nord";
      description = "Arctic north-bluish palette";
      icon = "❄";
      colors = {
        # Base - Polar night
        background = "#2e3440";
        backgroundAlt = "#3b4252";
        surface = "#434c5e";
        foreground = "#eceff4";
        foregroundDim = "#d8dee9";
        # Accents - Aurora
        red = "#bf616a";
        orange = "#d08770";
        yellow = "#ebcb8b";
        green = "#a3be8c";
        cyan = "#8fbcbb";
        blue = "#81a1c1";
        magenta = "#b48ead";
        # UI - Frost
        border = "#4c566a";
        selection = "#434c5e";
        comment = "#616e88";
        # Terminal bright variants
        brightBlack = "#4c566a";
        brightWhite = "#eceff4";
      };
      fonts = {
        mono = "JetBrainsMono Nerd Font";
        monoSize = 11;
        sans = "Inter";
        sansSize = 11;
      };
    };

    # ── Tokyo Night ────────────────────────────────────────────────────────
    # Clean, dark theme inspired by Tokyo city lights
    tokyonight = {
      name = "Tokyo Night";
      description = "Tokyo city lights inspired";
      icon = "🌃";
      colors = {
        # Base
        background = "#1a1b26";
        backgroundAlt = "#16161e";
        surface = "#24283b";
        foreground = "#c0caf5";
        foregroundDim = "#a9b1d6";
        # Accents
        red = "#f7768e";
        orange = "#ff9e64";
        yellow = "#e0af68";
        green = "#9ece6a";
        cyan = "#7dcfff";
        blue = "#7aa2f7";
        magenta = "#bb9af7";
        # UI
        border = "#3b4261";
        selection = "#33467c";
        comment = "#565f89";
        # Terminal bright variants
        brightBlack = "#444b6a";
        brightWhite = "#d5d6db";
      };
      fonts = {
        mono = "JetBrainsMono Nerd Font";
        monoSize = 11;
        sans = "Inter";
        sansSize = 11;
      };
    };

    # ── Catppuccin Mocha ───────────────────────────────────────────────────
    # Soothing pastel theme with warm colors
    catppuccin = {
      name = "Catppuccin";
      description = "Soothing pastel warm theme";
      icon = "🐱";
      colors = {
        # Base
        background = "#1e1e2e";
        backgroundAlt = "#181825";
        surface = "#313244";
        foreground = "#cdd6f4";
        foregroundDim = "#bac2de";
        # Accents
        red = "#f38ba8";
        orange = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        cyan = "#94e2d5";
        blue = "#89b4fa";
        magenta = "#cba6f7";
        # UI
        border = "#45475a";
        selection = "#45475a";
        comment = "#6c7086";
        # Terminal bright variants
        brightBlack = "#585b70";
        brightWhite = "#a6adc8";
      };
      fonts = {
        mono = "JetBrainsMono Nerd Font";
        monoSize = 11;
        sans = "Inter";
        sansSize = 11;
      };
    };
  };

  # Read theme from file in the dotfiles repo (not home directory)
  # The theme-selector script updates this file and rebuilds
  themeFile = ./current-theme;

  # Try to read theme file, fallback to "ristretto"
  currentTheme =
    let
      fileContent = builtins.tryEval (builtins.readFile themeFile);
    in
      if fileContent.success
      then builtins.replaceStrings ["\n" " " "\t"] ["" "" ""] fileContent.value
      else "ristretto";

  # Validate theme exists, fallback to ristretto
  validTheme = if builtins.hasAttr currentTheme themes then currentTheme else "ristretto";

  # Get the selected theme
  selectedTheme = themes.${validTheme};

  # Export theme list for the selector script
  themeList = builtins.attrNames themes;

in
{
  options.theme = {
    # ── Theme Selector ──
    name = lib.mkOption {
      type = lib.types.enum themeList;
      default = validTheme;
      description = ''
        Theme to use. Available themes:
        - ristretto: Monokai Pro Ristretto (warm coffee-inspired)
        - neobrutalist: Minimal high-contrast bold design
        - nord: Arctic north-bluish palette
        - tokyonight: Tokyo city lights inspired
        - catppuccin: Soothing pastel warm theme
      '';
    };

    # ── Color Options ──
    colors = {
      background = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.background;
        description = "Main background color";
      };
      backgroundAlt = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.backgroundAlt;
        description = "Alternative/secondary background";
      };
      surface = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.surface;
        description = "Surface/container color";
      };
      foreground = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.foreground;
        description = "Main text color";
      };
      foregroundDim = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.foregroundDim;
        description = "Dimmed text color";
      };
      red = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.red;
        description = "Red accent (errors, alerts)";
      };
      orange = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.orange;
        description = "Orange accent";
      };
      yellow = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.yellow;
        description = "Yellow accent (warnings, highlights)";
      };
      green = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.green;
        description = "Green accent (success, additions)";
      };
      cyan = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.cyan;
        description = "Cyan/teal accent";
      };
      blue = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.blue;
        description = "Blue accent";
      };
      magenta = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.magenta;
        description = "Magenta/purple accent";
      };
      border = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.border;
        description = "Border color";
      };
      selection = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.selection;
        description = "Selection/highlight background";
      };
      comment = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.comment;
        description = "Comment/muted text color";
      };
      brightBlack = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.brightBlack;
        description = "Bright black (terminal)";
      };
      brightWhite = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.brightWhite;
        description = "Bright white (terminal)";
      };
    };

    # ── Font Options ──
    fonts = {
      mono = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.fonts.mono;
        description = "Primary monospace font";
      };
      monoSize = lib.mkOption {
        type = lib.types.int;
        default = selectedTheme.fonts.monoSize;
        description = "Default monospace font size";
      };
      sans = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.fonts.sans;
        description = "Primary sans-serif font";
      };
      sansSize = lib.mkOption {
        type = lib.types.int;
        default = selectedTheme.fonts.sansSize;
        description = "Default sans-serif font size";
      };
    };
  };

  # No config needed - theme is read from ./current-theme file in dotfiles repo
}
