# btop system monitor configuration
{ config, ... }:

let
  theme = config.theme;
in
{
  # btop theme (Monokai Pro Ristretto)
  xdg.configFile."btop/themes/ristretto.theme".text = ''
    # Monokai Pro (Filter Ristretto) - btop theme

    # Main background
    theme[main_bg]="${theme.colors.background}"

    # Main text color
    theme[main_fg]="${theme.colors.foreground}"

    # Title color for boxes
    theme[title]="${theme.colors.foreground}"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="${theme.colors.red}"

    # Background color of selected item in processes box
    theme[selected_bg]="#3d2f2a"

    # Foreground color of selected item in processes box
    theme[selected_fg]="${theme.colors.yellow}"

    # Color of inactive/disabled text
    theme[inactive_fg]="${theme.colors.comment}"

    # Color of text appearing on top of graphs
    theme[graph_text]="${theme.colors.foreground}"

    # Background color of the percentage meters
    theme[meter_bg]="#3d2f2a"

    # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
    theme[proc_misc]="${theme.colors.cyan}"

    # CPU, Memory, Network, Proc box outline colors
    theme[cpu_box]="#5b4a45"
    theme[mem_box]="#5b4a45"
    theme[net_box]="#5b4a45"
    theme[proc_box]="#5b4a45"

    # Box divider line and small boxes line color
    theme[div_line]="${theme.colors.comment}"

    # Temperature graph color (Fully red @100C, Fully blue @0C)
    theme[temp_start]="${theme.colors.magenta}"
    theme[temp_mid]="${theme.colors.orange}"
    theme[temp_end]="#fd6a85"

    # CPU graph colors (Fully red @100%, Fully blue @0%)
    theme[cpu_start]="${theme.colors.green}"
    theme[cpu_mid]="${theme.colors.yellow}"
    theme[cpu_end]="${theme.colors.red}"

    # Memory/disks free meter
    theme[free_start]="${theme.colors.comment}"
    theme[free_mid]="${theme.colors.cyan}"
    theme[free_end]="${theme.colors.magenta}"

    # Memory cached meter
    theme[cached_start]="${theme.colors.comment}"
    theme[cached_mid]="${theme.colors.yellow}"
    theme[cached_end]="${theme.colors.red}"

    # Memory available meter
    theme[available_start]="${theme.colors.comment}"
    theme[available_mid]="${theme.colors.green}"
    theme[available_end]="${theme.colors.cyan}"

    # Memory used meter
    theme[used_start]="${theme.colors.red}"
    theme[used_mid]="${theme.colors.orange}"
    theme[used_end]="${theme.colors.yellow}"

    # Download graph colors (Fully red @100%, Fully blue @0%)
    theme[download_start]="${theme.colors.magenta}"
    theme[download_mid]="${theme.colors.foregroundDim}"
    theme[download_end]="${theme.colors.red}"

    # Upload graph colors (Fully red @100%, Fully blue @0%)
    theme[upload_start]="${theme.colors.green}"
    theme[upload_mid]="${theme.colors.yellow}"
    theme[upload_end]="${theme.colors.red}"

    # Process box color gradient for threads, mem and cpu usage (Fully red @100%, Fully blue @0%)
    theme[process_start]="${theme.colors.cyan}"
    theme[process_mid]="${theme.colors.yellow}"
    theme[process_end]="${theme.colors.red}"
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
