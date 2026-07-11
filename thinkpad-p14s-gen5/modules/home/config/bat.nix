# Bat (cat replacement) and its theme, generated from config.theme.
# Extracted from programs/shell.nix to keep the ~330-line theme XML out of it.
{ config, ... }:

let
  theme = config.theme;
in
{
  # Bat (cat replacement) - theme from theme.nix
  programs.bat = {
    enable = true;
    config = {
      theme = "current";
      style = "numbers,changes";
    };
  };

  # Bat theme (from theme.nix)
  home.file.".config/bat/themes/current.tmTheme".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>name</key>
      <string>Current Theme</string>
      <key>settings</key>
      <array>
        <!-- Global Settings -->
        <dict>
          <key>settings</key>
          <dict>
            <key>background</key>
            <string>${theme.colors.background}</string>
            <key>foreground</key>
            <string>${theme.colors.foreground}</string>
            <key>caret</key>
            <string>${theme.colors.accent}</string>
            <key>lineHighlight</key>
            <string>${theme.colors.surface}</string>
            <key>selection</key>
            <string>${theme.colors.selection}</string>
            <key>selectionBorder</key>
            <string>${theme.colors.selection}</string>
            <key>findHighlight</key>
            <string>${theme.colors.accent}</string>
            <key>guide</key>
            <string>${theme.colors.border}</string>
            <key>activeGuide</key>
            <string>${theme.colors.foreground}</string>
          </dict>
        </dict>
        <!-- Comments -->
        <dict>
          <key>name</key>
          <string>Comment</string>
          <key>scope</key>
          <string>comment, punctuation.definition.comment</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.comment}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Strings -->
        <dict>
          <key>name</key>
          <string>String</string>
          <key>scope</key>
          <string>string</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.yellow}</string>
          </dict>
        </dict>
        <!-- Numbers -->
        <dict>
          <key>name</key>
          <string>Number</string>
          <key>scope</key>
          <string>constant.numeric</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.magenta}</string>
          </dict>
        </dict>
        <!-- Constants -->
        <dict>
          <key>name</key>
          <string>Constant</string>
          <key>scope</key>
          <string>constant, constant.language, constant.character</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.magenta}</string>
          </dict>
        </dict>
        <!-- Keywords -->
        <dict>
          <key>name</key>
          <string>Keyword</string>
          <key>scope</key>
          <string>keyword, storage.type, storage.modifier</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Operators -->
        <dict>
          <key>name</key>
          <string>Operator</string>
          <key>scope</key>
          <string>keyword.operator</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Functions -->
        <dict>
          <key>name</key>
          <string>Function</string>
          <key>scope</key>
          <string>entity.name.function, support.function, meta.function-call</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.green}</string>
          </dict>
        </dict>
        <!-- Classes -->
        <dict>
          <key>name</key>
          <string>Class</string>
          <key>scope</key>
          <string>entity.name.class, entity.name.type, support.class</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Variables -->
        <dict>
          <key>name</key>
          <string>Variable</string>
          <key>scope</key>
          <string>variable, variable.parameter</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.foreground}</string>
          </dict>
        </dict>
        <!-- Parameters -->
        <dict>
          <key>name</key>
          <string>Parameter</string>
          <key>scope</key>
          <string>variable.parameter</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.orange}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Tags (HTML/XML) -->
        <dict>
          <key>name</key>
          <string>Tag</string>
          <key>scope</key>
          <string>entity.name.tag</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Attributes -->
        <dict>
          <key>name</key>
          <string>Attribute</string>
          <key>scope</key>
          <string>entity.other.attribute-name</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Support -->
        <dict>
          <key>name</key>
          <string>Support</string>
          <key>scope</key>
          <string>support.type, support.constant</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
          </dict>
        </dict>
        <!-- Punctuation -->
        <dict>
          <key>name</key>
          <string>Punctuation</string>
          <key>scope</key>
          <string>punctuation</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.foreground}</string>
          </dict>
        </dict>
        <!-- Invalid -->
        <dict>
          <key>name</key>
          <string>Invalid</string>
          <key>scope</key>
          <string>invalid</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
            <key>background</key>
            <string>${theme.colors.surface}</string>
          </dict>
        </dict>
        <!-- Markdown Heading -->
        <dict>
          <key>name</key>
          <string>Markdown Heading</string>
          <key>scope</key>
          <string>markup.heading, entity.name.section</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
            <key>fontStyle</key>
            <string>bold</string>
          </dict>
        </dict>
        <!-- Markdown Bold -->
        <dict>
          <key>name</key>
          <string>Markdown Bold</string>
          <key>scope</key>
          <string>markup.bold</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.orange}</string>
            <key>fontStyle</key>
            <string>bold</string>
          </dict>
        </dict>
        <!-- Markdown Italic -->
        <dict>
          <key>name</key>
          <string>Markdown Italic</string>
          <key>scope</key>
          <string>markup.italic</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.yellow}</string>
            <key>fontStyle</key>
            <string>italic</string>
          </dict>
        </dict>
        <!-- Markdown Link -->
        <dict>
          <key>name</key>
          <string>Markdown Link</string>
          <key>scope</key>
          <string>markup.underline.link, string.other.link</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.cyan}</string>
          </dict>
        </dict>
        <!-- Markdown Code -->
        <dict>
          <key>name</key>
          <string>Markdown Code</string>
          <key>scope</key>
          <string>markup.raw, markup.inline.raw</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.green}</string>
          </dict>
        </dict>
        <!-- Diff Added -->
        <dict>
          <key>name</key>
          <string>Diff Added</string>
          <key>scope</key>
          <string>markup.inserted, meta.diff.header.to-file</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.green}</string>
          </dict>
        </dict>
        <!-- Diff Removed -->
        <dict>
          <key>name</key>
          <string>Diff Removed</string>
          <key>scope</key>
          <string>markup.deleted, meta.diff.header.from-file</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.red}</string>
          </dict>
        </dict>
        <!-- Diff Changed -->
        <dict>
          <key>name</key>
          <string>Diff Changed</string>
          <key>scope</key>
          <string>markup.changed</string>
          <key>settings</key>
          <dict>
            <key>foreground</key>
            <string>${theme.colors.orange}</string>
          </dict>
        </dict>
      </array>
    </dict>
    </plist>
  '';
}
