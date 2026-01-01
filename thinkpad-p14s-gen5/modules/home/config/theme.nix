# Centralized theme configuration - Monokai Pro Ristretto
# All colors and fonts defined here to avoid duplication across modules
#
# Usage in other modules:
#   { config, ... }:
#   let
#     theme = config.theme;
#   in {
#     # Access colors: theme.colors.background, theme.colors.red, etc.
#     # Access fonts: theme.fonts.mono, theme.fonts.monoSize, etc.
#   }
{ lib, ... }:

{
  options.theme = {
    # ── Monokai Pro Ristretto Colors ──
    colors = {
      # Base colors
      background = lib.mkOption {
        type = lib.types.str;
        default = "#2c2421";
        description = "Main background color";
      };
      backgroundAlt = lib.mkOption {
        type = lib.types.str;
        default = "#2c2525";
        description = "Alternative/secondary background";
      };
      surface = lib.mkOption {
        type = lib.types.str;
        default = "#403e41";
        description = "Surface/container color";
      };
      foreground = lib.mkOption {
        type = lib.types.str;
        default = "#e6d9db";
        description = "Main text color";
      };
      foregroundDim = lib.mkOption {
        type = lib.types.str;
        default = "#c3b7b8";
        description = "Dimmed text color";
      };

      # Accent colors
      red = lib.mkOption {
        type = lib.types.str;
        default = "#fd6883";
        description = "Red accent (errors, alerts)";
      };
      orange = lib.mkOption {
        type = lib.types.str;
        default = "#fc9867";
        description = "Orange accent";
      };
      yellow = lib.mkOption {
        type = lib.types.str;
        default = "#f9cc6c";
        description = "Yellow accent (warnings, highlights)";
      };
      green = lib.mkOption {
        type = lib.types.str;
        default = "#adda78";
        description = "Green accent (success, additions)";
      };
      cyan = lib.mkOption {
        type = lib.types.str;
        default = "#85dacc";
        description = "Cyan/teal accent";
      };
      blue = lib.mkOption {
        type = lib.types.str;
        default = "#85dacc";
        description = "Blue accent (same as cyan in Ristretto)";
      };
      magenta = lib.mkOption {
        type = lib.types.str;
        default = "#a8a9eb";
        description = "Magenta/purple accent";
      };

      # UI-specific colors
      border = lib.mkOption {
        type = lib.types.str;
        default = "#5b595c";
        description = "Border color";
      };
      selection = lib.mkOption {
        type = lib.types.str;
        default = "#72696a";
        description = "Selection/highlight background";
      };
      comment = lib.mkOption {
        type = lib.types.str;
        default = "#72696a";
        description = "Comment/muted text color";
      };

      # Bright variants (for terminal)
      brightBlack = lib.mkOption {
        type = lib.types.str;
        default = "#72696a";
        description = "Bright black (comments)";
      };
      brightWhite = lib.mkOption {
        type = lib.types.str;
        default = "#fff1f3";
        description = "Bright white";
      };
    };

    # ── Font Configuration ──
    fonts = {
      mono = lib.mkOption {
        type = lib.types.str;
        default = "JetBrainsMono Nerd Font";
        description = "Primary monospace font";
      };
      monoSize = lib.mkOption {
        type = lib.types.int;
        default = 11;
        description = "Default monospace font size";
      };
      sans = lib.mkOption {
        type = lib.types.str;
        default = "Inter";
        description = "Primary sans-serif font";
      };
      sansSize = lib.mkOption {
        type = lib.types.int;
        default = 11;
        description = "Default sans-serif font size";
      };
    };

    # ── Helper Functions (as strings for use in configs) ──
    # These provide ready-to-use format strings
    css = {
      background = lib.mkOption {
        type = lib.types.str;
        default = "#2c2421";
        description = "CSS-ready background color";
      };
      foreground = lib.mkOption {
        type = lib.types.str;
        default = "#e6d9db";
        description = "CSS-ready foreground color";
      };
    };
  };

  # Default config values are set above via `default = ...`
  config = {};
}
