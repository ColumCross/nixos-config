set -eu
umask 077

accounts_file="$HOME/.config/mail/accounts.tsv"
state_root="$HOME/.local/state/mail"

usage() {
  printf '%s\n' 'usage: mail-setup <account>' >&2
  exit 2
}

[ "$#" -eq 1 ] || usage
account="$1"
if ! awk -F '\t' -v account="$account" '$1 == account { found = 1 } END { exit !found }' "$accounts_file"; then
  printf 'Unknown mail account: %s\n' "$account" >&2
  exit 2
fi

root="$HOME/Mail/$account"
repo="$root/gmail"
config="$HOME/.config/notmuch/$account.conf"
credentials="$state_root/credentials/$account.json"
initialized="$state_root/initialized/$account"
credential_link="$repo/.credentials.gmailieer.json"
lock="$state_root/locks/$account.lock"

if [ -e "$initialized" ]; then
  printf 'Refreshing existing setup for %s.\n' "$account"
fi

mkdir -p "$root/local-drafts" "$repo" "$state_root/credentials" "$state_root/initialized" "$state_root/locks"
chmod 700 "$HOME/Mail" "$root" "$root/local-drafts" "$repo" "$state_root" "$state_root/credentials" "$state_root/initialized" "$state_root/locks"

exec 9>"$lock"
flock -n 9 || {
  printf 'Setup or synchronization is already running for %s.\n' "$account" >&2
  exit 1
}

if [ -L "$credential_link" ]; then
  [ "$(readlink "$credential_link")" = "$credentials" ] || {
    printf 'Credential link for %s points to an unexpected path.\n' "$account" >&2
    exit 1
  }
elif [ -e "$credential_link" ]; then
  [ ! -e "$credentials" ] || {
    printf 'Both repository and private-state credentials exist for %s; refusing to overwrite either.\n' "$account" >&2
    exit 1
  }
  mv "$credential_link" "$credentials"
  ln -s "$credentials" "$credential_link"
else
  ln -s "$credentials" "$credential_link"
fi

export NOTMUCH_CONFIG="$config"
notmuch --config="$config" new

if [ -e "$repo/.gmailieer.json" ]; then
  python3 - "$repo/.gmailieer.json" "$account" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    configured = json.load(handle).get("account")
if configured != sys.argv[2]:
    raise SystemExit(
        f"Lieer repository belongs to {configured!r}, not {sys.argv[2]!r}; refusing to continue."
    )
PY
else
  gmi init --no-auth -C "$repo" "$account"
fi

gmi set -C "$repo" --ignore-tags-local "" --translation-list-overlay "Marked for Deletion,marked-for-deletion"
gmi auth -C "$repo"
gmi sync -C "$repo"
mail-refresh-folders "$account"
notmuch --config="$config" count '*'
touch "$initialized"
printf 'Initial synchronization completed for %s.\n' "$account"
