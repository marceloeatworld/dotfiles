# MangoHud - In-game overlay for GPU/CPU/FPS monitoring
# Usage in Steam: Add "mangohud %command%" to launch options
# Usage outside: MANGOHUD=1 ./game or mangohud ./game
{ ... }:

{
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;  # Only activate when explicitly called

    settings = {
      # ── Display Position ──
      position = "top-left";
      round_corners = 8;
      background_alpha = 0.5;

      # ── FPS & Frametime ──
      fps = true;
      fps_limit = 0;  # No limit (use game's vsync)
      frametime = true;
      frame_timing = true;

      # ── GPU Stats (AMD Radeon 780M) ──
      gpu_stats = true;
      gpu_temp = true;
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_power = true;
      gpu_load_change = true;  # Color changes with load

      # ── CPU Stats (Ryzen 7 PRO 8840HS) ──
      cpu_stats = true;
      cpu_temp = true;
      cpu_power = true;
      cpu_mhz = true;
      cpu_load_change = true;  # Color changes with load

      # ── RAM & VRAM ──
      ram = true;
      vram = true;

      # ── Vulkan/OpenGL Info ──
      gpu_name = true;
      vulkan_driver = true;

      # ── Toggle Key ──
      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_R+F11";

      # ── Theme (Monokai Pro Ristretto inspired) ──
      text_color = "F5F5F1";
      gpu_color = "F38D70";
      cpu_color = "A8DC76";
      vram_color = "FFD76D";
      ram_color = "AB9DF2";
      engine_color = "FC9867";
      frametime_color = "78DCE8";
      background_color = "2D2A2E";
    };
  };
}
