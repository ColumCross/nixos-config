#!/bin/sh
set -eu

state_file="$HOME/.cache/current-theme"
theme_root="${XDG_CONFIG_HOME:-$HOME/.config}/theme-switcher/themes"
mkdir -p "$(dirname "$state_file")"

apply_theme() {
  theme="$1"
  theme_dir="$theme_root/$theme"
  [ -d "$theme_dir" ] || exit 1

  printf '%s\n' "$theme" > "$state_file"

  if command -v kitten >/dev/null 2>&1; then
    ln -sfn "$theme_dir/kitty.conf" "$HOME/.config/kitty/current-theme.conf"
    for pid in $(pgrep -x kitty 2>/dev/null || true); do
      kitten @ --to "unix:/tmp/kittyrcontrol-$pid" set-colors --all --configured "$theme_dir/kitty.conf" 2>/dev/null || true
    done
  fi

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl keyword general:col.active_border "$(cat "$theme_dir/active-border")" 2>/dev/null || true
    hyprctl keyword general:col.inactive_border "$(cat "$theme_dir/inactive-border")" 2>/dev/null || true
    if command -v hyprpaper >/dev/null 2>&1; then
      hyprctl hyprpaper wallpaper ", $theme_dir/wallpaper.jpg" 2>/dev/null || true
    fi
  fi

  if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$theme'" 2>/dev/null || true
  fi

  if [ -e "$HOME/.config/waybar/theme-$theme.css" ]; then
    ln -sfn "$HOME/.config/waybar/theme-$theme.css" "$HOME/.config/waybar/style.css"
    if command -v pkill >/dev/null 2>&1; then
      pkill -SIGUSR2 waybar 2>/dev/null || true
    fi
  fi

  if [ "$theme" = light ] && [ -f "$theme_dir/dunst.conf" ]; then
    mkdir -p "$HOME/.config/dunst/dunstrc.d"
    ln -sfn "$theme_dir/dunst.conf" "$HOME/.config/dunst/dunstrc.d/10-theme.conf"
  else
    rm -f "$HOME/.config/dunst/dunstrc.d/10-theme.conf"
  fi
  if command -v dunstctl >/dev/null 2>&1; then
    dunstctl reload 2>/dev/null || true
  fi

  ln -sfn "$HOME/.config/rofi/config-$theme.rasi" "$HOME/.config/rofi/config.rasi"
  ln -sfn "$theme_dir/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
  ln -sfn "$theme_dir/wlogout.css" "$HOME/.config/wlogout/style.css"
}

if [ "${1:-}" = --reset-dark ]; then
  apply_theme dark
  exit 0
fi

current=dark
if [ -f "$state_file" ]; then
  current=$(tr -d '[:space:]' < "$state_file")
fi

if [ "$current" = dark ]; then
  apply_theme light
else
  apply_theme dark
fi

if command -v notify-send >/dev/null 2>&1; then
  notify-send Theme "Switched to $(tr -d '[:space:]' < "$state_file") mode"
fi
