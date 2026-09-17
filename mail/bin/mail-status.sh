set -eu

accounts_file="$HOME/.config/mail/accounts.tsv"
config_root="$HOME/.config/notmuch"
state_root="$HOME/.local/state/mail"

status_one() {
  account="$1"
  printf '%s\n' "$account"
  if [ -e "$state_root/initialized/$account" ]; then
    printf '  indexed_messages: '
    notmuch --config="$config_root/$account.conf" count '*' 2>/dev/null || printf 'unavailable'
    if [ -f "$state_root/status/$account" ]; then
      awk '{ print "  " $0 }' "$state_root/status/$account"
    else
      printf '%s\n' '  last_success=never'
    fi
  else
    printf '%s\n' '  status=not initialized'
  fi
}

if [ "${1:-all}" = all ]; then
  while IFS="$(printf '\t')" read -r account _; do
    [ -n "$account" ] && status_one "$account"
  done <"$accounts_file"
else
  status_one "$1"
fi
