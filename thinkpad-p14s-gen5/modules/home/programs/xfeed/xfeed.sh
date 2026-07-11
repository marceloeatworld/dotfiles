set -euo pipefail

cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
runtime_base="${XDG_RUNTIME_DIR:-/tmp}"

cache_dir="$cache_home/xfeed"
state_dir="$state_home/xfeed"
x_data_dir="$data_home/xfeed/x-cli"
runtime_dir="$runtime_base/xfeed"
session_file="$x_data_dir/session.json"
response_file="$cache_dir/timeline.jsonl"
cards_file="$cache_dir/cards.jsonl"
seen_file="$state_dir/seen-posts"
pid_file="$runtime_dir/reader.pid"

mkdir -p "$cache_dir" "$state_dir" "$runtime_dir"
chmod 700 "$cache_dir" "$state_dir" "$runtime_dir"
printf '%s\n' "$$" > "$pid_file"

cleanup() {
  rm -f "$pid_file" "$runtime_dir/visible"
  printf '\033[0m\033[?25h'
}
trap cleanup EXIT
trap 'exit 0' HUP INT TERM

bold=$'\033[1m'
dim=$'\033[2m'
cyan=$'\033[38;5;81m'
blue=$'\033[38;5;75m'
muted=$'\033[38;5;245m'
red=$'\033[38;5;203m'
reset=$'\033[0m'

current_url=""
current_cards="[]"
selected_index=0
paused=0
speed_offset=0
force_refresh=0
needs_redraw=0

trap 'needs_redraw=1' WINCH

terminal_width() {
  local width
  width=$(tput cols 2>/dev/null || printf '80')
  (( width < 24 )) && width=24
  printf '%s' "$width"
}

terminal_height() {
  local height
  height=$(tput lines 2>/dev/null || printf '24')
  (( height < 8 )) && height=8
  printf '%s' "$height"
}

rule() {
  local width line
  width=$(terminal_width)
  printf -v line '%*s' "$width" ''
  printf '%s\n' "${line// /─}"
}

wrap_text() {
  local width
  width=$(terminal_width)
  (( width > 2 )) && width=$((width - 2))
  fold -s -w "$width"
}

wrapped_rows() {
  local text="$1" width rows
  [[ -n "$text" ]] || {
    printf '0'
    return
  }
  width=$(terminal_width)
  (( width > 2 )) && width=$((width - 2))
  rows=$(printf '%s\n' "$text" | fold -s -w "$width" | wc -l)
  printf '%s' "${rows//[[:space:]]/}"
}

page_size() {
  local height
  height=$(terminal_height)
  if (( height >= 48 )); then
    printf '4'
  elif (( height >= 30 )); then
    printf '3'
  elif (( height >= 18 )); then
    printf '2'
  else
    printf '1'
  fi
}

controls_rows() {
  if (( $(terminal_width) >= 90 )); then
    printf '1'
  else
    printf '2'
  fi
}

