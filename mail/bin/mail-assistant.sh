set -eu
umask 077

home="$HOME"
mail="$home/Mail"
config="$home/.config"
mkdir -p "$mail/notes" "$home/.local/share/opencode"
chmod 700 "$mail/notes" "$home/.local/share/opencode"

# The mail archive is read-only; only notes and OpenCode's application state are writable.
# Lieer credentials live outside the sandbox under ~/.local/state/mail/credentials
# and are not mounted.
exec bwrap \
  --die-with-parent \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --dir "$home" \
  --ro-bind /nix/store /nix/store \
  --ro-bind /run/current-system/sw /run/current-system/sw \
  --ro-bind "$mail" "$mail" \
  --bind "$mail/notes" "$mail/notes" \
  --ro-bind "$config/opencode" "$config/opencode" \
  --ro-bind "$config/mail" "$config/mail" \
  --bind "$home/.local/share/opencode" "$home/.local/share/opencode" \
  --setenv HOME "$home" \
  --setenv XDG_CONFIG_HOME "$config" \
  --setenv XDG_DATA_HOME "$home/.local/share" \
  --chdir "$mail" \
  opencode "$@"
