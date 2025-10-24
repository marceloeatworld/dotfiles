# Font configuration (fontconfig)
{ pkgs, ... }:

{
  # Font packages
  home.packages = with pkgs; [
    liberation-fonts  # Liberation Sans, Liberation Serif
    cascadia-code     # CaskaydiaMono Nerd Font (Cascadia Code Nerd Font)
  ];

  # Fontconfig settings
  xdg.configFile."fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <!-- Default font substitutions -->
      <match target="pattern">
        <test qual="any" name="family">
          <string>sans-serif</string>
        </test>
        <edit name="family" mode="assign" binding="strong">
          <string>Liberation Sans</string>
        </edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family">
          <string>serif</string>
        </test>
        <edit name="family" mode="assign" binding="strong">
          <string>Liberation Serif</string>
        </edit>
      </match>

      <match target="pattern">
        <test qual="any" name="family">
          <string>monospace</string>
        </test>
        <edit name="family" mode="assign" binding="strong">
          <string>CaskaydiaMono Nerd Font</string>
        </edit>
      </match>

      <!-- System UI font aliases -->
      <alias binding="strong">
        <family>system-ui</family>
        <prefer><family>Liberation Sans</family></prefer>
      </alias>

      <alias binding="strong">
        <family>ui-monospace</family>
        <prefer><family>monospace</family></prefer>
      </alias>

      <alias binding="strong">
        <family>-apple-system</family>
        <prefer><family>Liberation Sans</family></prefer>
      </alias>

      <alias binding="strong">
        <family>BlinkMacSystemFont</family>
        <prefer><family>Liberation Sans</family></prefer>
      </alias>
    </fontconfig>
  '';
}