limited_wrap() {
  local text="$1" max_rows="$2" width index last
  local -a lines=()
  mapfile -t lines < <(printf '%s\n' "$text" | wrap_text)
  (( ${#lines[@]} > 0 )) || return

  last=${#lines[@]}
  (( last > max_rows )) && last=$max_rows
  for (( index = 0; index < last; index++ )); do
    if (( index == max_rows - 1 && ${#lines[@]} > max_rows )); then
      width=$(terminal_width)
      (( width > 4 )) && width=$((width - 4))
      printf '%s…\n' "${lines[$index]:0:$width}"
    else
      printf '%s\n' "${lines[$index]}"
    fi
  done
}

image_height_for_card() {
  local card="$1" budget="$2" max_text_rows text_rows reference_rows image_count available
  max_text_rows=3
  (( budget < 10 )) && max_text_rows=2
  text_rows=$(wrapped_rows "$(jq -r '.text' <<< "$card")")
  (( text_rows > max_text_rows )) && text_rows=$max_text_rows
  reference_rows=$(jq 'if (.referenced | length) > 0 then 1 else 0 end' <<< "$card")
  image_count=$(jq '.images | length' <<< "$card")
  (( image_count > 0 )) || {
    printf '0'
    return
  }

  # Separator, author and metrics use three rows per compact card.
  available=$((budget - 3 - text_rows - reference_rows))
  (( available < 2 )) && available=0
  printf '%s' "$available"
}

show_welcome() {
  printf '\033[2J\033[H\033[?25l'
  printf '%s%sXFeed%s\n\n' "$bold" "$cyan" "$reset"
  printf 'A small unofficial X feed using your browser session.\n\n'
  printf '%sNo local X session is configured.%s\n\n' "$bold" "$reset"
  printf 'Run this command in another terminal:\n\n'
  printf '  %sxfeed-configure%s\n\n' "$cyan" "$reset"
  printf 'The cookies stay under ~/.local/share/xfeed with mode 600.\n'
  printf 'They are not part of the dotfiles repository or the Nix store.\n\n'
  printf '%sPress q to close, or r after configuring.%s\n' "$muted" "$reset"
}

normalise_response() {
  jq -c '
    def clean: gsub("[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]"; "");
    {
      id: .id,
      name: (.author.name // "Unknown"),
      username: (.author.username // "unknown"),
      created_at: (.created_at // ""),
      text: ((.text // "") | clean),
      metrics: {
        like_count: (.metrics.likes // 0),
        retweet_count: (.metrics.retweets // 0),
        reply_count: (.metrics.replies // 0),
        quote_count: (.metrics.quotes // 0)
      },
      images: [.media[]? | (.url // .preview_image // empty)],
      referenced: (
        [.quoted? | select(. != null) | {type: "quoted", text: ((.text // "") | clean)}]
        + [.retweeted? | select(. != null) | {type: "retweeted", text: ((.text // "") | clean)}]
      )
    }
  ' "$response_file" > "$cards_file"
}

fetch_timeline() {
  if [[ ! -s "$session_file" ]]; then
    return 2
  fi

  local tmp error_file error
  tmp=$(mktemp "$cache_dir/.timeline.XXXXXX")
  error_file=$(mktemp "$cache_dir/.timeline-error.XXXXXX")

  if ! X_DATA_DIR="$x_data_dir" x \
      --tier session --rate 2s --quiet --color=never \
      home -n 25 -o jsonl > "$tmp" 2> "$error_file"; then
    error=$(<"$error_file")
    rm -f "$tmp" "$error_file"
    printf '%s\n' "${error:-X session request failed. The cookies may have expired.}" >&2
    return 1
  fi

  rm -f "$error_file"
  if ! jq -e -s 'length > 0 and all(.[]; type == "object" and (.id | type == "string"))' \
      "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    printf 'x-cli returned an invalid or empty timeline.\n' >&2
    return 1
  fi

  mv "$tmp" "$response_file"
  normalise_response
}

next_cards() {
  local limit="$1" card id count=0
  local -a batch_items=()
  [[ -s "$cards_file" ]] || return 1
  while IFS= read -r card; do
    id=$(jq -r '.id' <<< "$card")
    if ! grep -Fqx "$id" "$seen_file" 2>/dev/null; then
      batch_items+=("$card")
      count=$((count + 1))
      (( count >= limit )) && break
    fi
  done < "$cards_file"
  (( count > 0 )) || return 1
  printf '%s\n' "${batch_items[@]}" | jq -s -c '.'
}

remember_seen() {
  local id="$1" tmp
  printf '%s\n' "$id" >> "$seen_file"
  if (( $(wc -l < "$seen_file") > 1000 )); then
    tmp=$(mktemp "$state_dir/.seen.XXXXXX")
    tail -n 800 "$seen_file" > "$tmp"
    mv "$tmp" "$seen_file"
  fi
}

render_image() {
  local url="$1" height="$2" width hash image_file tmp
  width=$(terminal_width)
  (( width > 2 )) && width=$((width - 2))
  hash=$(printf '%s' "$url" | sha256sum | cut -d' ' -f1)
  image_file="$cache_dir/media-$hash"

  if [[ ! -s "$image_file" ]]; then
    tmp=$(mktemp "$cache_dir/.media.XXXXXX")
    if ! curl --fail --silent --show-error --location --max-time 20 \
      --output "$tmp" "$url" 2>/dev/null; then
      rm -f "$tmp"
      return 0
    fi
    mv "$tmp" "$image_file"
  fi

  chafa --format=kitty --animate=off --align=top,left --size="${width}x${height}" "$image_file" 2>/dev/null \
    || chafa --format=symbols --animate=off --align=top,left --size="${width}x${height}" "$image_file" 2>/dev/null \
    || true
}

render_compact_card() {
  local card="$1" index="$2" budget="$3"
  local id name username created text likes reposts replies quotes image_count image_url image_height
  local reference marker max_text_rows
  id=$(jq -r '.id' <<< "$card")
  name=$(jq -r '.name' <<< "$card")
  username=$(jq -r '.username' <<< "$card")
  created=$(jq -r '.created_at | if length >= 16 then .[0:16] | gsub("T"; " ") else . end' <<< "$card")
  text=$(jq -r '.text' <<< "$card")
  likes=$(jq -r '.metrics.like_count // 0' <<< "$card")
  reposts=$(jq -r '.metrics.retweet_count // 0' <<< "$card")
  replies=$(jq -r '.metrics.reply_count // 0' <<< "$card")
  quotes=$(jq -r '.metrics.quote_count // 0' <<< "$card")
  image_count=$(jq '.images | length' <<< "$card")
  image_url=$(jq -r '.images[0] // empty' <<< "$card")
  reference=$(jq -r '.referenced[0].text // empty' <<< "$card")
  image_height=$(image_height_for_card "$card" "$budget")
  max_text_rows=3
  (( budget < 10 )) && max_text_rows=2

  if (( index == selected_index )); then
    marker="${cyan}▸${reset}"
  else
    marker=" "
  fi

  rule
  printf '%s %s%s%s %s@%s%s %s· %s%s\n' \
    "$marker" "$bold" "$name" "$reset" "$blue" "$username" "$reset" "$muted" "$created" "$reset"
  printf '%s' "$bold"
  limited_wrap "$text" "$max_text_rows"
  printf '%s' "$reset"

  if [[ -n "$reference" ]]; then
    printf '%s↳ %s%s' "$muted" "$reset" "$muted"
    limited_wrap "$reference" 1
    printf '%s' "$reset"
  fi

  if (( image_height > 0 )) && [[ -n "$image_url" ]]; then
    render_image "$image_url" "$image_height"
  fi

  printf '%s♥ %s  ↻ %s  💬 %s  ❝ %s' "$muted" "$likes" "$reposts" "$replies" "$quotes"
  if (( image_count > 0 )); then
    printf '  ▧ %s' "$image_count"
  fi
  printf '%s\n' "$reset"
}

render_controls() {
  if (( $(controls_rows) == 1 )); then
    printf '%sj/k select · o open · n next · Space pause · +/- speed · r refresh · q quit%s\n' "$dim" "$reset"
  else
    printf '%sj/k select · o open · n next · Space pause%s\n' "$dim" "$reset"
    printf '%s+/- speed · r refresh · q quit%s\n' "$dim" "$reset"
  fi
}

render_screen() {
  local page="$1" count height available budget index card id
  current_cards="$page"
  needs_redraw=0
  count=$(jq 'length' <<< "$page")
  (( selected_index < count )) || selected_index=0
  id=$(jq -r ".[${selected_index}].id" <<< "$page")
  current_url="https://x.com/i/web/status/$id"
  height=$(terminal_height)
  available=$((height - $(controls_rows)))
  budget=$((available / count))
  (( budget < 5 )) && budget=5

  # The whole viewport is one dashboard page; resize redraws every visible card.
  printf '\033[2J\033[H\033[?25l'
  for (( index = 0; index < count; index++ )); do
    card=$(jq -c ".[${index}]" <<< "$page")
    render_compact_card "$card" "$index" "$budget"
  done
  render_controls
}

redraw_if_needed() {
  if (( needs_redraw )) && [[ "$current_cards" != "[]" ]]; then
    render_screen "$current_cards"
  fi
}

open_current() {
  if [[ -n "$current_url" ]]; then
    xdg-open "$current_url" >/dev/null 2>&1 &
    disown
  fi
}

handle_key() {
  local key="$1" count
  case "$key" in
    q|Q) exit 0 ;;
    ' ')
      if (( paused )); then paused=0; else paused=1; fi
      ;;
    j|J)
      count=$(jq 'length' <<< "$current_cards")
      if (( count > 0 )); then
        selected_index=$(((selected_index + 1) % count))
        needs_redraw=1
      fi
      ;;
    k|K)
      count=$(jq 'length' <<< "$current_cards")
      if (( count > 0 )); then
        selected_index=$(((selected_index - 1 + count) % count))
        needs_redraw=1
      fi
      ;;
    n|N) return 10 ;;
    o|O|'') open_current ;;
    r|R) force_refresh=1; return 10 ;;
    +) speed_offset=$((speed_offset - 2)) ;;
    -) speed_offset=$((speed_offset + 2)) ;;
  esac
  return 0
}

wait_interactive() {
  local key read_rc remaining="$1"
  while (( remaining > 0 )); do
    redraw_if_needed
    if IFS= read -r -s -n 1 -t 1 key; then
      if ! handle_key "$key"; then
        return 0
      fi
    else
      read_rc=$?
      # A terminal timeout already waited one second; EOF returns immediately.
      (( read_rc == 1 )) && sleep 1
      if (( ! paused )); then
        remaining=$((remaining - 1))
      fi
    fi
  done
}

printf '\033[2J\033[H\033[?25l'

streak=0
pause_after=$((8 + RANDOM % 5))

while true; do
  if [[ ! -s "$session_file" ]]; then
    show_welcome
    while [[ ! -s "$session_file" ]]; do
      if IFS= read -r -s -n 1 -t 1 key; then
        case "$key" in
          q|Q) exit 0 ;;
          r|R) break ;;
        esac
      fi
    done
  fi

  if (( force_refresh )) || [[ ! -s "$cards_file" ]]; then
    force_refresh=0
    if ! error=$(fetch_timeline 2>&1); then
      if [[ ! -s "$cards_file" ]]; then
        printf '\n%s%s%s\n' "$red" "$error" "$reset"
        printf '%sPress r to retry or q to close.%s\n' "$muted" "$reset"
        wait_interactive 60
        continue
      fi
    fi
  fi

  if visible_page=$(next_cards "$(page_size)"); then
    selected_index=0
    render_screen "$visible_page"
    while IFS= read -r id; do
      remember_seen "$id"
    done < <(jq -r '.[].id' <<< "$visible_page")
    streak=$((streak + $(jq 'length' <<< "$visible_page")))

    delay=$((8 + RANDOM % 13 + speed_offset))
    (( delay < 2 )) && delay=2
    wait_interactive "$delay"

    if (( streak >= pause_after )); then
      rest=$((30 + RANDOM % 61 + speed_offset))
      (( rest < 5 )) && rest=5
      wait_interactive "$rest"
      streak=0
      pause_after=$((8 + RANDOM % 5))
    fi
  else
    # Keep the last dashboard visible while waiting for new timeline entries.
    force_refresh=1
    wait_interactive 60
  fi
done
