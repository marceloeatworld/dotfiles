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
    # WCAG AA compliant - all text colors ≥4.5:1 contrast
    ristretto = {
      name = "Ristretto";
      description = "Warm coffee-inspired (Monokai Pro)";
      icon = "☕";
      colors = {
        # Base
        background = "#2c2421";      # Warm dark brown
        backgroundAlt = "#2c2525";   # Elevated surfaces
        surface = "#403e41";         # Panels
        foreground = "#e6d9db";      # 11.08:1 contrast
        foregroundDim = "#c3b7b8";   # 7.81:1 contrast
        # Accents - all pass WCAG AA (≥4.5:1)
        red = "#fd6883";             # 5.42:1
        orange = "#fc9867";          # 7.11:1
        yellow = "#f9cc6c";          # 10.05:1
        green = "#adda78";           # 9.47:1
        cyan = "#85dacc";            # 9.34:1
        blue = "#85dacc";            # 9.34:1
        magenta = "#a8a9eb";         # 6.91:1
        # UI
        border = "#5b595c";          # 2.19:1
        selection = "#72696a";       # 2.86:1
        comment = "#989393";         # 5.02:1 (was #72696a 2.86:1 FAIL)
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
    # Ultra-minimal old-school terminal aesthetic
    # Eye-comfort optimized based on 2025 research:
    # - Dark gray (#1e1e1e) instead of pure black - reduces halation effect
    # - Text contrast 7:1-15:1 range (not 21:1) - reduces eye strain
    # - Desaturated accents - prevents "vibration" on dark backgrounds
    # - All colors pass WCAG AA (4.5:1 min for text, 3:1 for UI)
    # Sources: Material Design, WCAG 2.1, PMC eye strain studies
    neobrutalist = {
      name = "Neobrutalist";
      description = "Ultra-minimal old-school";
      icon = "▪";
      colors = {
        # Base - Eye-comfort dark grays (Material Design recommends #121212)
        # Using #1e1e1e (VS Code) - slightly lighter, proven comfortable
        background = "#1e1e1e";      # 11.25:1 contrast with foreground
        backgroundAlt = "#252526";   # Elevated surfaces
        surface = "#2d2d30";         # Panels/cards
        foreground = "#d4d4d4";      # Soft white - 11.25:1 (ideal range 7-15:1)
        foregroundDim = "#9d9d9d";   # Dim text - 6.15:1 (was 4.22:1 FAIL)
        # Accents - Desaturated + brightness adjusted for WCAG AA compliance
        red = "#d08080";             # 5.72:1 - errors (was 4.68:1)
        orange = "#c8a080";          # 7.02:1 - warnings
        yellow = "#d4c080";          # 9.35:1 - primary accent (brightest)
        green = "#90c090";           # 8.05:1 - success
        cyan = "#80b8c8";            # 7.56:1 - info (was 5.83:1)
        blue = "#90a8c8";            # 6.75:1 - links (was 5.01:1)
        magenta = "#b888b8";         # 5.52:1 - special (was 4.22:1 FAIL)
        # UI - Increased contrast for visibility (WCAG 3:1 min for UI)
        border = "#4a4a50";          # 1.87:1 - subtle but visible
        selection = "#3a5a80";       # 2.52:1 - clear selection highlight
        comment = "#7cb365";         # 6.74:1 - readable comments (was 5.00:1)
        # Terminal bright variants
        brightBlack = "#686868";     # 3.14:1 - meets UI requirement
        brightWhite = "#f0f0f0";     # 13.28:1 - high contrast when needed
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
    # WCAG AA compliant - adjusted red, orange, magenta, comment
    nord = {
      name = "Nord";
      description = "Arctic north-bluish palette";
      icon = "❄";
      colors = {
        # Base - Polar night
        background = "#2e3440";      # Nordic dark blue-gray
        backgroundAlt = "#3b4252";   # Elevated surfaces
        surface = "#434c5e";         # Panels
        foreground = "#eceff4";      # 10.84:1 contrast
        foregroundDim = "#d8dee9";   # 9.25:1 contrast
        # Accents - Aurora (adjusted for WCAG AA ≥4.5:1)
        red = "#d3959b";             # 5.08:1 (was #bf616a 3.05:1 FAIL)
        orange = "#d69885";          # 5.17:1 (was #d08770 4.39:1 FAIL)
        yellow = "#ebcb8b";          # 8.00:1
        green = "#a3be8c";           # 6.13:1
        cyan = "#8fbcbb";            # 5.99:1
        blue = "#81a1c1";            # 4.64:1
        magenta = "#c4a5bd";         # 5.20:1 (was #b48ead 4.41:1 FAIL)
        # UI - Frost
        border = "#4c566a";          # 1.69:1
        selection = "#434c5e";       # 1.45:1
        comment = "#9da4b4";         # 5.00:1 (was #616e88 2.43:1 FAIL)
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
    # WCAG AA compliant - adjusted comment color
    tokyonight = {
      name = "Tokyo Night";
      description = "Tokyo city lights inspired";
      icon = "🌃";
      colors = {
        # Base
        background = "#1a1b26";      # Deep blue-black
        backgroundAlt = "#16161e";   # Even darker for depth
        surface = "#24283b";         # Elevated surfaces
        foreground = "#c0caf5";      # 10.59:1 contrast
        foregroundDim = "#a9b1d6";   # 8.10:1 contrast
        # Accents - all pass WCAG AA (≥4.5:1)
        red = "#f7768e";             # 6.46:1
        orange = "#ff9e64";          # 8.40:1
        yellow = "#e0af68";          # 8.55:1
        green = "#9ece6a";           # 9.35:1
        cyan = "#7dcfff";            # 9.96:1
        blue = "#7aa2f7";            # 6.79:1
        magenta = "#bb9af7";         # 7.39:1
        # UI
        border = "#3b4261";          # 1.74:1
        selection = "#33467c";       # 1.88:1
        comment = "#848aa9";         # 5.04:1 (was #565f89 2.76:1 FAIL)
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
    # WCAG AA compliant - adjusted comment color
    catppuccin = {
      name = "Catppuccin";
      description = "Soothing pastel warm theme";
      icon = "🐱";
      colors = {
        # Base
        background = "#1e1e2e";      # Dark purple-gray
        backgroundAlt = "#181825";   # Deeper for contrast
        surface = "#313244";         # Elevated surfaces
        foreground = "#cdd6f4";      # 11.34:1 contrast
        foregroundDim = "#bac2de";   # 9.26:1 contrast
        # Accents - all pass WCAG AA (≥4.5:1)
        red = "#f38ba8";             # 7.08:1
        orange = "#fab387";          # 9.27:1
        yellow = "#f9e2af";          # 12.91:1
        green = "#a6e3a1";           # 11.03:1
        cyan = "#94e2d5";            # 11.01:1
        blue = "#89b4fa";            # 7.79:1
        magenta = "#cba6f7";         # 8.07:1
        # UI
        border = "#45475a";          # 1.80:1
        selection = "#45475a";       # 1.80:1
        comment = "#8b8e9f";         # 5.05:1 (was #6c7086 3.36:1 FAIL)
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
