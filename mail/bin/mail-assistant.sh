set -eu

cd "$HOME/Mail"
exec opencode --agent email "$@"
