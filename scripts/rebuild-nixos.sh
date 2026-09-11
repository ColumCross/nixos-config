log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT

set +e
systemd-inhibit --what=sleep:shutdown --why="NixOS rebuild in progress" --mode=block sudo nixos-rebuild switch --flake "@flakeReference@" 2>&1 | tee "$log_file"
rebuild_status=${PIPESTATUS[0]}
set -e

printf '\n'
if [ "$rebuild_status" -ne 0 ]; then
  wl-copy < "$log_file"
  printf '\033[1;31mThe build FAILED\033[0m\n'
elif grep -Eqi '(^|[[:space:]])error:' "$log_file"; then
  wl-copy < "$log_file"
  printf '\033[1;33mThe build passed with errors\033[0m\n'
else
  printf '\033[1;32mThe build succeeded\033[0m\n'
fi

printf 'Press any key to close...'
read -r -n 1 || true
