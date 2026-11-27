# XFeed: lightweight, removable X home-timeline panel for Ghostty + Hyprland.
#
# All implementation lives in this directory. Removing this module's import
# from home.nix removes the commands, package, keybind, and window rules.
# Session cookies are written at runtime under ~/.local/share/xfeed and are
# never stored in this repository or in the Nix store.
{ config, lib, pkgs, ... }:

let
  hyprlandPkg = config.wayland.windowManager.hyprland.package;

  # Pinned, audited read-only GraphQL client. It has no account-write commands.
  x-cli = pkgs.callPackage ./package.nix { };

  xfeed = pkgs.writeShellApplication {
    name = "xfeed";
    runtimeInputs = with pkgs; [
      chafa
      coreutils
      curl
      gnugrep
      jq
      util-linux
      xdg-utils
      x-cli
    ];
    text = builtins.readFile ./xfeed.sh;
  };

  xfeed-configure = pkgs.writeShellApplication {
    name = "xfeed-configure";
    runtimeInputs = [ pkgs.coreutils x-cli ];
    text = builtins.readFile ./xfeed-configure.sh;
  };

  xfeed-toggle = pkgs.writeShellApplication {
    name = "xfeed-toggle";
    runtimeInputs = [
      xfeed
      pkgs.coreutils
      pkgs.ghostty
      pkgs.gnugrep
      pkgs.jq
      pkgs.libnotify
      hyprlandPkg
    ];
    text = builtins.readFile ./xfeed-toggle.sh;
  };

  xfeed-control = pkgs.writeShellApplication {
    name = "xfeed-control";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.jq
      pkgs.libnotify
      hyprlandPkg
    ];
    text = builtins.readFile ./xfeed-control.sh;
  };
in
{
  home.packages = [
    xfeed
    xfeed-configure
    xfeed-toggle
    xfeed-control
  ];

  # Kept separate from the main Hyprland files so this module is removable as
  # one unit. extraConfig is a lines option and is merged with hyprland.lua.
  xdg.configFile."hypr/xfeed.lua".text = ''
    local xfeed = { class = "^(xfeed)$" }

    hl.window_rule({ match = xfeed, float = true })
    hl.window_rule({ match = xfeed, size = {680, 800} })
    hl.window_rule({ match = xfeed, move = {"monitor_w-700", 46} })
    hl.window_rule({ match = xfeed, persistent_size = true })
    hl.window_rule({ match = xfeed, no_initial_focus = true })
    hl.window_rule({ match = xfeed, no_blur = true })
    hl.window_rule({ match = xfeed, no_shadow = true })
    hl.window_rule({ match = xfeed, no_dim = true })
    hl.window_rule({ match = xfeed, rounding = 0 })
    hl.window_rule({ match = xfeed, border_size = 0 })
    hl.window_rule({ match = xfeed, no_shortcuts_inhibit = true })

    -- SUPER+R is intentionally owned by this standalone module.
    hl.bind("SUPER + R", hl.dsp.exec_cmd("${lib.getExe xfeed-toggle}"))
  '';

  wayland.windowManager.hyprland.extraConfig = ''
    require("xfeed")
  '';
}
