{ config, lib, pkgs, ... }:
let
  waybar = import ./styles/waybar.nix;
  dunst = import ./styles/dunst.nix;
  rofi = import ./styles/rofi.nix;
  wlogout = import ./styles/wlogout.nix {
    wlogoutIcons = "${pkgs.wlogout}/share/wlogout/icons";
  };
  darkWallpaper = ../../wallpapers/nix-dark.png;
  lightWallpaper = ../../wallpapers/nix-bright.png;
  switcher = import ./switcher.nix { inherit pkgs darkWallpaper lightWallpaper; };
in {
  qt = {
    enable = true;
    platformTheme = {
      name = "kde";
      package = [ pkgs.kdePackages.plasma-integration pkgs.kdePackages.plasma-integration.qt5 ];
    };
    style.name = "breeze";
  };

  home.packages = [ switcher.set-theme switcher.toggle-theme ];

  programs.kitty.settings = {
    allow_remote_control = "yes";
    listen_on = "unix:/tmp/kittyrcontrol";
    "include" = "~/.config/kitty/current-theme.conf";
  };

  wayland.windowManager.hyprland.settings = {
    general = {
      "col.active_border" = "rgba(11d424ff) rgba(0e8a1aff) 45deg";
      "col.inactive_border" = "rgba(00ffffff) rgba(0055ffff) 45deg";
    };
    exec-once = lib.mkAfter [ "set-theme dark" ];
    bind = lib.mkAfter [ "$mainMod ALT, L, exec, toggle-theme" ];
  };

  programs.waybar = {
    settings.mainBar = {
      height = waybar.metrics.height;
      tray.icon-size = waybar.metrics.trayIconSize;
    };
    style = ''@import url("file://${config.xdg.configHome}/waybar/styles/current.css");'';
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true;
      splash = false;
      wallpaper = [{ monitor = ""; path = "${darkWallpaper}"; fit_mode = "cover"; }];
    };
  };

  services.dunst.settings = {
    global.frame_color = "#3b4252";
    urgency_low = { background = "#3b4252"; foreground = "#d8dee9"; };
    urgency_normal = { background = "#434c5e"; foreground = "#eceff4"; };
    urgency_critical = { background = "#bf616a"; foreground = "#eceff4"; };
  };

  xdg.configFile = {
    "waybar/styles/dark.css".text = waybar.dark;
    "waybar/styles/light.css".text = waybar.light;
    "dunst/dunstrc.d/dark.conf".text = dunst.dark;
    "dunst/dunstrc.d/light.conf".text = dunst.light;
    "rofi/config.rasi".text = rofi.config;
    "rofi/themes/dark.rasi".text = rofi.dark;
    "rofi/themes/light.rasi".text = rofi.light;
    "wlogout/styles/dark.css".text = wlogout.dark;
    "wlogout/styles/light.css".text = wlogout.light;
  };

  home.activation.initializeThemeSelectors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.config/waybar/styles" "$HOME/.config/dunst/dunstrc.d" "$HOME/.config/rofi/themes" "$HOME/.config/wlogout"
    $DRY_RUN_CMD rm -f "$HOME/.config/dunst/dunstrc.d/10-theme.conf"
    selector_theme=dark
    if [ -f "$HOME/.cache/current-theme" ] && [ "$(cat "$HOME/.cache/current-theme")" = light ]; then
      selector_theme=light
    fi
    $DRY_RUN_CMD ln -sfnT "$selector_theme.css" "$HOME/.config/waybar/styles/current.css"
    $DRY_RUN_CMD ln -sfnT "$selector_theme.conf" "$HOME/.config/dunst/dunstrc.d/current-theme.conf"
    $DRY_RUN_CMD ln -sfnT "$selector_theme.rasi" "$HOME/.config/rofi/themes/current.rasi"
    $DRY_RUN_CMD ln -sfnT "styles/$selector_theme.css" "$HOME/.config/wlogout/style.css"
  '';
}
