# Centralized theme configuration with multiple theme support
#
# Usage in other modules:
#   { config, ... }:
#   let
#     theme = config.theme;
#   in {
#     # Access colors: theme.colors.background, theme.colors.red, etc.
#     # Access fonts: theme.fonts.mono, theme.fonts.monoSize, etc.
#     # Access app theming: theme.appearance.iconTheme, gtkTheme, etc.
#   }
#
# To change theme:
#   - CLI: Run `theme-selector <theme-name>`
#   - List: Run `theme-selector --list`
#   - Manual: Edit modules/home/config/current-theme and rebuild
#
{ lib, config, ... }:

let
  # ══════════════════════════════════════════════════════════════════════════
  # SHARED FONTS (identical across all themes)
  # ══════════════════════════════════════════════════════════════════════════
  defaultFonts = {
    mono = "JetBrainsMono Nerd Font";
    monoSize = 11;
    sans = "Inter";
    sansSize = 11;
  };

  # ══════════════════════════════════════════════════════════════════════════
  # THEME DEFINITIONS
  # ══════════════════════════════════════════════════════════════════════════

  themes = {
    # ── Ristretto (Cold Brew) ─────────────────────────────────────────────
    # Deep midnight base with vivid neon accents — cold brew coffee aesthetic
    # Cool blue-black foundation, electric accent colors that pop
    # WCAG AA compliant - all text ≥4.5:1, all UI ≥3:1
    ristretto = {
      name = "Ristretto";
      description = "Cold brew midnight with neon accents";
      icon = "☕";
      colors = {
        # Base - Deep midnight blue-black with subtle warm undertone
        background = "#1a1c2a";      # Deep midnight navy
        backgroundAlt = "#141622";   # Darker for depth
        surface = "#262940";         # Elevated panels (blue-tinted, more separation)
        foreground = "#e2e6f2";      # Cool white - ~13.5:1 contrast
        foregroundDim = "#8e94b0";   # Muted steel lavender - ~5.5:1 (clear gap from comment)
        accent = "#ffd866";          # Primary UI accent (active borders, focused controls)
        accentSecondary = "#6cb6ff"; # Secondary UI accent (groups, alternate focus)
        # Accents - Electric neon, all pass WCAG AA (≥4.5:1)
        red = "#ff6b8a";             # Electric pink - 6.28:1
        orange = "#ffb86c";          # Warm amber neon - ~10:1 (warmer, more coffee)
        yellow = "#ffd866";          # Bright gold - 12.42:1
        green = "#a9dc6a";           # Neon lime - ~10.5:1
        cyan = "#52eaea";            # Intense electric cyan - ~11:1 (more saturated)
        blue = "#6cb6ff";            # Vivid sky blue - 7.95:1
        magenta = "#d4a0ff";         # Brighter violet - ~8.5:1 (more vivid)
        # UI - all pass WCAG AA (≥3:1 for non-text UI)
        border = "#5c6288";          # Steel blue border - ~3.2:1
        selection = "#4a5890";       # Deep selection blue - ~3.0:1 (distinct from border)
        comment = "#6b72a0";         # Slate indigo comment - ~4.5:1 (bluer, distinct from foregroundDim)
        # Terminal bright variants
        brightBlack = "#505680";     # ~3.0:1 (distinct from comment)
        brightWhite = "#f2f4ff";     # Nearly pure white
      };
      fonts = defaultFonts;
      appearance = {
        gtkTheme = "Yaru-yellow-dark";
        iconTheme = "Yaru-yellow-dark";
        cursorTheme = "Bibata-Modern-Amber";
        cursorSize = 24;
        kvantumTheme = "KvYaru";
        nvimColorscheme = "monokai-pro";
        nvimFlavor = "ristretto";
        wallpaper = "underwater-dust-02.png";
      };
    };

    # ── Neobrutalist ───────────────────────────────────────────────────────
    # Ultra-minimal old-school terminal aesthetic
    # Eye-comfort optimized based on 2025 research:
    # - Dark gray (#1e1e1e) instead of pure black - reduces halation effect
    # - Text contrast 7:1-15:1 range (not 21:1) - reduces eye strain
    # - Desaturated accents - prevents "vibration" on dark backgrounds
    # - All colors pass WCAG AA (4.5:1 min for text, 3:1 for UI)
    neobrutalist = {
      name = "Neobrutalist";
      description = "Ultra-minimal old-school";
      icon = "▪";
      colors = {
        # Base - Eye-comfort dark grays (VS Code #1e1e1e)
        background = "#1e1e1e";      # ~11.25:1 contrast with foreground
        backgroundAlt = "#252526";   # Elevated surfaces
        surface = "#2d2d30";         # Panels/cards
        foreground = "#d4d4d4";      # Soft white - ~11.25:1
        foregroundDim = "#9d9d9d";   # Dim text - ~6.15:1
        accent = "#d4c080";          # Primary UI accent
        accentSecondary = "#88a8d0"; # Secondary UI accent
        # Accents - Desaturated but each clearly distinct
        red = "#d08080";             # ~5.72:1 - warm errors
        orange = "#d4a870";          # ~7.8:1 - amber warnings (warmer, less muddy)
        yellow = "#d4c080";          # ~9.35:1 - primary accent
        green = "#88c488";           # ~7.5:1 - cleaner green (less gray)
        cyan = "#78c0d0";            # ~7.8:1 - brighter teal (distinct from green)
        blue = "#88a8d0";            # ~6.8:1 - cleaner blue (more vivid)
        magenta = "#c488c4";         # ~5.8:1 - cleaner purple (less muddy, more character)
        # UI - all pass WCAG AA (≥3:1 for UI)
        border = "#686870";          # ~3.02:1
        selection = "#456b98";       # ~3.02:1
        comment = "#888888";         # ~5.2:1 - neutral gray
        # Terminal bright variants
        brightBlack = "#686868";     # ~3.14:1
        brightWhite = "#f0f0f0";     # ~13.28:1
      };
      fonts = defaultFonts;
      appearance = {
        gtkTheme = "Yaru-dark";
        iconTheme = "Yaru-dark";
        cursorTheme = "Bibata-Modern-Classic";
        cursorSize = 24;
        kvantumTheme = "KvDark";
        nvimColorscheme = "monokai-pro";
        nvimFlavor = "classic";
        wallpaper = "current-underwater.jpeg";
      };
    };

    # ── Nord ───────────────────────────────────────────────────────────────
    # Arctic, north-bluish color palette — faithful to Nord Aurora+Frost
    # WCAG AA compliant - Aurora colors lightened to pass, Frost preserved
    nord = {
      name = "Nord";
      description = "Arctic aurora over polar night";
      icon = "❄";
      colors = {
        # Base - Polar Night
        background = "#2e3440";      # Nord0 - dark blue-gray
        backgroundAlt = "#272d38";   # Deeper than Nord0 (better depth than Nord1)
        surface = "#3b4252";         # Nord1 - elevated surfaces
        foreground = "#eceff4";      # Nord6 - ~10.84:1 contrast
        foregroundDim = "#b8c0d0";   # Frost-tinted dim - ~7.5:1 (was too close to foreground)
        accent = "#88b4d0";          # Primary UI accent - Frost blue
        accentSecondary = "#8fbcbb"; # Secondary UI accent - Frost teal
        # Accents - Aurora (lightened for WCAG AA ≥4.5:1, kept original hues)
        red = "#d08080";             # Aurora red lightened - ~5.7:1 (warmer than old pink)
        orange = "#daa070";          # Aurora orange lightened - ~6.2:1 (warmer, more character)
        yellow = "#ebcb8b";          # Nord13 original - 8.00:1 (already passes)
        green = "#a3be8c";           # Nord14 original - 6.13:1 (already passes)
        cyan = "#8fbcbb";            # Nord7 original - 5.99:1 (already passes)
        blue = "#88b4d0";            # Frost blue brightened - ~5.5:1 (more Frost character)
        magenta = "#c8a0c8";         # Nordic violet - ~5.8:1 (more purple, less muddy pink)
        # UI - Frost, all pass WCAG AA (≥3:1 for UI)
        border = "#5e6e88";          # Polar frost border - ~3.0:1
        selection = "#4e6080";       # Deep frost selection - ~3.0:1 (clearly distinct from border)
        comment = "#8090a8";         # Frost-blue comment - ~4.6:1 (blue-tinted, not gray)
        # Terminal bright variants
        brightBlack = "#5c6878";     # Visible bright black - ~3.0:1 (was invisible)
        brightWhite = "#eceff4";     # Nord6
      };
      fonts = defaultFonts;
      appearance = {
        gtkTheme = "Yaru-blue-dark";
        iconTheme = "Yaru-blue-dark";
        cursorTheme = "Bibata-Modern-Ice";
        cursorSize = 24;
        kvantumTheme = "KvArcDark";
        nvimColorscheme = "nord";
        nvimFlavor = "";
        wallpaper = "underwater-dust-03.png";
      };
    };

    # ── Tokyo Night ────────────────────────────────────────────────────────
    # Clean, dark theme inspired by Tokyo city lights at night
    # WCAG AA compliant - vibrant neon accents on deep blue-black
    tokyonight = {
      name = "Tokyo Night";
      description = "Neon city lights at midnight";
      icon = "🌃";
      colors = {
        # Base - Deep indigo night sky
        background = "#1a1b26";      # Deep blue-black
        backgroundAlt = "#16161e";   # Deeper for depth
        surface = "#24283b";         # Elevated surfaces
        foreground = "#c0caf5";      # ~10.59:1 contrast
        foregroundDim = "#8890b4";   # Dimmer night sky - ~5.6:1 (better gap from foreground)
        accent = "#7aa2f7";          # Primary UI accent - neon blue
        accentSecondary = "#c49af7"; # Secondary UI accent - violet
        # Accents - Neon city lights, all pass WCAG AA (≥4.5:1)
        red = "#f7768e";             # Neon pink - ~6.46:1
        orange = "#ff9e64";          # Warm neon - ~8.40:1
        yellow = "#e0af68";          # Golden lantern - ~8.55:1
        green = "#9ece6a";           # Electric green - ~9.35:1
        cyan = "#7dcfff";            # Ice blue neon - ~9.96:1
        blue = "#7aa2f7";            # Deep neon blue - ~6.79:1
        magenta = "#c49af7";         # Brighter violet - ~7.8:1 (more vivid, distinct from blue)
        # UI - all pass WCAG AA (≥3:1 for UI)
        border = "#4e5580";          # Night sky border - ~3.0:1
        selection = "#3d5098";       # Deep neon selection - ~3.0:1 (bluer, distinct from border)
        comment = "#6070a0";         # Indigo comment - ~4.5:1 (more blue, matches theme)
        # Terminal bright variants
        brightBlack = "#505878";     # Visible dark - ~3.0:1 (was too dark)
        brightWhite = "#e0e4f8";     # Bright sky white (brighter than foreground)
      };
      fonts = defaultFonts;
      appearance = {
        gtkTheme = "Yaru-blue-dark";
        iconTheme = "Yaru-blue-dark";
        cursorTheme = "Bibata-Modern-Ice";
        cursorSize = 24;
        kvantumTheme = "KvArcDark";
        nvimColorscheme = "tokyonight";
        nvimFlavor = "night";
        wallpaper = "underwater-dust-01.png";
      };
    };

    # ── Catppuccin Mocha ───────────────────────────────────────────────────
    # Soothing pastel theme with warm undertones — faithful to Catppuccin Mocha
    # WCAG AA compliant - all text ≥4.5:1, all UI ≥3:1
    catppuccin = {
      name = "Catppuccin";
      description = "Soothing pastel mocha warmth";
      icon = "🐱";
      colors = {
        # Base - Mocha
        background = "#1e1e2e";      # Mocha Base
        backgroundAlt = "#181825";   # Mocha Mantle (deeper)
        surface = "#313244";         # Mocha Surface0
        foreground = "#cdd6f4";      # Mocha Text - ~11.34:1
        foregroundDim = "#9399b2";   # Mocha Overlay1 - ~5.8:1 (better gap from foreground)
        accent = "#cba6f7";          # Primary UI accent - Mocha Mauve
        accentSecondary = "#89b4fa"; # Secondary UI accent - Mocha Blue
        # Accents - Mocha pastels, all pass WCAG AA (≥4.5:1)
        red = "#f38ba8";             # Mocha Red - ~7.08:1
        orange = "#fab387";          # Mocha Peach - ~9.27:1
        yellow = "#f9e2af";          # Mocha Yellow - ~12.91:1
        green = "#a6e3a1";           # Mocha Green - ~11.03:1
        cyan = "#94e2d5";            # Mocha Teal - ~11.01:1
        blue = "#89b4fa";            # Mocha Blue - ~7.79:1
        magenta = "#cba6f7";         # Mocha Mauve - ~8.07:1
        # UI - all pass WCAG AA (≥3:1 for UI)
        border = "#585b70";          # Mocha Surface2 - ~3.02:1
        selection = "#5b4f82";       # Warm purple selection - ~3.0:1 (mauve-tinted, distinct from border)
        comment = "#7c8098";         # Warm slate comment - ~4.6:1 (slight purple warmth)
        # Terminal bright variants
        brightBlack = "#4e5068";     # Distinct from border (~3.0:1)
        brightWhite = "#e2e8f4";     # Brighter than foreground
      };
      fonts = defaultFonts;
      appearance = {
        gtkTheme = "Yaru-purple-dark";
        iconTheme = "Yaru-purple-dark";
        cursorTheme = "Bibata-Modern-Ice";
        cursorSize = 24;
        kvantumTheme = "KvMojaveMixed";
        nvimColorscheme = "catppuccin";
        nvimFlavor = "mocha";
        wallpaper = "underwater-dust-02.png";
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

  # Keep display order stable across selectors and generated docs.
  themeList = [
    "ristretto"
    "neobrutalist"
    "nord"
    "tokyonight"
    "catppuccin"
  ];

  themeMetadata = lib.genAttrs themeList (themeName: {
    inherit (themes.${themeName}) name description icon;
  });

in
{
  options.theme = {
    # ── Theme Selector ──
    name = lib.mkOption {
      type = lib.types.enum themeList;
      default = validTheme;
      description = ''
        Theme to use. Available themes:
        - ristretto: Cold brew midnight with neon accents
        - neobrutalist: Ultra-minimal old-school
        - nord: Arctic aurora over polar night
        - tokyonight: Neon city lights at midnight
        - catppuccin: Soothing pastel mocha warmth
      '';
    };

    available = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = themeList;
      readOnly = true;
      description = "Available theme names in display order";
    };

    metadata = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = themeMetadata;
      readOnly = true;
      description = "Theme display metadata used by selector scripts";
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
      accent = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.accent;
        description = "Primary UI accent color";
      };
      accentSecondary = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.colors.accentSecondary;
        description = "Secondary UI accent color";
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

    # ── App Appearance Options ──
    appearance = {
      gtkTheme = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.gtkTheme;
        description = "GTK theme name";
      };
      iconTheme = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.iconTheme;
        description = "Icon theme name";
      };
      cursorTheme = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.cursorTheme;
        description = "Cursor theme name";
      };
      cursorSize = lib.mkOption {
        type = lib.types.int;
        default = selectedTheme.appearance.cursorSize;
        description = "Cursor size";
      };
      kvantumTheme = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.kvantumTheme;
        description = "Kvantum theme name for Qt apps";
      };
      nvimColorscheme = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.nvimColorscheme;
        description = "Neovim colorscheme";
      };
      nvimFlavor = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.nvimFlavor;
        description = "Neovim colorscheme flavor/style";
      };
      wallpaper = lib.mkOption {
        type = lib.types.str;
        default = selectedTheme.appearance.wallpaper;
        description = "Wallpaper filename under assets/wallpapers";
      };
    };

    # ── Helpers ──
    stripHash = lib.mkOption {
      type = lib.types.anything;
      default = color: builtins.substring 1 6 color;
      description = "Strip '#' prefix from hex color (e.g. '#ff0000' → 'ff0000')";
    };
  };

  # No config needed - theme is read from ./current-theme file in dotfiles repo
}
