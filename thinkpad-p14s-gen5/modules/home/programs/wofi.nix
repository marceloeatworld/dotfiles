# Wofi application launcher configuration
{ ... }:

{
  programs.wofi = {
    enable = true;

    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = true;
    };

    style = ''
      window {
        margin: 0px;
        border: 2px solid #cba6f7;
        border-radius: 8px;
        background-color: rgba(30, 30, 46, 0.95);
        font-family: "JetBrainsMono Nerd Font";
        font-size: 13px;
      }

      #input {
        margin: 10px;
        padding: 8px;
        border: 2px solid #313244;
        border-radius: 8px;
        background-color: #1e1e2e;
        color: #cdd6f4;
      }

      #inner-box {
        margin: 5px;
        padding: 10px;
        background-color: transparent;
      }

      #outer-box {
        margin: 5px;
        padding: 10px;
        background-color: transparent;
      }

      #scroll {
        margin: 0px;
        padding: 0px;
      }

      #text {
        margin: 5px;
        padding: 5px;
        color: #cdd6f4;
      }

      #entry {
        padding: 8px;
        margin: 2px;
        border-radius: 8px;
        background-color: transparent;
      }

      #entry:selected {
        background-color: #45475a;
      }

      #entry:selected #text {
        color: #cba6f7;
        font-weight: bold;
      }
    '';
  };
}
