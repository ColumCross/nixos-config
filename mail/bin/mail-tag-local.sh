set -eu

usage() {
  printf '%s\n' 'usage: mail-tag-local <account> <message-id> <Marked for Deletion>' >&2
  exit 2
}

[ "$#" -eq 3 ] || usage
account="$1"
message_id="$2"
case "$3" in
  "Marked for Deletion"|marked-for-deletion) tag=marked-for-deletion ;;
  *) usage ;;
esac
if ! awk -F '\t' -v account="$account" '$1 == account { found = 1 } END { exit !found }' "$HOME/.config/mail/accounts.tsv"; then
  printf 'Unknown mail account: %s\n' "$account" >&2
  exit 2
fi
case "$message_id" in *[!A-Za-z0-9.@_+%=-]*|'') printf '%s\n' 'Invalid message ID.' >&2; exit 2 ;; esac
notmuch --config="$HOME/.config/notmuch/$account.conf" tag "+$tag" "id:$message_id"
