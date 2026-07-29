{ config, lib, pkgs, ... }:

let
  themeDir = "${config.xdg.configHome}/theme-switcher/themes";
  darkDir = "${themeDir}/dark";
  lightDir = "${themeDir}/light";

  toggleTheme = pkgs.writeShellApplication {
    name = "toggle-theme";
    runtimeInputs = with pkgs; [ coreutils procps libnotify dconf hyprland kitty ];
    text = builtins.readFile ./toggle-theme.sh;
  };

  sessionStart = pkgs.writeShellApplication {
    name = "theme-switcher-session";
    runtimeInputs = with pkgs; [ coreutils hypridle hyprpaper waybar dunst dbus toggleTheme ];
    text = ''
      toggle-theme --reset-dark
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      waybar &
      hyprpaper &
      hypridle &
      dunst &
    '';
  };
in
{
  home.packages = [ toggleTheme sessionStart ];

  home.activation.themeSwitcherDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.xdg.configHome}/theme-switcher/themes" "$HOME/.cache"
    mkdir -p "$HOME/.config/dunst/dunstrc.d" "$HOME/.config/gtk-4.0" "$HOME/.config/waybar" "$HOME/.config/rofi" "$HOME/.config/wlogout" "$HOME/.config/kitty"
    ln -sfn "${darkDir}/kitty.conf" "$HOME/.config/kitty/theme-dark.conf"
    ln -sfn "${lightDir}/kitty.conf" "$HOME/.config/kitty/theme-light.conf"
    ln -sfn "${darkDir}/waybar.css" "$HOME/.config/waybar/theme-dark.css"
    ln -sfn "${lightDir}/waybar.css" "$HOME/.config/waybar/theme-light.css"
    ln -sfn "${darkDir}/rofi-config.rasi" "$HOME/.config/rofi/config-dark.rasi"
    ln -sfn "${lightDir}/rofi-config.rasi" "$HOME/.config/rofi/config-light.rasi"
    ln -sfn "${darkDir}/gtk.css" "$HOME/.config/gtk-4.0/theme-dark.css"
    ln -sfn "${lightDir}/gtk.css" "$HOME/.config/gtk-4.0/theme-light.css"
    ln -sfn "${darkDir}/wlogout.css" "$HOME/.config/wlogout/theme-dark.css"
    ln -sfn "${lightDir}/wlogout.css" "$HOME/.config/wlogout/theme-light.css"
  '';

  xdg.configFile."theme-switcher/themes/dark/kitty.conf".source = ./themes/dark/kitty.conf;
  xdg.configFile."theme-switcher/themes/dark/active-border".source = ./themes/dark/active-border;
  xdg.configFile."theme-switcher/themes/dark/inactive-border".source = ./themes/dark/inactive-border;
  xdg.configFile."theme-switcher/themes/dark/waybar.css".source = ./themes/dark/waybar.css;
  xdg.configFile."theme-switcher/themes/dark/wallpaper.jpg".source = ../wallpapers/dark_wallpaper.jpg;
  xdg.configFile."theme-switcher/themes/dark/rofi-config.rasi".source = ./themes/dark/rofi-config.rasi;
  xdg.configFile."theme-switcher/themes/dark/gtk.css".source = ./themes/dark/gtk.css;
  xdg.configFile."theme-switcher/themes/dark/wlogout.css".source = ./themes/dark/wlogout.css;
  xdg.configFile."theme-switcher/themes/light/kitty.conf".source = ./themes/light/kitty.conf;
  xdg.configFile."theme-switcher/themes/light/active-border".source = ./themes/light/active-border;
  xdg.configFile."theme-switcher/themes/light/inactive-border".source = ./themes/light/inactive-border;
  xdg.configFile."theme-switcher/themes/light/waybar.css".source = ./themes/light/waybar.css;
  xdg.configFile."theme-switcher/themes/light/wallpaper.jpg".source = ../wallpapers/light_wallpaper.jpg;
  xdg.configFile."theme-switcher/themes/light/rofi-config.rasi".source = ./themes/light/rofi-config.rasi;
  xdg.configFile."theme-switcher/themes/light/gtk.css".source = ./themes/light/gtk.css;
  xdg.configFile."theme-switcher/themes/light/wlogout.css".source = ./themes/light/wlogout.css;
  xdg.configFile."theme-switcher/themes/light/dunst.conf".source = ./themes/light/dunst.conf;
  xdg.configFile."theme-switcher/themes/dark/rofi-theme.rasi".source = ./themes/dark/rofi-theme.rasi;
  xdg.configFile."theme-switcher/themes/light/rofi-theme.rasi".source = ./themes/light/rofi-theme.rasi;
  xdg.configFile."theme-switcher/nvim/theme-watcher.lua".source = ./nvim/theme-watcher.lua;

  programs.kitty.settings = {
    allow_remote_control = "yes";
    listen_on = "unix:/tmp/kittyrcontrol";
    "include" = "~/.config/kitty/current-theme.conf";
  };

  wayland.windowManager.hyprland.settings.bind = lib.mkAfter [ "$mainMod ALT, L, exec, toggle-theme" ];

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${../wallpapers/dark_wallpaper.jpg}
    preload = ${../wallpapers/light_wallpaper.jpg}
    wallpaper = , ${../wallpapers/dark_wallpaper.jpg}
    ipc = on
  '';
}
