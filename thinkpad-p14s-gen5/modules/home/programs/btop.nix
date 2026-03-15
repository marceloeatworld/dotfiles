# btop system monitor configuration
{ config, ... }:

let
  theme = config.theme;
in
{
  # btop theme (from theme.nix)
  xdg.configFile."btop/themes/current.theme".text = ''
    # btop theme - auto-generated from theme.nix

    theme[main_bg]="${theme.colors.background}"
    theme[main_fg]="${theme.colors.foreground}"
    theme[title]="${theme.colors.foreground}"
    theme[hi_fg]="${theme.colors.yellow}"
    theme[selected_bg]="${theme.colors.selection}"
    theme[selected_fg]="${theme.colors.yellow}"
    theme[inactive_fg]="${theme.colors.comment}"
    theme[graph_text]="${theme.colors.foreground}"
    theme[meter_bg]="${theme.colors.surface}"
    theme[proc_misc]="${theme.colors.cyan}"

    theme[cpu_box]="${theme.colors.border}"
    theme[mem_box]="${theme.colors.border}"
    theme[net_box]="${theme.colors.border}"
    theme[proc_box]="${theme.colors.border}"
    theme[div_line]="${theme.colors.comment}"

    theme[temp_start]="${theme.colors.cyan}"
    theme[temp_mid]="${theme.colors.yellow}"
    theme[temp_end]="${theme.colors.red}"

    theme[cpu_start]="${theme.colors.green}"
    theme[cpu_mid]="${theme.colors.yellow}"
    theme[cpu_end]="${theme.colors.red}"

    theme[free_start]="${theme.colors.comment}"
    theme[free_mid]="${theme.colors.cyan}"
    theme[free_end]="${theme.colors.green}"

    theme[cached_start]="${theme.colors.comment}"
    theme[cached_mid]="${theme.colors.yellow}"
    theme[cached_end]="${theme.colors.orange}"

    theme[available_start]="${theme.colors.comment}"
    theme[available_mid]="${theme.colors.green}"
    theme[available_end]="${theme.colors.cyan}"

    theme[used_start]="${theme.colors.green}"
    theme[used_mid]="${theme.colors.yellow}"
    theme[used_end]="${theme.colors.red}"

    theme[download_start]="${theme.colors.cyan}"
    theme[download_mid]="${theme.colors.magenta}"
    theme[download_end]="${theme.colors.red}"

    theme[upload_start]="${theme.colors.green}"
    theme[upload_mid]="${theme.colors.yellow}"
    theme[upload_end]="${theme.colors.red}"

    theme[process_start]="${theme.colors.cyan}"
    theme[process_mid]="${theme.colors.yellow}"
    theme[process_end]="${theme.colors.red}"
  '';

  # btop configuration
  programs.btop = {
    enable = true;
    settings = {
      # Theme
      color_theme = "current";
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
