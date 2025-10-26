# Fastfetch - System information tool
{ pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        type = "builtin";
        source = "nixos_small";
        color = {
          "1" = "blue";
          "2" = "blue";
        };
        padding = {
          top = 1;
          left = 2;
          right = 4;
        };
      };

      display = {
        separator = " → ";
      };

      modules = [
        {
          type = "custom";
          format = "┌─────────── Hardware ───────────┐";
        }
        {
          type = "host";
          key = "󰇅 PC";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "󰻠 CPU";
          keyColor = "green";
        }
        {
          type = "gpu";
          key = "󰾲 GPU";
          keyColor = "green";
        }
        {
          type = "display";
          key = "󰍹 Display";
          keyColor = "green";
        }
        {
          type = "disk";
          key = "󰋊 Disk";
          keyColor = "green";
        }
        {
          type = "memory";
          key = "󰍛 Memory";
          keyColor = "green";
        }
        {
          type = "swap";
          key = "󰾱 Swap";
          keyColor = "green";
        }
        "break"
        {
          type = "custom";
          format = "├─────────── Software ───────────┤";
        }
        {
          type = "os";
          key = " OS";
          keyColor = "blue";
        }
        {
          type = "kernel";
          key = " Kernel";
          keyColor = "blue";
        }
        {
          type = "wm";
          key = "󰨇 WM";
          keyColor = "blue";
        }
        {
          type = "de";
          key = " DE";
          keyColor = "blue";
        }
        {
          type = "terminal";
          key = " Terminal";
          keyColor = "blue";
        }
        {
          type = "packages";
          key = "󰏖 Packages";
          keyColor = "blue";
        }
        {
          type = "theme";
          key = "󰉼 Theme";
          keyColor = "blue";
        }
        {
          type = "icons";
          key = "󰀻 Icons";
          keyColor = "blue";
        }
        {
          type = "cursor";
          key = "󰇀 Cursor";
          keyColor = "blue";
        }
        {
          type = "font";
          key = "󰛖 Font";
          keyColor = "blue";
        }
        "break"
        {
          type = "custom";
          format = "├──────────── System ────────────┤";
        }
        {
          type = "uptime";
          key = "󰔚 Uptime";
          keyColor = "magenta";
        }
        "break"
        {
          type = "custom";
          format = "└────────────────────────────────┘";
        }
        {
          type = "colors";
          paddingLeft = 5;
          symbol = "circle";
        }
      ];
    };
  };
}
