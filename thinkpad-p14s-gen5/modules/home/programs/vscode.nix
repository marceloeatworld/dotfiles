# Visual Studio Code configuration.
{ config, pkgs, lib, ... }:

let
  theme = config.theme;
  c = theme.colors;
  podmanSocketPath = "/run/user/1000/podman/podman.sock";
  podmanSocket = "unix://${podmanSocketPath}";
in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # Keep Marketplace extensions mutable so existing manually installed
    # extensions and Settings Sync extensions are not replaced by Nix.
    mutableExtensionsDir = true;

    argvSettings = {
      "disable-hardware-acceleration" = false;
      # Keep this aligned with telemetry.telemetryLevel = "off"; VS Code
      # rewrites argv.json at startup when they disagree.
      "enable-crash-reporter" = false;
      "password-store" = "gnome-libsecret";
    };

    profiles.default = {
      # VS Code itself is pinned by the Nix overlay; extensions stay mutable.
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      userSettings = {
        # Appearance
        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.preferredDarkColorTheme" = "Default Dark Modern";
        "workbench.preferredLightColorTheme" = "Default Light Modern";
        "workbench.iconTheme" = "vs-seti";
        "workbench.startupEditor" = "none";
        "workbench.sideBar.location" = "left";
        "workbench.panel.defaultLocation" = "bottom";
        "workbench.editor.showTabs" = "multiple";
        "workbench.editor.labelFormat" = "medium";
        "workbench.editor.enablePreview" = false;
        "workbench.editor.revealIfOpen" = true;
        "workbench.editor.highlightModifiedTabs" = true;
        "workbench.editor.pinnedTabsOnSeparateRow" = true;
        "workbench.layoutControl.enabled" = true;
        "workbench.statusBar.visible" = true;
        "workbench.commandPalette.preserveInput" = true;
        "workbench.commandPalette.history" = 50;
        "workbench.settings.editor" = "ui";
        "workbench.tips.enabled" = false;
        "window.commandCenter" = true;
        "window.menuBarVisibility" = "compact";
        "window.restoreWindows" = "none";
        "window.titleBarStyle" = "custom";
        "window.zoomLevel" = 0;
        "breadcrumbs.enabled" = true;
        "workbench.colorCustomizations" = {
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
        "editor.tokenColorCustomizations" = {
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
        "editor.semanticTokenColorCustomizations" = {
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

        # Editor
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'FiraCode Nerd Font', 'CaskaydiaCove Nerd Font', monospace";
        "editor.fontSize" = 14;
        "editor.fontWeight" = "400";
        "editor.lineHeight" = 22;
        "editor.fontLigatures" = true;
        "editor.tabSize" = 2;
        "editor.insertSpaces" = true;
        "editor.detectIndentation" = true;
        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "editor.trimAutoWhitespace" = true;
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.guides.indentation" = true;
        "editor.renderWhitespace" = "selection";
        "editor.rulers" = [ 100 ];
        "editor.minimap.enabled" = false;
        "editor.stickyScroll.enabled" = true;
        "editor.scrollBeyondLastLine" = false;
        "editor.linkedEditing" = true;
        "editor.copyWithSyntaxHighlighting" = false;
        "editor.emptySelectionClipboard" = false;
        "editor.inlayHints.enabled" = "onUnlessPressed";
        "editor.cursorBlinking" = "smooth";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.smoothScrolling" = true;
        "editor.renderLineHighlight" = "all";
        "editor.inlineSuggest.enabled" = true;
        "editor.inlineSuggest.suppressSuggestions" = false;
        "editor.suggestSelection" = "first";
        "editor.quickSuggestions" = {
          other = true;
          comments = false;
          strings = true;
        };
        "editor.quickSuggestionsDelay" = 50;
        "editor.acceptSuggestionOnCommitCharacter" = true;
        "editor.acceptSuggestionOnEnter" = "on";
        "editor.snippetSuggestions" = "top";
        "editor.suggest.localityBonus" = true;
        "editor.suggest.insertMode" = "replace";
        "editor.wordBasedSuggestions" = "matchingDocuments";
        "editor.parameterHints.enabled" = true;
        "editor.hover.enabled" = true;
        "editor.hover.delay" = 300;
        "editor.gotoLocation.multipleDefinitions" = "peek";
        "editor.gotoLocation.multipleReferences" = "peek";
        "editor.gotoLocation.multipleImplementations" = "peek";

        # Files, explorer and search
        "files.autoSave" = "off";
        "files.autoSaveDelay" = 1000;
        "files.eol" = "\n";
        "files.simpleDialog.enable" = true;
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.exclude" = {
          "**/.classpath" = true;
          "**/.project" = true;
          "**/.settings" = true;
          "**/.factorypath" = true;
          "**/.DS_Store" = true;
          "**/Thumbs.db" = true;
          "**/__pycache__" = true;
          "**/.pytest_cache" = true;
          "**/node_modules" = true;
          "**/.git" = false;
          "**/.env" = false;
          "**/.env.*" = false;
          "**/secrets.*" = false;
        };
        "search.exclude" = {
          "**/node_modules" = true;
          "**/bower_components" = true;
          "**/dist" = true;
          "**/build" = true;
          "**/*.code-search" = true;
          "**/.env" = true;
          "**/.env.*" = true;
          "**/secrets.*" = true;
          "**/*.key" = true;
          "**/*.pem" = true;
          "**/credentials*" = true;
          "**/.aws/**" = true;
          "**/.ssh/**" = true;
        };
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/.venv/**" = true;
          "**/.env*" = true;
          "**/secrets.*" = true;
        };
        "files.associations" = {
          "**/.env" = "properties";
          "**/.env.*" = "properties";
          "**/secrets.*" = "properties";
        };
        "explorer.confirmDragAndDrop" = true;
        "explorer.confirmDelete" = true;
        "explorer.autoReveal" = "focusNoScroll";
        "explorer.compactFolders" = true;
        "explorer.incrementalNaming" = "smart";
        "explorer.fileNesting.enabled" = true;
        "explorer.fileNesting.expand" = false;
        "explorer.fileNesting.patterns" = {
          ".env" = ".env.*,*.env";
          "Cargo.toml" = "Cargo.lock";
          "Dockerfile" = ".dockerignore,Dockerfile.*,compose*.yml,docker-compose*.yml";
          "flake.nix" = "flake.lock";
          "package.json" = "package-lock.json,pnpm-lock.yaml,yarn.lock,bun.lock,bun.lockb,deno.lock";
          "pyproject.toml" = "poetry.lock,uv.lock,requirements*.txt";
          "tsconfig.json" = "tsconfig.*.json";
        };
        "search.smartCase" = true;
        "search.useIgnoreFiles" = true;
        "search.useGlobalIgnoreFiles" = true;
        "search.searchOnType" = false;
        "search.collapseResults" = "auto";

        # Integrated terminal
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "terminal.integrated.profiles.linux" = {
          zsh = {
            path = "${pkgs.zsh}/bin/zsh";
            args = [ "-l" ];
            icon = "terminal";
          };
        };
        "terminal.integrated.inheritEnv" = true;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font', 'FiraCode Nerd Font', monospace";
        "terminal.integrated.fontSize" = 14;
        "terminal.integrated.cursorBlinking" = false;
        "terminal.integrated.gpuAcceleration" = "off";
        "terminal.integrated.copyOnSelection" = true;
        "terminal.integrated.rightClickBehavior" = "paste";
        "terminal.integrated.scrollback" = 20000;
        "terminal.integrated.shellIntegration.enabled" = true;

        # Navigation, review and debugging
        "diffEditor.ignoreTrimWhitespace" = false;
        "diffEditor.renderSideBySide" = true;
        "mergeEditor.enabled" = true;
        "debug.console.closeOnEnd" = true;
        "debug.openDebug" = "openOnDebugBreak";
        "debug.toolBarLocation" = "docked";
        "problems.autoReveal" = false;

        # Git and GitHub
        "git.enableSmartCommit" = true;
        "git.autofetch" = true;
        "git.autorefresh" = true;
        "git.fetchOnPull" = true;
        "git.pruneOnFetch" = true;
        "git.decorations.enabled" = true;
        "git.confirmSync" = false;
        "git.openRepositoryInParentFolders" = "always";
        "git.ignoreMissingGitWarning" = true;
        "git.inputValidation" = true;
        "git.inputValidationLength" = 72;
        "git.inputValidationSubjectLength" = 50;
        "git.branchSortOrder" = "committerdate";
        "git.branchProtection" = [
          "main"
          "master"
          "prod"
          "production"
          "release/*"
        ];
        "git.branchProtectionPrompt" = "alwaysCommitToNewBranch";
        "git.allowForcePush" = false;
        "git.useForcePushWithLease" = true;
        "git.confirmForcePush" = true;
        "git.addAICoAuthor" = "off";
        "githubPullRequests.createOnPublishBranch" = "never";

        # Copilot stays enabled, but sensitive file types stay excluded.
        "github.copilot.enable" = {
          "*" = true;
          plaintext = false;
          markdown = true;
          scminput = false;
          yaml = true;
          javascript = true;
          typescript = true;
          python = true;
          nix = true;
          env = false;
          dotenv = false;
          ini = false;
          properties = false;
        };
        "github.copilot.editor.enableAutoCompletions" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.chat.welcomeMessage" = "never";
        "github.copilot.chat.otel.enabled" = false;
        "github.copilot.chat.otel.captureContent" = false;
        "github.copilot.chat.otel.dbSpanExporter.enabled" = false;
        "github.copilot.advanced.excludedFiles" = [
          "**/.env"
          "**/.env.*"
          "**/secrets.*"
          "**/*.key"
          "**/*.pem"
          "**/credentials*"
          "**/config/database.*"
          "**/appsettings.*.json"
        ];

        # Language defaults
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
          "editor.tabSize" = 2;
        };
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${pkgs.nil}/bin/nil";
        "nix.serverSettings" = {
          nil = {
            formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
          };
        };
        "nix.formatterPath" = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";

        "[javascript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit";
        };
        "[typescript]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit";
        };
        "[javascriptreact]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit";
        };
        "[typescriptreact]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.codeActionsOnSave"."source.fixAll.eslint" = "explicit";
        };
        "[json]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[jsonc]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[html]" = {
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.linkedEditing" = true;
        };
        "[css]"."editor.defaultFormatter" = "esbenp.prettier-vscode";
        "[markdown]" = {
          "editor.wordWrap" = "on";
          "editor.quickSuggestions" = {
            comments = false;
            strings = false;
            other = false;
          };
        };
        "[dockercompose]" = {
          "editor.defaultFormatter" = "redhat.vscode-yaml";
          "editor.insertSpaces" = true;
          "editor.tabSize" = 2;
        };
        "[github-actions-workflow]"."editor.defaultFormatter" = "redhat.vscode-yaml";
        "[dart]" = {
          "editor.formatOnSave" = true;
          "editor.formatOnType" = true;
          "editor.rulers" = [ 80 ];
          "editor.tabCompletion" = "onlySnippets";
          "editor.wordBasedSuggestions" = "off";
        };
        "dart.showExtensionRecommendations" = false;
        "dart.checkForSdkUpdates" = false;
        "javascript.suggest.autoImports" = true;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "typescript.suggest.autoImports" = true;
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "python.languageServer" = "Pylance";
        "python.analysis.typeCheckingMode" = "basic";
        "python.analysis.autoImportCompletions" = true;
        "python.analysis.autoSearchPaths" = true;
        "python.analysis.indexing" = true;
        "python.analysis.inlayHints.functionReturnTypes" = true;
        "python.analysis.inlayHints.variableTypes" = true;

        # Extension behavior
        "extensions.autoUpdate" = false;
        "extensions.autoCheckUpdates" = false;
        "extensions.ignoreRecommendations" = true;
        "remote.SSH.remotePlatform" = {
          "192.168.1.188" = "linux";
          "192.168.1.180" = "linux";
          "192.168.1.200" = "linux";
          pi5 = "linux";
          mac = "macOS";
        };
        "remote.autoForwardPortsSource" = "hybrid";
        "remote.defaultExtensionsIfInstalledLocally" = [
          "GitHub.copilot"
          "GitHub.copilot-chat"
          "GitHub.vscode-pull-request-github"
        ];

        # Containers / Podman
        "dev.containers.dockerPath" = "podman";
        "dev.containers.dockerComposePath" = "podman-compose";
        "dev.containers.dockerSocketPath" = podmanSocketPath;
        "dev.containers.optimisticallyLaunchDocker" = false;
        "containers.containerClient" = "com.microsoft.visualstudio.containers.podman";
        "containers.orchestratorClient" = "com.microsoft.visualstudio.orchestrators.podmancompose";
        "containers.environment" = {
          DOCKER_HOST = podmanSocket;
          CONTAINER_HOST = podmanSocket;
        };
        "containers.composeBuild" = true;
        "containers.composeDetached" = true;
        "containers.contexts.showInStatusBar" = true;
        "containers.enableComposeLanguageService" = true;
        "docker.extension.enableComposeLanguageServer" = false;
        "cmake.configureOnOpen" = true;
        "cmake.showOptionsMovedNotification" = false;
        "vue.server.hybridMode" = false;
        "claudeCode.preferredLocation" = "panel";
        "claudeCode.useTerminal" = true;

        # Privacy and safety
        "security.workspace.trust.untrustedFiles" = "open";
        "security.allowedUNCHosts" = [ "wsl.localhost" ];
        "telemetry.telemetryLevel" = "off";
        "telemetry.feedback.enabled" = false;
        "redhat.telemetry.enabled" = false;
        "workbench.enableExperiments" = false;
        "workbench.settings.enableNaturalLanguageSearch" = false;
        "python.experiments.enabled" = false;
        "python.experiments.optOutFrom" = [ "All" ];
        "jupyter.experiments.enabled" = false;
        "jupyter.experiments.optOutFrom" = [ "All" ];
        "dataWrangler.experiments.copilot.enabled" = false;
        "docker.lsp.telemetry" = "off";
        "docker.lsp.experimental.vulnerabilityScanning" = false;
        "docker.lsp.experimental.scout.criticalHighVulnerabilities" = false;
        "docker.lsp.experimental.scout.vulnerabilities" = false;
        "yaml.extension.recommendations" = false;

        # Keep local display preferences controlled by this Nix module when
        # Settings Sync is enabled.
        "settingsSync.ignoredSettings" = [
          "workbench.colorTheme"
          "workbench.iconTheme"
          "workbench.sideBar.location"
          "workbench.panel.defaultLocation"
          "workbench.colorCustomizations"
          "editor.tokenColorCustomizations"
          "editor.semanticTokenColorCustomizations"
          "editor.fontFamily"
          "editor.fontSize"
          "editor.lineHeight"
          "terminal.integrated.fontFamily"
          "terminal.integrated.fontSize"
        ];
      };
    };
  };

  # The machine already had imperative VS Code files before this module became
  # declarative. Force only the files owned by programs.vscode so activation
  # cannot fail on stale *.backup files, while extensions remain mutable.
  home.file = {
    ".vscode/argv.json".force = true;
    ".vscode/extensions/.extensions-immutable.json".force = true;
    "/home/marcelo/.config/Code/User/settings.json".force = true;
  };

  # Home Manager's VS Code module writes these files as Nix store symlinks.
  # VS Code expects them to be writable, so convert only the generated
  # symlinks back into normal user-owned files after link generation.
  home.activation.vscodeWritableRuntimeFiles = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    make_writable() {
      path="$1"
      label="$2"

      if [ -L "$path" ]; then
        if [ -n "''${DRY_RUN_CMD:-}" ]; then
          echo "Would convert VS Code $label symlink to writable file"
        else
          tmp="$path.hm-tmp"
          ${pkgs.coreutils}/bin/cp "$path" "$tmp"
          ${pkgs.coreutils}/bin/rm -f "$path"
          ${pkgs.coreutils}/bin/install -m 0644 "$tmp" "$path"
          ${pkgs.coreutils}/bin/rm -f "$tmp"
        fi
      fi
    }

    make_writable "$HOME/.config/Code/User/settings.json" "settings.json"
    make_writable "$HOME/.vscode/argv.json" "argv.json"
  '';

  # Memory-capped wrapper for `code`: launches under app-code.slice
  # (MemoryHigh=10G, MemoryMax=14G; see modules/system/performance.nix).
  home.packages = [
    (lib.hiPrio (pkgs.writeShellScriptBin "code" ''
      exec ${pkgs.systemd}/bin/systemd-run --user --quiet --scope \
        --slice=app-code.slice \
        ${pkgs.vscode}/bin/code "$@"
    ''))
  ];
}
