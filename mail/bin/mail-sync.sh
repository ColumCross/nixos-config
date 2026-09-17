set -eu
umask 077

accounts_file="$HOME/.config/mail/accounts.tsv"
state_root="$HOME/.local/state/mail"

usage() {
  printf '%s\n' 'usage: mail-sync <account>' >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
account="$1"
if [ "$account" = all ]; then
  result=0
  while IFS="$(printf '\t')" read -r configured_account _; do
    [ -n "$configured_account" ] || continue
    "$0" "$configured_account" || result=1
  done <"$accounts_file"
  exit "$result"
fi
if ! awk -F '\t' -v account="$account" '$1 == account { found = 1 } END { exit !found }' "$accounts_file"; then
  printf 'Unknown mail account: %s\n' "$account" >&2
  exit 2
fi

initialized="$state_root/initialized/$account"
[ -e "$initialized" ] || {
  printf 'Account %s has not completed mail-setup.\n' "$account" >&2
  exit 1
}

repo="$HOME/Mail/$account/gmail"
config="$HOME/.config/notmuch/$account.conf"
status="$state_root/status/$account"
lock="$state_root/locks/$account.lock"
mkdir -p "$state_root/status" "$state_root/locks"
chmod 700 "$state_root" "$state_root/status" "$state_root/locks"

exec 9>"$lock"
flock -n 9 || {
  printf 'A synchronization is already running for %s.\n' "$account" >&2
  exit 1
}

tmp="$(mktemp "$state_root/status/.${account}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
if NOTMUCH_CONFIG="$config" gmi sync -C "$repo" >"$tmp" 2>&1; then
  mail-refresh-folders "$account"
  {
    printf 'last_success=%s\n' "$(date --iso-8601=seconds)"
    printf 'last_error=\n'
  } >"$status"
  cat "$tmp"
else
  error="$(tr '\n' ' ' <"$tmp" | cut -c1-2000)"
  last_success="$(grep '^last_success=' "$status" 2>/dev/null || true)"
  {
    printf '%s\n' "$last_success"
    printf 'last_error=%s\n' "$error"
  } >"$status"
  cat "$tmp" >&2
  exit 1
fi
