{ ... }:
{
  programs.waybar.settings.mainBar = {
    position= "top";
    layer= "top";
    height= 5;
    margin-top= 0;
    margin-bottom= 0;
    margin-left= 0;
    margin-right= 0;
    modules-left= [
        "custom/launcher" 
        "hyprland/workspaces"
    ];
    modules-center= [
        "clock"
    ];
    modules-right= [
        "tray" 
        "cpu"
        "memory"
        "disk"
        "pulseaudio" 
        "network"
    ];
    clock= {
        calendar = {
          format = { today = "<span color='#b4befe'><b>{}</b></span>"; };
        };
        format = " {:%H:%M}";
        tooltip= "true";
        tooltip-format= "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt= " {:%d/%m}";
    };
    "hyprland/workspaces"= {
        active-only= false;
        disable-scroll= true;
        format = "{icon}";
        on-click= "activate";
        format-icons= {
            "1"= "󰈹";
            "2"= "";
            "3"= "󰘙";
            "4"= "󰙯";
            "5"= "";
            "6"= "";
            urgent= "";
            default = "";
            sort-by-number= true;
        };
        persistent-workspaces = {
            "1"= [];
            "2"= [];
            "3"= [];
            "4"= [];
            "5"= [];
        };
    };
    memory= {
        format-alt= "  {}%";
        format= "  {used} GiB"; # 
        interval= 2;
    };
    cpu= {
        format-alt= "  {usage}%";
        format= "  {avg_frequency} GHz";
        interval= 2;
    };
    disk = {
        # path = "/";
        format = "󰋊 {percentage_used}%";
        interval= 60;
    };
    network = {
        format-wifi = "  {signalStrength}%";
        format-ethernet = "󰀂 ";
        tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
        format-linked = "{ifname} (No IP)";
        format-disconnected = "󰖪 ";
    };
    tray= {
        icon-size= 20;
        spacing= 8;
    };
    pulseaudio= {
        format= "{icon} {volume}%";
        format-muted= "󰖁 ";
        format-icons= {
            default= [" "];
        };
        scroll-step= 5;
        on-click= "pamixer -t";
    };
    "custom/launcher"= {
        format= "";
        on-click= "pkill wofi || wofi --show drun";
        on-click-right= "pkill wofi || wallpaper-picker"; 
        tooltip= "false";
    };
  };
}
