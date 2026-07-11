{}:

let
  colorThemeFor = theme:
    if theme.appearance.preferDark then "Default Dark Modern" else "Default Light Modern";

  colorCustomizations = theme:
    let
      c = theme.colors;
    in
    {
      "activityBar.background" = c.backgroundAlt;
      "activityBar.foreground" = c.foreground;
      "activityBar.inactiveForeground" = c.comment;
      "activityBarBadge.background" = c.accent;
      "activityBarBadge.foreground" = c.background;
      "badge.background" = c.accent;
      "badge.foreground" = c.background;
      "button.background" = c.surface;
      "button.foreground" = c.foreground;
      "button.hoverBackground" = c.selection;
      "button.secondaryBackground" = c.backgroundAlt;
      "button.secondaryForeground" = c.foregroundDim;
      "button.secondaryHoverBackground" = c.surface;
      "checkbox.background" = c.backgroundAlt;
      "checkbox.border" = c.border;
      "checkbox.foreground" = c.foreground;
      "commandCenter.activeBackground" = "${c.selection}99";
      "commandCenter.background" = c.backgroundAlt;
      "commandCenter.border" = c.border;
      "commandCenter.foreground" = c.foreground;
      "contrastBorder" = c.border;
      "descriptionForeground" = c.foregroundDim;
      "dropdown.background" = c.backgroundAlt;
      "dropdown.border" = c.border;
      "dropdown.foreground" = c.foreground;
      "editor.background" = c.background;
      "editor.foreground" = c.foreground;
      "editor.findMatchBackground" = "${c.accent}4d";
      "editor.findMatchBorder" = c.accent;
      "editor.findMatchHighlightBackground" = "${c.accentSecondary}33";
      "editor.findRangeHighlightBackground" = "${c.selection}66";
      "editor.inactiveSelectionBackground" = "${c.selection}66";
      "editor.lineHighlightBackground" = "${c.surface}99";
      "editor.lineHighlightBorder" = "${c.border}55";
      "editor.selectionBackground" = c.selection;
      "editor.selectionForeground" = c.foreground;
      "editor.wordHighlightBackground" = "${c.accentSecondary}26";
      "editor.wordHighlightStrongBackground" = "${c.accent}33";
      "editorBracketHighlight.foreground1" = c.blue;
      "editorBracketHighlight.foreground2" = c.green;
      "editorBracketHighlight.foreground3" = c.yellow;
      "editorBracketHighlight.foreground4" = c.magenta;
      "editorBracketHighlight.foreground5" = c.cyan;
      "editorBracketHighlight.foreground6" = c.orange;
      "editorCursor.foreground" = c.accent;
      "editorError.foreground" = c.red;
      "editorGroup.border" = c.border;
      "editorGroupHeader.tabsBackground" = c.backgroundAlt;
      "editorGroupHeader.tabsBorder" = c.border;
      "editorGutter.addedBackground" = c.green;
      "editorGutter.background" = c.background;
      "editorGutter.deletedBackground" = c.red;
      "editorGutter.modifiedBackground" = c.orange;
      "editorLineNumber.activeForeground" = c.accent;
      "editorLineNumber.foreground" = c.comment;
      "editorOverviewRuler.border" = c.backgroundAlt;
      "editorWarning.foreground" = c.yellow;
      "editorWidget.background" = c.backgroundAlt;
      "editorWidget.border" = c.border;
      "errorForeground" = c.red;
      "focusBorder" = c.accent;
      "foreground" = c.foreground;
      "gitDecoration.addedResourceForeground" = c.green;
      "gitDecoration.conflictingResourceForeground" = c.magenta;
      "gitDecoration.deletedResourceForeground" = c.red;
      "gitDecoration.ignoredResourceForeground" = c.comment;
      "gitDecoration.modifiedResourceForeground" = c.orange;
      "gitDecoration.renamedResourceForeground" = c.cyan;
      "input.background" = c.backgroundAlt;
      "input.border" = c.border;
      "input.foreground" = c.foreground;
      "input.placeholderForeground" = c.comment;
      "inputOption.activeBackground" = "${c.accent}33";
      "inputOption.activeBorder" = c.accent;
      "inputValidation.errorBorder" = c.red;
      "inputValidation.infoBorder" = c.blue;
      "inputValidation.warningBorder" = c.yellow;
      "list.activeSelectionBackground" = c.selection;
      "list.activeSelectionForeground" = c.foreground;
      "list.focusBackground" = "${c.selection}99";
      "list.highlightForeground" = c.accent;
      "list.hoverBackground" = c.surface;
      "list.inactiveSelectionBackground" = "${c.selection}88";
      "list.inactiveSelectionForeground" = c.foreground;
      "menu.background" = c.backgroundAlt;
      "menu.border" = c.border;
      "menu.foreground" = c.foreground;
      "menu.selectionBackground" = c.selection;
      "menu.selectionForeground" = c.foreground;
      "minimap.background" = c.background;
      "notificationCenter.border" = c.border;
      "notificationCenterHeader.background" = c.surface;
      "notificationToast.border" = c.border;
      "notifications.background" = c.backgroundAlt;
      "notifications.border" = c.border;
      "notifications.foreground" = c.foreground;
      "panel.background" = c.backgroundAlt;
      "panel.border" = c.border;
      "panelTitle.activeBorder" = c.accent;
      "panelTitle.activeForeground" = c.foreground;
      "panelTitle.inactiveForeground" = c.comment;
      "peekView.border" = c.accent;
      "peekViewEditor.background" = c.background;
      "peekViewResult.background" = c.backgroundAlt;
      "pickerGroup.border" = c.border;
      "pickerGroup.foreground" = c.accent;
      "progressBar.background" = c.accent;
      "quickInput.background" = c.backgroundAlt;
      "quickInput.foreground" = c.foreground;
      "quickInputList.focusBackground" = c.selection;
      "scrollbar.shadow" = c.background;
      "scrollbarSlider.activeBackground" = "${c.accent}77";
      "scrollbarSlider.background" = "${c.border}66";
      "scrollbarSlider.hoverBackground" = "${c.border}99";
      "sideBar.background" = c.backgroundAlt;
      "sideBar.border" = c.border;
      "sideBar.foreground" = c.foreground;
      "sideBarSectionHeader.background" = c.surface;
      "sideBarSectionHeader.border" = c.border;
      "sideBarTitle.foreground" = c.foreground;
      "statusBar.background" = c.backgroundAlt;
      "statusBar.border" = c.border;
      "statusBar.debuggingBackground" = c.orange;
      "statusBar.debuggingForeground" = c.background;
      "statusBar.foreground" = c.foreground;
      "statusBar.noFolderBackground" = c.backgroundAlt;
      "statusBarItem.activeBackground" = "${c.selection}cc";
      "statusBarItem.hoverBackground" = c.surface;
      "tab.activeBackground" = c.background;
      "tab.activeBorder" = c.accent;
      "tab.activeForeground" = c.foreground;
      "tab.border" = c.border;
      "tab.inactiveBackground" = c.backgroundAlt;
      "tab.inactiveForeground" = c.comment;
      "terminal.ansiBlack" = c.background;
      "terminal.ansiBlue" = c.blue;
      "terminal.ansiBrightBlack" = c.brightBlack;
      "terminal.ansiBrightBlue" = c.blue;
      "terminal.ansiBrightCyan" = c.cyan;
      "terminal.ansiBrightGreen" = c.green;
      "terminal.ansiBrightMagenta" = c.magenta;
      "terminal.ansiBrightRed" = c.red;
      "terminal.ansiBrightWhite" = c.brightWhite;
      "terminal.ansiBrightYellow" = c.yellow;
      "terminal.ansiCyan" = c.cyan;
      "terminal.ansiGreen" = c.green;
      "terminal.ansiMagenta" = c.magenta;
      "terminal.ansiRed" = c.red;
      "terminal.ansiWhite" = c.foreground;
      "terminal.ansiYellow" = c.yellow;
      "terminal.background" = c.background;
      "terminal.foreground" = c.foreground;
      "terminal.selectionBackground" = c.selection;
      "textBlockQuote.background" = c.backgroundAlt;
      "textBlockQuote.border" = c.border;
      "textCodeBlock.background" = c.backgroundAlt;
      "textLink.activeForeground" = c.accentSecondary;
      "textLink.foreground" = c.accent;
      "titleBar.activeBackground" = c.backgroundAlt;
      "titleBar.activeForeground" = c.foreground;
      "titleBar.border" = c.border;
      "titleBar.inactiveBackground" = c.backgroundAlt;
      "titleBar.inactiveForeground" = c.comment;
      "tree.indentGuidesStroke" = c.border;
      "walkThrough.embeddedEditorBackground" = c.background;
      "welcomePage.tileBackground" = c.backgroundAlt;
      "widget.border" = c.border;
      "widget.shadow" = c.background;
    };

  tokenColorCustomizations = theme:
    let
      c = theme.colors;
    in
    {
      comments = c.comment;
      functions = c.blue;
      keywords = c.magenta;
      numbers = c.orange;
      strings = c.green;
      types = c.cyan;
      variables = c.foreground;
      textMateRules = [
        {
          scope = [
            "constant"
            "constant.language"
            "constant.numeric"
            "support.constant"
          ];
          settings.foreground = c.orange;
        }
        {
          scope = [
            "entity.name.function"
            "support.function"
          ];
          settings.foreground = c.blue;
        }
        {
          scope = [
            "entity.name.type"
            "entity.name.class"
            "support.type"
          ];
          settings.foreground = c.cyan;
        }
        {
          scope = [
            "keyword"
            "storage"
            "storage.type"
          ];
          settings.foreground = c.magenta;
        }
        {
          scope = [
            "markup.heading"
            "markup.bold"
          ];
          settings = {
            foreground = c.accent;
            fontStyle = "bold";
          };
        }
        {
          scope = [
            "markup.inserted"
          ];
          settings.foreground = c.green;
        }
        {
          scope = [
            "markup.deleted"
          ];
          settings.foreground = c.red;
        }
        {
          scope = [
            "invalid"
            "invalid.illegal"
          ];
          settings.foreground = c.red;
        }
      ];
    };

  semanticTokenColorCustomizations = theme:
    let
      c = theme.colors;
    in
    {
      enabled = true;
      rules = {
        class = c.cyan;
        enum = c.cyan;
        enumMember = c.orange;
        function = c.blue;
        interface = c.cyan;
        keyword = c.magenta;
        macro = c.magenta;
        method = c.blue;
        namespace = c.cyan;
        number = c.orange;
        parameter = c.foreground;
        property = c.foreground;
        string = c.green;
        struct = c.cyan;
        type = c.cyan;
        typeParameter = c.cyan;
        variable = c.foreground;
        "variable.readonly" = c.orange;
      };
    };
in
{
  inherit
    colorCustomizations
    colorThemeFor
    semanticTokenColorCustomizations
    tokenColorCustomizations
    ;

  settingsFor = theme: {
    "window.autoDetectColorScheme" = true;
    "workbench.colorTheme" = colorThemeFor theme;
    "workbench.preferredDarkColorTheme" = "Default Dark Modern";
    "workbench.preferredLightColorTheme" = "Default Light Modern";
    "workbench.colorCustomizations" = colorCustomizations theme;
    "editor.tokenColorCustomizations" = tokenColorCustomizations theme;
    "editor.semanticTokenColorCustomizations" = semanticTokenColorCustomizations theme;
  };
}
