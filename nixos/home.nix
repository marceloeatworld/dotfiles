{ inputs, config, pkgs, ...}:

{
home.username = "marcelo";
home.homeDirectory = "/home/marcelo";
home.stateVersion = "23.11";

home.packages = [




];
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    __GL_GSYNC_ALLOWED = "0";
    __GL_VRR_ALLOWED = "0";
    _JAVA_AWT_WM_NONEREPARENTING = "1";
    SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
    DISABLE_QT5_COMPAT = "0";
    GDK_BACKEND = "wayland";
    ANKI_WAYLAND = "1";
    DIRENV_LOG_FORMAT = "";
    WLR_DRM_NO_ATOMIC = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORM = "xcb";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_STYLE_OVERRIDE = "kvantum";
    MOZ_ENABLE_WAYLAND = "1";
    WLR_BACKEND = "vulkan";
    WLR_RENDERER = "vulkan";
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_SESSION_TYPE = "wayland";
    SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    GTK_THEME = "Catppuccin-Mocha-Compact-Lavender-Dark";
  };
programs.home-manager.enable = true;
imports = [

	./app/bat.nix
	./app/btop.nix
	./app/discord.nix
	./app/floorp/floorp.nix
	./app/gaming.nix
	./app/gtk.nix
	./app/micro.nix
	./app/nvim.nix
	./app/waybar
	./app/packages.nix
	./app/swaylock.nix
	./app/starship.nix
	./app/scripts/scripts.nix
	./app/mako.nix
	./app/wofi.nix
	./app/vscodium.nix
	./app/zsh.nix
	./app/git.nix
	./app/kitty.nix
	];

}
