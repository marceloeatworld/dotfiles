set -euo pipefail

state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
runtime_base="${XDG_RUNTIME_DIR:-/tmp}"
state_dir="$state_home/xfeed"
runtime_dir="$runtime_base/xfeed"
disabled_file="$state_dir/disabled"
pid_file="$runtime_dir/reader.pid"
visible_file="$runtime_dir/visible"

if [[ -e "$disabled_file" ]]; then
  notify-send -a XFeed 'XFeed is disabled' 'Run xfeed-control enable to reactivate it.' 2>/dev/null || true
  exit 0
fi

mkdir -p "$runtime_dir"
chmod 700 "$runtime_dir"

client_json=$(hyprctl clients -j 2>/dev/null || printf '[]')
address=$(jq -r 'first(.[] | select(.class == "xfeed")) | .address // empty' <<< "$client_json")

reader_pid=""
if [[ -r "$pid_file" ]]; then
  reader_pid=$(<"$pid_file")
fi

reader_is_running() {
  [[ "$reader_pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$reader_pid" 2>/dev/null || return 1
  grep -aq 'xfeed' "/proc/$reader_pid/cmdline" 2>/dev/null
}

is_visible() {
  if hyprctl monitors -j 2>/dev/null \
    | jq -e 'any(.specialWorkspace.name == "special:xfeed")' >/dev/null 2>&1; then
    return 0
  fi
  [[ -e "$visible_file" ]]
}

toggle_special() {
  hyprctl eval "hl.dispatch(hl.dsp.workspace.toggle_special('xfeed'))" >/dev/null
}

if [[ -z "$address" ]]; then
  rm -f "$pid_file" "$visible_file"
  ghostty \
    --class=xfeed \
    --font-size=15 \
    --background=101318 \
    --foreground=f5f7ff \
    --background-opacity=0.18 \
    --scrollback-limit=0 \
    --scrollbar=never \
    --resize-overlay=never \
    --window-padding-x=10 \
    --window-padding-y=8 \
    --window-padding-balance=true \
    --window-decoration=false \
    --confirm-close-surface=false \
    -e xfeed &
  disown

  # Wait briefly for Ghostty to expose its Wayland window.
  for _ in $(seq 1 50); do
    sleep 0.1
    address=$(hyprctl clients -j 2>/dev/null \
      | jq -r 'first(.[] | select(.class == "xfeed")) | .address // empty')
    [[ -n "$address" ]] && break
  done

  if [[ -z "$address" ]]; then
    notify-send -a XFeed 'Unable to open XFeed' 'Ghostty did not expose the xfeed window.' 2>/dev/null || true
    exit 1
  fi

  # Hyprland 0.55 uses the Lua parser, so runtime dispatch goes through eval.
  hyprctl eval "(function()
    local win = 'address:$address'
    hl.dispatch(hl.dsp.window.move({ workspace = 'special:xfeed', follow = false, window = win }))
    hl.dispatch(hl.dsp.workspace.toggle_special('xfeed'))
    hl.dispatch(hl.dsp.focus({ window = win }))
  end)()" >/dev/null
  : > "$visible_file"
  exit 0
fi

if is_visible; then
  toggle_special
  rm -f "$visible_file"
  if reader_is_running; then
    kill -STOP "$reader_pid" 2>/dev/null || true
  fi
else
  if reader_is_running; then
    kill -CONT "$reader_pid" 2>/dev/null || true
  fi
  toggle_special
  : > "$visible_file"
  hyprctl eval "hl.dispatch(hl.dsp.focus({ window = 'address:$address' }))" >/dev/null 2>&1 || true
fi
