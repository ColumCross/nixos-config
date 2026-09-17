set -eu

[ "$#" -ge 1 ] || { printf '%s\n' 'usage: mail-send <account> [sendmail arguments...]' >&2; exit 2; }
account="$1"
shift
if ! awk -F '\t' -v account="$account" '$1 == account { found = 1 } END { exit !found }' "$HOME/.config/mail/accounts.tsv"; then
  printf 'Unknown mail account: %s\n' "$account" >&2
  exit 2
fi
export NOTMUCH_CONFIG="$HOME/.config/notmuch/$account.conf"
exec gmi send -t -C "$HOME/Mail/$account/gmail" "$@"
