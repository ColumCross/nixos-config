{ pkgs, darkWallpaper, lightWallpaper }:
let
  set-theme = pkgs.writeShellApplication {
    name = "set-theme";
    runtimeInputs = with pkgs; [
      coreutils
      dconf
      gnugrep
      gnused
      hyprland
      kitty
      libnotify
      procps
    ];
    text = ''
      new="$1"
      state_file="$HOME/.cache/current-theme"

      case "$new" in
        dark)
          kitty_theme="$HOME/.config/kitty/theme-dark.conf"
          btop_theme=Default
          kde_color_scheme=BreezeDark
          gtk_theme=Adwaita-dark
          wallpaper=${darkWallpaper}
          ;;
        light)
          kitty_theme="$HOME/.config/kitty/theme-light.conf"
          btop_theme=whiteout
          kde_color_scheme=BreezeLight
          gtk_theme=Adwaita
          wallpaper=${lightWallpaper}
          ;;
        *) exit 2 ;;
      esac

      attempt=0
      until hyprctl hyprpaper wallpaper ",$wallpaper,cover"; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 20 ]; then
          notify-send "Theme" "Could not switch the wallpaper"
          exit 1
        fi
        sleep 0.25
      done

      mkdir -p "$(dirname "$state_file")"
      printf '%s\n' "$new" > "$state_file"

      btop_config="$HOME/.config/btop/btop.conf"
      mkdir -p "$(dirname "$btop_config")"
      if [ -f "$btop_config" ] && grep -q '^color_theme[[:space:]]*=' "$btop_config"; then
        sed -i -E "s/^color_theme[[:space:]]*=.*/color_theme = \"$btop_theme\"/" "$btop_config"
      else
        printf '\ncolor_theme = "%s"\n' "$btop_theme" >> "$btop_config"
      fi
      pkill -SIGUSR2 -x btop || true

      ln -sfnT "$kitty_theme" "$HOME/.config/kitty/current-theme.conf"
      for socket in /tmp/kittyrcontrol-*; do
        [ -S "$socket" ] || continue
        kitten @ --to "unix:$socket" set-colors --all --configured "$kitty_theme" 2>/dev/null || true
      done

      hyprctl keyword general:col.active_border "rgba(11d424ff) rgba(0e8a1aff) 45deg"
      hyprctl keyword general:col.inactive_border "rgba(00ffffff) rgba(0055ffff) 45deg"
      dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'"
      dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$new'"
      ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-colorscheme "$kde_color_scheme" >/dev/null 2>&1 || true

      ln -sfnT "$HOME/.config/waybar/styles/$new.css" "$HOME/.config/waybar/styles/current.css"
      pkill -SIGUSR2 waybar || true
      ln -sfnT "$HOME/.config/dunst/dunstrc.d/$new.conf" "$HOME/.config/dunst/dunstrc.d/current-theme.conf"
      dunstctl reload || true
      ln -sfnT "$HOME/.config/rofi/themes/$new.rasi" "$HOME/.config/rofi/themes/current.rasi"
      ln -sfnT "$HOME/.config/wlogout/styles/$new.css" "$HOME/.config/wlogout/style.css"
    '';
  };
in {
  inherit set-theme;
  toggle-theme = pkgs.writeShellApplication {
    name = "toggle-theme";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      state_file="$HOME/.cache/current-theme"
      if [ -f "$state_file" ] && [ "$(cat "$state_file")" = dark ]; then
        exec ${set-theme}/bin/set-theme light
      fi
      exec ${set-theme}/bin/set-theme dark
    '';
  };
}
