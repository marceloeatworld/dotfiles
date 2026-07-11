set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
x_data_dir="$data_home/xfeed/x-cli"

printf '\nXFeed session configuration (unofficial, free, read-only)\n\n'
printf 'WARNING: auth_token is equivalent to a logged-in browser session.\n'
printf 'Never paste it into chat, Git, a command argument, or a screenshot.\n'
printf 'Using it outside the X website can lead to account restriction or suspension.\n\n'
printf 'In Brave while logged into x.com:\n'
printf '  1. Open Developer Tools (F12).\n'
printf '  2. Application -> Storage -> Cookies -> https://x.com.\n'
printf '  3. Copy the values of auth_token and ct0.\n\n'

read -r -s -p 'auth_token cookie: ' auth_token
printf '\n'
read -r -s -p 'ct0 cookie: ' ct0
printf '\n'

if [[ -z "$auth_token" || -z "$ct0" ]]; then
  printf 'Both auth_token and ct0 are required.\n' >&2
  exit 2
fi

mkdir -p "$x_data_dir"
chmod 700 "$x_data_dir"

# x-cli accepts a Cookie header on stdin. The secrets never enter process
# arguments, shell history, this repository, or the Nix store.
printf 'auth_token=%s; ct0=%s\n' "$auth_token" "$ct0" \
  | X_DATA_DIR="$x_data_dir" x auth import

unset auth_token ct0

printf '\nSession saved locally under %s (mode 600).\n' "$x_data_dir"
printf 'Run xfeed-control enable, then press Super+R.\n'
