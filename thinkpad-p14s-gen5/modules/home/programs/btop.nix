# btop system monitor configuration
{ ... }:

{
  # btop theme (Monokai Pro Ristretto)
  xdg.configFile."btop/themes/ristretto.theme".text = ''
    # Monokai Pro (Filter Ristretto) - btop theme

    # Main background
    theme[main_bg]="#2c2421"

    # Main text color
    theme[main_fg]="#e6d9db"

    # Title color for boxes
    theme[title]="#e6d9db"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="#fd6883"

    # Background color of selected item in processes box
    theme[selected_bg]="#3d2f2a"

    # Foreground color of selected item in processes box
    theme[selected_fg]="#f9cc6c"

    # Color of inactive/disabled text
    theme[inactive_fg]="#72696a"

    # Color of text appearing on top of graphs
    theme[graph_text]="#e6d9db"

    # Background color of the percentage meters
    theme[meter_bg]="#3d2f2a"

    # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
    theme[proc_misc]="#85dacc"

    # CPU, Memory, Network, Proc box outline colors
    theme[cpu_box]="#5b4a45"
    theme[mem_box]="#5b4a45"
    theme[net_box]="#5b4a45"
    theme[proc_box]="#5b4a45"

    # Box divider line and small boxes line color
    theme[div_line]="#72696a"

    # Temperature graph color (Fully red @100C, Fully blue @0C)
    theme[temp_start]="#a8a9eb"
    theme[temp_mid]="#f38d70"
    theme[temp_end]="#fd6a85"

    # CPU graph colors (Fully red @100%, Fully blue @0%)
    theme[cpu_start]="#adda78"
    theme[cpu_mid]="#f9cc6c"
    theme[cpu_end]="#fd6883"

    # Memory/disks free meter
    theme[free_start]="#72696a"
    theme[free_mid]="#85dacc"
    theme[free_end]="#a8a9eb"

    # Memory cached meter
    theme[cached_start]="#72696a"
    theme[cached_mid]="#f9cc6c"
    theme[cached_end]="#fd6883"

    # Memory available meter
    theme[available_start]="#72696a"
    theme[available_mid]="#adda78"
    theme[available_end]="#85dacc"

    # Memory used meter
    theme[used_start]="#fd6883"
    theme[used_mid]="#f38d70"
    theme[used_end]="#f9cc6c"

    # Download graph colors (Fully red @100%, Fully blue @0%)
    theme[download_start]="#a8a9eb"
    theme[download_mid]="#c3b7b8"
    theme[download_end]="#fd6883"

    # Upload graph colors (Fully red @100%, Fully blue @0%)
    theme[upload_start]="#adda78"
    theme[upload_mid]="#f9cc6c"
    theme[upload_end]="#fd6883"

    # Process box color gradient for threads, mem and cpu usage (Fully red @100%, Fully blue @0%)
    theme[process_start]="#85dacc"
    theme[process_mid]="#f9cc6c"
    theme[process_end]="#fd6883"
  '';

  # btop configuration
  programs.btop = {
    enable = true;
    settings = {
      # Theme
      color_theme = "ristretto";
      theme_background = true;
      truecolor = true;
      force_tty = false;

      # UI
      vim_keys = true;  # h,j,k,l navigation
      rounded_corners = true;
      graph_symbol = "braille";
      shown_boxes = "cpu mem net proc";

      # Update time in milliseconds
      update_ms = 2000;

      # Processes
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = false;

      # CPU
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_uptime = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      cpu_core_map = "";
      temp_scale = "celsius";
      base_10_sizes = false;
      show_cpu_freq = true;
      clock_format = "%H:%M";
      background_update = true;
      custom_cpu_name = "";
      disks_filter = "";
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      zfs_hide_datasets = false;
      disk_free_priv = false;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;
      io_graph_speeds = "";
      net_download = "100M";
      net_upload = "100M";
      net_auto = true;
      net_sync = true;
      net_iface = "";
      show_battery = true;
      selected_battery = "Auto";
      log_level = "WARNING";
    };
  };
}
