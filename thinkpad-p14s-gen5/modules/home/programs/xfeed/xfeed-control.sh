set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
runtime_base="${XDG_RUNTIME_DIR:-/tmp}"

config_dir="$config_home/xfeed"
cache_dir="$cache_home/xfeed"
state_dir="$state_home/xfeed"
data_dir="$data_home/xfeed"
runtime_dir="$runtime_base/xfeed"
disabled_file="$state_dir/disabled"
pid_file="$runtime_dir/reader.pid"
session_file="$data_dir/x-cli/session.json"

reader_is_running() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  grep -aq 'xfeed' "/proc/$pid/cmdline" 2>/dev/null
}

stop_reader() {
  if [[ -r "$pid_file" ]]; then
    pid=$(<"$pid_file")
    if reader_is_running "$pid"; then
      kill -CONT "$pid" 2>/dev/null || true
      kill -TERM "$pid" 2>/dev/null || true
    fi
  fi
}

close_panel() {
  address=$(hyprctl clients -j 2>/dev/null \
    | jq -r 'first(.[] | select(.class == "xfeed")) | .address // empty')
  if [[ -n "$address" ]]; then
    hyprctl eval "hl.dispatch(hl.dsp.window.close({ window = 'address:$address' }))" >/dev/null 2>&1 || true
  fi
}

status() {
  if [[ -e "$disabled_file" ]]; then
    printf 'XFeed: disabled\n'
  else
    printf 'XFeed: enabled\n'
  fi

  if [[ -s "$session_file" ]]; then
    printf 'Session cookies: configured locally\n'
  else
    printf 'Session cookies: missing (run xfeed-configure)\n'
  fi

  if [[ -r "$pid_file" ]] && reader_is_running "$(<"$pid_file")"; then
    printf 'Panel: running\n'
  else
    printf 'Panel: stopped\n'
  fi
}

case "${1:-status}" in
  enable)
    mkdir -p "$state_dir"
    rm -f "$disabled_file"
    printf 'XFeed enabled. Press Super+R to show it.\n'
    ;;
  disable)
    mkdir -p "$state_dir"
    : > "$disabled_file"
    stop_reader
    close_panel
    rm -rf "$runtime_dir"
    notify-send -a XFeed 'XFeed disabled' 'Run xfeed-control enable to reactivate it.' 2>/dev/null || true
    printf 'XFeed disabled. Local session cookies were preserved.\n'
    ;;
  status)
    status
    ;;
  purge)
    printf 'This removes XFeed session cookies, cache, and local state. Continue? [y/N] '
    read -r answer
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      printf 'Cancelled.\n'
      exit 0
    fi
    stop_reader
    close_panel
    rm -rf "$config_dir" "$cache_dir" "$state_dir" "$data_dir" "$runtime_dir"
    printf 'All local XFeed data was removed.\n'
    ;;
  *)
    printf 'usage: xfeed-control {enable|disable|status|purge}\n' >&2
    exit 2
    ;;
esac
