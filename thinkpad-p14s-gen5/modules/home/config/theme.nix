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
# To change theme: set `theme.name = "neobrutalist";` in home.nix
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
    # Minimal, high-contrast, bold design with sharp edges
    # Inspired by brutalist architecture and modern design
    neobrutalist = {
      colors = {
        # Base - Pure black/white for maximum contrast
        background = "#0a0a0a";
        backgroundAlt = "#121212";
        surface = "#1a1a1a";
        foreground = "#f5f5f5";
        foregroundDim = "#a0a0a0";
        # Accents - Bold, saturated, unapologetic
        red = "#ff3333";
        orange = "#ff6600";
        yellow = "#ffcc00";
        green = "#00cc66";
        cyan = "#00cccc";
        blue = "#3399ff";
        magenta = "#cc33ff";
        # UI - Stark contrasts
        border = "#333333";
        selection = "#2a2a2a";
        comment = "#666666";
        # Terminal bright variants
        brightBlack = "#555555";
        brightWhite = "#ffffff";
      };
      fonts = {
        mono = "JetBrainsMono Nerd Font";
        monoSize = 11;
        sans = "Inter";
        sansSize = 11;
      };
    };

    # ── Nord ───────────────────────────────────────────────────────────────
    # Arctic, north-bluish color palette
    nord = {
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
  };

  # Get the selected theme
  selectedTheme = themes.${config.theme.name};

in
{
  options.theme = {
    # ── Theme Selector ──
    name = lib.mkOption {
      type = lib.types.enum (builtins.attrNames themes);
      default = "ristretto";
      description = ''
        Theme to use. Available themes:
        - ristretto: Monokai Pro Ristretto (warm coffee-inspired)
        - neobrutalist: Minimal high-contrast bold design
        - nord: Arctic north-bluish palette
        - tokyonight: Tokyo city lights inspired
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

  config = {};
}
