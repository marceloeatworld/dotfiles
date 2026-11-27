# User-level fontconfig overrides
# NOTE: Fonts are installed system-wide in modules/system/fonts.nix
{ config, ... }:

let
  theme = config.theme;
in

{
  # User-specific fontconfig settings
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Default font substitutions from theme -->
      <match target="pattern">
        <test qual="any" name="family">
          <string>sans-serif</string>
        </test>
        <edit name="family" mode="assign" binding="strong">
          <string>${theme.fonts.sans}</string>
        </edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family">
          <string>serif</string>
        </test>
        <edit name="family" mode="assign" binding="strong">
          <string>Noto Serif</string>
        </edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family">
          <string>monospace</string>
        </test>
        <edit name="family" mode="assign" binding="strong">
          <string>${theme.fonts.mono}</string>
        </edit>
      </match>

      <!-- System UI font aliases from theme -->
      <alias binding="strong">
        <family>system-ui</family>
        <prefer><family>${theme.fonts.sans}</family></prefer>
      </alias>

      <alias binding="strong">
        <family>ui-monospace</family>
        <prefer><family>${theme.fonts.mono}</family></prefer>
      </alias>

      <alias binding="strong">
        <family>-apple-system</family>
        <prefer><family>${theme.fonts.sans}</family></prefer>
      </alias>

      <alias binding="strong">
        <family>BlinkMacSystemFont</family>
        <prefer><family>${theme.fonts.sans}</family></prefer>
      </alias>
    </fontconfig>
  '';
}
