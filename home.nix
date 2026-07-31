# =========================
# home.nix
# =========================
{ config, pkgs, ... }:

let
  # ==========================================
  # Theme definitions
  # ==========================================

  dark-wallpaper = ./wallpapers/dark_wallpaper.jpg;
  light-wallpaper = ./wallpapers/light_wallpaper.jpg;

  waybar-dark-css = ''
    @define-color teal #00ffff;
    @define-color teal-dim #00cccc;
    @define-color teal-light #00ffd5;
    @define-color green #00ff9f;
    @define-color pink #ff33cc;
    @define-color red #ff0080;
    @define-color orange #ff4d00;
    @define-color yellow #ffff00;
    @define-color purple #bd00ff;
    @define-color blue #00b8ff;
    @define-color grey #888888;
    @define-color gold #ffcc00;
    @define-color black #000000;
    @define-color black-gradient #0a0a0a;

    * {
      font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Noto Sans Mono', 'Font Awesome 6 Free', 'Font Awesome 6 Brands', monospace;
      font-size: 13px;
      font-weight: 500;
    }

    window#waybar {
      background: linear-gradient(180deg, @black 0%, @black-gradient 100%);
      border-bottom: 2px solid @teal;
      box-shadow: 0 0 20px @teal;
      color: @teal;
      transition-property: background-color, border-color, box-shadow;
      transition-duration: 0.3s;
      border-radius: 0 0;
    }

    window#waybar.hidden { opacity: 0.2; }
    window#waybar.empty { background-color: transparent; }
    window#waybar.solo { background-color: @black; border: 2px solid @teal; }

    button {
      border: none;
      border-radius: 4px;
      background: rgba(0, 255, 255, 0.1);
      color: @teal;
    }
    button:hover {
      background: rgba(0, 255, 255, 0.2);
      box-shadow: 0 0 15px @teal;
    }

    #workspaces button {
      padding: 4px 8px;
      margin: 0 4px;
      background: transparent;
      color: @teal-dim;
      border: none;
    }
    #workspaces button:hover { color: @teal; }
    #workspaces button.focused { color: @teal; font-weight: bold; }
    #workspaces button.urgent { color: @pink; }

    #clock, #battery, #cpu, #memory, #backlight, #disk, #network,
    #bluetooth, #pulseaudio, #wireplumber, #custom-media, #tray,
    #mode, #scratchpad, #power-profiles-daemon, #mpd, #language,
    #keyboard-state, #privacy-item {
      padding: 1px 12px;
      margin: 0;
      background: transparent;
      border: none;
      color: @teal;
    }

    #window, #workspaces { margin: 0 4px; }

    #custom-sep1, #custom-sep2, #custom-sep3, #custom-sep4,
    #custom-sep5, #custom-sep6, #custom-sep7 {
      color: @teal;
      opacity: 0.4;
      padding: 0 4px;
      margin: 0;
    }

    #custom-power {
      color: @red;
      padding: 1px 12px;
      margin: 0;
    }
    #custom-power:hover {
      color: @pink;
      text-shadow: 0 0 10px @pink;
    }

    #cpu { color: @teal; }
    #memory { color: @purple; }
    #disk { color: @orange; }
    #backlight { color: @yellow; }
    #battery { color: @green; }
    #battery.charging, #battery.plugged { color: @green; }
    #battery.critical:not(.charging) { color: @red; }
    #battery.warning:not(.charging) { color: @orange; }
    #network { color: @teal; }
    #network.disconnected { color: @red; }
    #bluetooth { color: @teal; }
    #bluetooth.connected { color: @green; }
    #bluetooth.off, #bluetooth.disabled { color: @red; }
    #pulseaudio { color: @teal-light; }
    #pulseaudio.muted { color: @grey; }
    #wireplumber { color: @pink; }
    #wireplumber.muted { color: @red; }
    #custom-media { color: @green; }
    #mpd { color: @green; }
    #mpd.disconnected { color: @red; }
    #mpd.stopped { color: @grey; }
    #mpd.paused { color: @gold; }
    #clock { font-weight: bold; letter-spacing: 1px; color: @teal-light; }
    #temperature.critical { color: @red; }
    #custom-weather { color: @blue; }
    #tray { color: @teal; }
    #tray > .passive { opacity: 0.5; }
    #tray > .needs-attention { color: @pink; }
    #idle_inhibitor { color: @teal; }
    #idle_inhibitor.activated { color: @green; }
    #language { min-width: 16px; padding: 4px 8px; }
    #keyboard-state { color: @teal-light; padding: 4px 0px; min-width: 16px; }
    #keyboard-state > label.locked { color: @pink; }
    #scratchpad { color: @teal; }
    #scratchpad.empty { color: rgba(0, 255, 255, 0.3); }
    #mode { color: @pink; font-weight: bold; }
    #privacy { padding: 0; }
    #privacy-item.screenshare { color: @orange; }
    #privacy-item.audio-in { color: @green; }
    #privacy-item.audio-out { color: @teal; }
  '';

  waybar-light-css = ''
    @define-color teal #0077aa;
    @define-color teal-dim #006699;
    @define-color teal-light #0088bb;
    @define-color green #00aa55;
    @define-color pink #aa0088;
    @define-color red #cc0044;
    @define-color orange #cc5500;
    @define-color yellow #aa8800;
    @define-color purple #8800aa;
    @define-color blue #0088cc;
    @define-color grey #666666;
    @define-color gold #aa8800;
    @define-color black #ffffff;
    @define-color black-gradient #f5f5f5;

    * {
      font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Noto Sans Mono', 'Font Awesome 6 Free', 'Font Awesome 6 Brands', monospace;
      font-size: 13px;
      font-weight: 500;
    }

    window#waybar {
      background: linear-gradient(180deg, @black 0%, @black-gradient 100%);
      border-bottom: 2px solid @teal;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      color: @teal;
      transition-property: background-color, border-color, box-shadow;
      transition-duration: 0.3s;
      border-radius: 0 0;
    }

    window#waybar.hidden { opacity: 0.2; }
    window#waybar.empty { background-color: transparent; }
    window#waybar.solo { background-color: @black; border: 2px solid @teal; }

    button {
      border: none;
      border-radius: 4px;
      background: rgba(0, 119, 170, 0.1);
      color: @teal;
    }
    button:hover {
      background: rgba(0, 119, 170, 0.2);
      box-shadow: 0 0 8px rgba(0, 119, 170, 0.3);
    }

    #workspaces button {
      padding: 4px 8px;
      margin: 0 4px;
      background: transparent;
      color: @teal-dim;
      border: none;
    }
    #workspaces button:hover { color: @teal; }
    #workspaces button.focused { color: @teal; font-weight: bold; }
    #workspaces button.urgent { color: @pink; }

    #clock, #battery, #cpu, #memory, #backlight, #disk, #network,
    #bluetooth, #pulseaudio, #wireplumber, #custom-media, #tray,
    #mode, #scratchpad, #power-profiles-daemon, #mpd, #language,
    #keyboard-state, #privacy-item {
      padding: 1px 12px;
      margin: 0;
      background: transparent;
      border: none;
      color: @teal;
    }

    #window, #workspaces { margin: 0 4px; }

    #custom-sep1, #custom-sep2, #custom-sep3, #custom-sep4,
    #custom-sep5, #custom-sep6, #custom-sep7 {
      color: @teal;
      opacity: 0.4;
      padding: 0 4px;
      margin: 0;
    }

    #custom-power {
      color: @red;
      padding: 1px 12px;
      margin: 0;
    }
    #custom-power:hover {
      color: @pink;
      text-shadow: 0 0 8px @pink;
    }

    #cpu { color: @teal; }
    #memory { color: @purple; }
    #disk { color: @orange; }
    #backlight { color: @yellow; }
    #battery { color: @green; }
    #battery.charging, #battery.plugged { color: @green; }
    #battery.critical:not(.charging) { color: @red; }
    #battery.warning:not(.charging) { color: @orange; }
    #network { color: @teal; }
    #network.disconnected { color: @red; }
    #bluetooth { color: @teal; }
    #bluetooth.connected { color: @green; }
    #bluetooth.off, #bluetooth.disabled { color: @red; }
    #pulseaudio { color: @teal-light; }
    #pulseaudio.muted { color: @grey; }
    #wireplumber { color: @pink; }
    #wireplumber.muted { color: @red; }
    #custom-media { color: @green; }
    #mpd { color: @green; }
    #mpd.disconnected { color: @red; }
    #mpd.stopped { color: @grey; }
    #mpd.paused { color: @gold; }
    #clock { font-weight: bold; letter-spacing: 1px; color: @teal-light; }
    #temperature.critical { color: @red; }
    #custom-weather { color: @blue; }
    #tray { color: @teal; }
    #tray > .passive { opacity: 0.5; }
    #tray > .needs-attention { color: @pink; }
    #idle_inhibitor { color: @teal; }
    #idle_inhibitor.activated { color: @green; }
    #language { min-width: 16px; padding: 4px 8px; }
    #keyboard-state { color: @teal-light; padding: 4px 0px; min-width: 16px; }
    #keyboard-state > label.locked { color: @pink; }
    #scratchpad { color: @teal; }
    #scratchpad.empty { color: rgba(0, 119, 170, 0.3); }
    #mode { color: @pink; font-weight: bold; }
    #privacy { padding: 0; }
    #privacy-item.screenshare { color: @orange; }
    #privacy-item.audio-in { color: @green; }
    #privacy-item.audio-out { color: @teal; }
  '';

  dunst-light-overrides = ''
    [global]
    frame_color = "#d8dee9"

    [urgency_low]
    background = "#d8dee9"
    foreground = "#2e3440"

    [urgency_normal]
    background = "#e5e9f0"
    foreground = "#2e3440"

    [urgency_critical]
    background = "#bf616a"
    foreground = "#eceff4"
  '';

  rofi-dark-config = ''
    configuration {
      display-drun: "Apps";
      drun-display-format: "{name}";
      font: "JetBrains Mono 12";
    }

    @theme "~/.config/rofi/themes/black-neon.rasi"
  '';

  rofi-light-config = ''
    configuration {
      display-drun: "Apps";
      drun-display-format: "{name}";
      font: "JetBrains Mono 12";
    }

    @theme "~/.config/rofi/themes/light-neon.rasi"
  '';

  gtk4-dark-css = ''
    window {
      background-color: #000000;
      color: #ffffff;
      font-family: 'JetBrainsMono Nerd Font', monospace;
      font-size: 13px;
      border: none;
      border-radius: 0;
    }
    label { color: #ffffff; }
    titlebar, headerbar {
      background-color: #000000;
      color: #ffffff;
      border-bottom: 2px solid #ffffff;
      border-radius: 0;
      box-shadow: none;
    }
    button {
      background-color: transparent;
      color: #ffffff;
      border: 1px solid #ffffff;
      border-radius: 0;
      padding: 4px 12px;
      box-shadow: none;
    }
    button:hover {
      background-color: rgba(255, 255, 255, 0.15);
      box-shadow: 0 0 10px rgba(255, 255, 255, 0.3);
    }
    button:active, button:checked {
      background-color: rgba(255, 255, 255, 0.25);
    }
    box.key {
      background-color: rgba(255, 255, 255, 0.08);
      color: #ffffff;
      border: 1px solid rgba(255, 255, 255, 0.3);
      border-radius: 0;
    }
    box.key:hover {
      background-color: rgba(255, 255, 255, 0.2);
      border-color: #ffffff;
    }
    box.key.active {
      background-color: rgba(255, 255, 255, 0.3);
      border-color: #ffffff;
      color: #ffffff;
    }
    list { background-color: #000000; }
    row {
      background-color: #000000;
      color: #ffffff;
      padding: 4px 8px;
    }
    row:selected { background-color: rgba(255, 255, 255, 0.15); }
    row:hover { background-color: rgba(255, 255, 255, 0.08); }
    separator {
      background-color: rgba(255, 255, 255, 0.2);
      min-height: 1px;
    }
    scrollbar { background-color: transparent; }
    scrollbar slider {
      background-color: rgba(255, 255, 255, 0.3);
      border-radius: 0;
      min-width: 6px;
      min-height: 6px;
    }
    scrollbar slider:hover { background-color: #ffffff; }
    entry {
      background-color: rgba(255, 255, 255, 0.05);
      color: #ffffff;
      border: 1px solid rgba(255, 255, 255, 0.3);
      border-radius: 0;
      caret-color: #ffffff;
    }
    entry:focus { border-color: #ffffff; }
    check, radio {
      background-color: transparent;
      color: #ffffff;
      border: 1px solid #ffffff;
      border-radius: 0;
    }
    check:checked, radio:checked {
      background-color: #ffffff;
      color: #000000;
    }
    tooltip {
      background-color: #000000;
      color: #ffffff;
      border: 1px solid #ffffff;
      border-radius: 0;
    }
    popover, dialog {
      background-color: #000000;
      color: #ffffff;
      border: 1px solid #ffffff;
      border-radius: 0;
    }
    .sidebar {
      background-color: #000000;
      border-right: 1px solid rgba(255, 255, 255, 0.2);
    }
    .dim-label { color: rgba(255, 255, 255, 0.4); }
  '';

  gtk4-light-css = ''
    window {
      background-color: #ffffff;
      color: #282a36;
      font-family: 'JetBrainsMono Nerd Font', monospace;
      font-size: 13px;
      border: none;
      border-radius: 0;
    }
    label { color: #282a36; }
    titlebar, headerbar {
      background-color: #ffffff;
      color: #282a36;
      border-bottom: 2px solid #282a36;
      border-radius: 0;
      box-shadow: none;
    }
    button {
      background-color: transparent;
      color: #282a36;
      border: 1px solid #282a36;
      border-radius: 0;
      padding: 4px 12px;
      box-shadow: none;
    }
    button:hover {
      background-color: rgba(40, 42, 54, 0.1);
      box-shadow: 0 0 8px rgba(40, 42, 54, 0.15);
    }
    button:active, button:checked {
      background-color: rgba(40, 42, 54, 0.2);
    }
    box.key {
      background-color: rgba(40, 42, 54, 0.05);
      color: #282a36;
      border: 1px solid rgba(40, 42, 54, 0.2);
      border-radius: 0;
    }
    box.key:hover {
      background-color: rgba(40, 42, 54, 0.1);
      border-color: #282a36;
    }
    box.key.active {
      background-color: rgba(40, 42, 54, 0.2);
      border-color: #282a36;
      color: #282a36;
    }
    list { background-color: #ffffff; }
    row {
      background-color: #ffffff;
      color: #282a36;
      padding: 4px 8px;
    }
    row:selected { background-color: rgba(40, 42, 54, 0.1); }
    row:hover { background-color: rgba(40, 42, 54, 0.05); }
    separator {
      background-color: rgba(40, 42, 54, 0.15);
      min-height: 1px;
    }
    scrollbar { background-color: transparent; }
    scrollbar slider {
      background-color: rgba(40, 42, 54, 0.2);
      border-radius: 0;
      min-width: 6px;
      min-height: 6px;
    }
    scrollbar slider:hover { background-color: #282a36; }
    entry {
      background-color: rgba(40, 42, 54, 0.05);
      color: #282a36;
      border: 1px solid rgba(40, 42, 54, 0.2);
      border-radius: 0;
      caret-color: #282a36;
    }
    entry:focus { border-color: #282a36; }
    check, radio {
      background-color: transparent;
      color: #282a36;
      border: 1px solid #282a36;
      border-radius: 0;
    }
    check:checked, radio:checked {
      background-color: #282a36;
      color: #ffffff;
    }
    tooltip {
      background-color: #ffffff;
      color: #282a36;
      border: 1px solid #282a36;
      border-radius: 0;
    }
    popover, dialog {
      background-color: #ffffff;
      color: #282a36;
      border: 1px solid #282a36;
      border-radius: 0;
    }
    .sidebar {
      background-color: #ffffff;
      border-right: 1px solid rgba(40, 42, 54, 0.15);
    }
    .dim-label { color: rgba(40, 42, 54, 0.4); }
  '';

  wlogout-icons = "${pkgs.wlogout}/share/wlogout/icons";

  wlogout-dark-css = ''
    * {
      background-image: none;
      box-shadow: none;
    }
    window {
      background-color: rgba(12, 12, 12, 0.9);
      color: #ffffff;
    }
    button {
      background-color: #1E1E1E;
      color: #ffffff;
      border: 1px solid #33ccff;
      border-radius: 0;
      margin: 5px;
      padding: 10px 30px;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 25%;
    }
    button:hover, button:focus {
      background-color: rgba(51, 204, 255, 0.2);
      box-shadow: 0 0 15px rgba(51, 204, 255, 0.3);
      color: #33ccff;
    }
    button:active {
      background-color: rgba(51, 204, 255, 0.35);
      color: #33ccff;
    }
    #lock      { background-image: image(url("${wlogout-icons}/lock.png")); }
    #logout    { background-image: image(url("${wlogout-icons}/logout.png")); }
    #suspend   { background-image: image(url("${wlogout-icons}/suspend.png")); }
    #hibernate { background-image: image(url("${wlogout-icons}/hibernate.png")); }
    #shutdown  { background-image: image(url("${wlogout-icons}/shutdown.png")); }
    #reboot    { background-image: image(url("${wlogout-icons}/reboot.png")); }
  '';

  wlogout-light-css = ''
    * {
      background-image: none;
      box-shadow: none;
    }
    window {
      background-color: rgba(248, 248, 242, 0.95);
      color: #282a36;
    }
    button {
      background-color: #eaecee;
      color: #282a36;
      border: 1px solid #0077aa;
      border-radius: 0;
      margin: 5px;
      padding: 10px 30px;
      background-repeat: no-repeat;
      background-position: center;
      background-size: 25%;
    }
    button:hover, button:focus {
      background-color: rgba(0, 119, 170, 0.15);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
      color: #0077aa;
    }
    button:active {
      background-color: rgba(0, 119, 170, 0.3);
      color: #0077aa;
    }
    #lock      { background-image: image(url("${wlogout-icons}/lock.png")); }
    #logout    { background-image: image(url("${wlogout-icons}/logout.png")); }
    #suspend   { background-image: image(url("${wlogout-icons}/suspend.png")); }
    #hibernate { background-image: image(url("${wlogout-icons}/hibernate.png")); }
    #shutdown  { background-image: image(url("${wlogout-icons}/shutdown.png")); }
    #reboot    { background-image: image(url("${wlogout-icons}/reboot.png")); }
  '';

  # ==========================================
  # Toggle theme script
  # ==========================================
  toggle-theme = pkgs.writeShellScriptBin "toggle-theme" ''
    STATE_FILE="$HOME/.cache/current-theme"

    if [ -f "$STATE_FILE" ]; then
      CURRENT=$(cat "$STATE_FILE")
    else
      CURRENT="dark"
    fi

    if [ "$CURRENT" = "dark" ]; then
      NEW="light"
    else
      NEW="dark"
    fi

    echo "$NEW" > "$STATE_FILE"

    # Kitty terminal colors
    if [ "$NEW" = "dark" ]; then
      THEME_FILE=~/.config/kitty/theme-dark.conf
    else
      THEME_FILE=~/.config/kitty/theme-light.conf
    fi
    ln -sf "$THEME_FILE" ~/.config/kitty/current-theme.conf
    for pid in $(pgrep kitty); do
      kitten @ --to "unix:/tmp/kittyrcontrol-$pid" set-colors --all --configured "$THEME_FILE" 2>/dev/null || true
    done

    # Hyprland border colors
    if [ "$NEW" = "dark" ]; then
      hyprctl keyword general:col.active_border "rgba(33ccffee) rgba(00ff99ee) 45deg"
      hyprctl keyword general:col.inactive_border "rgba(00FFFFEE)"
    else
      hyprctl keyword general:col.active_border "rgba(6272a4ee) rgba(50fa7bee) 45deg"
      hyprctl keyword general:col.inactive_border "rgba(d8dee9EE)"
    fi

    # Wallpaper
    if [ "$NEW" = "dark" ]; then
      hyprctl hyprpaper wallpaper , ${dark-wallpaper}
    else
      hyprctl hyprpaper wallpaper , ${light-wallpaper}
    fi

    # GTK / Electron / Libadwaita color scheme
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$NEW'"

    # Waybar
    rm -f ~/.config/waybar/style.css ~/.config/waybar/style.css.backup
    if [ "$NEW" = "dark" ]; then
      cat > ~/.config/waybar/style.css << 'WAYBAREOF'
    ${waybar-dark-css}
    WAYBAREOF
    else
      cat > ~/.config/waybar/style.css << 'WAYBAREOF'
    ${waybar-light-css}
    WAYBAREOF
    fi
    pkill -SIGUSR2 waybar || true

    # Dunst
    mkdir -p ~/.config/dunst/dunstrc.d
    if [ "$NEW" = "dark" ]; then
      rm -f ~/.config/dunst/dunstrc.d/10-theme.conf
    else
      cat > ~/.config/dunst/dunstrc.d/10-theme.conf << 'DUNSTEOF'
    ${dunst-light-overrides}
    DUNSTEOF
    fi
    dunstctl reload || true

    # Rofi
    rm -f ~/.config/rofi/config.rasi ~/.config/rofi/config.rasi.backup
    if [ "$NEW" = "dark" ]; then
      cat > ~/.config/rofi/config.rasi << 'ROFIEOF'
    ${rofi-dark-config}
    ROFIEOF
    else
      cat > ~/.config/rofi/config.rasi << 'ROFIEOF'
    ${rofi-light-config}
    ROFIEOF
    fi

    # GTK4 CSS for hyprKCS
    mkdir -p ~/.config/gtk-4.0
    rm -f ~/.config/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css.backup
    if [ "$NEW" = "dark" ]; then
      cat > ~/.config/gtk-4.0/gtk.css << 'GTKEOF'
    ${gtk4-dark-css}
    GTKEOF
    else
      cat > ~/.config/gtk-4.0/gtk.css << 'GTKEOF'
    ${gtk4-light-css}
    GTKEOF
    fi

    # wlogout CSS
    mkdir -p ~/.config/wlogout
    if [ "$NEW" = "dark" ]; then
      cat > ~/.config/wlogout/style.css << 'WLOGOUTEOF'
    ${wlogout-dark-css}
    WLOGOUTEOF
    else
      cat > ~/.config/wlogout/style.css << 'WLOGOUTEOF'
    ${wlogout-light-css}
    WLOGOUTEOF
    fi

    notify-send "Theme" "Switched to $NEW mode"
  '';

  brightness-adjust = pkgs.writeShellScriptBin "brightness-adjust" ''
    CURRENT=$(${pkgs.brightnessctl}/bin/brightnessctl -m info \
      | ${pkgs.coreutils}/bin/cut -d, -f4 \
      | ${pkgs.coreutils}/bin/tr -d '%')

    case "$1" in
      up)
        if [ "$CURRENT" -lt 5 ]; then
          STEP=1
        else
          STEP=5
        fi
        ${pkgs.brightnessctl}/bin/brightnessctl set "$STEP%+"
        ;;
      down)
        if [ "$CURRENT" -le 5 ]; then
          STEP=1
        else
          STEP=5
        fi
        ${pkgs.brightnessctl}/bin/brightnessctl set "$STEP%-"
        ;;
      *)
        exit 2
        ;;
    esac
  '';

in
{
  home.username = "colum";
  home.homeDirectory = "/home/colum";

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  home.packages = [
    pkgs.networkmanager_dmenu
    toggle-theme
    brightness-adjust
    (pkgs.writeShellScriptBin "rebuild-nixos" ''
      sudo nixos-rebuild switch --flake /etc/nixos#laptop --impure
      echo ""
      echo "Press any key to close..."
      read -n 1
    '')
    (pkgs.writeShellScriptBin "opencode-nixos" ''
      cd /etc/nixos
      exec opencode
    '')
    (pkgs.writeShellScriptBin "nvim-nixos" ''
      cd /etc/nixos
      exec nvim .
    '')
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    extraConfig.credential.helper = "store";
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "Inconsolata Nerd Font Mono";
      size = 12;
    };
    settings = {
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kittyrcontrol";
      window_padding_width = 4;
      background_opacity = "1.0";
      "include" = "~/.config/kitty/current-theme.conf";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#laptop --impure";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#laptop --impure --upgrade";
      gco = "git checkout";
      gs = "git status";
      gl = "git log --oneline -10";
      gp = "git push";
    };
  };

  # ==========================================
  # Hyprland
  # ==========================================
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    settings = {
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun";
      "$fileManager" = "dolphin";

      monitor = ",preferred,auto,1.2";

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          scroll_factor = 0.5;
        };
      };

      general = {
        gaps_in = 2;
        gaps_out = 5;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(00FFFFEE)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 5;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint,0.23,1,0.32,1"
          "easeInOutCubic,0.65,0.05,0.36,1"
          "linear,0,0,1,1"
          "almostLinear,0.5,0.5,0.75,1.0"
          "quick,0.15,0,0.1,1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 1, 1.94, almostLinear, fade"
          "workspacesIn, 1, 1.21, almostLinear, fade"
          "workspacesOut, 1, 1.94, almostLinear, fade"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      gestures = {
        workspace_swipe = false;
      };

      "$mainMod" = "SUPER";

      exec-once = [
        "nm-applet"
        "blueman-applet"
        "waybar"
        "hyprpaper"
        "hypridle"
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      ];

      bind = [
        "$mainMod, T, exec, $terminal"
        "$mainMod, SPACE, exec, $menu"
        "$mainMod, D, exec, discord"
        "$mainMod, Q, killactive,"
        "$mainMod SHIFT, Q, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, F, fullscreen"
        "$mainMod, P, pseudo,"
        "$mainMod, N, togglesplit,"
        "$mainMod SHIFT, L, exec, hyprlock"
        "$mainMod, slash, exec, hyprkcs"
        "$mainMod, O, exec, $terminal opencode"

        # Toggle theme
        "$mainMod ALT, L, exec, toggle-theme"

        # Rebuild NixOS
        "$mainMod CTRL SHIFT, R, exec, kitty --class nixos-rebuild -e rebuild-nixos"

        # OpenCode on /etc/nixos
        "$mainMod CTRL, C, exec, kitty --class opencode -e opencode-nixos"

        # Neovim on /etc/nixos
        "$mainMod CTRL SHIFT, C, exec, kitty --class neovim-edit -e nvim-nixos"

        # Applications
        "$mainMod, B, exec, blueman-manager"
        "$mainMod, W, exec, google-chrome-stable"

        # Screenshots
        "CTRL SHIFT, 4, exec, grim -g \"$(slurp)\" - | wl-copy && notify-send \"Screenshot copied to clipboard\""
        "CTRL SHIFT, 5, exec, grim - | wl-copy && notify-send \"Full screenshot copied to clipboard\""

        # Vim-style focus
        "$mainMod, H, movefocus, l"
        "$mainMod, J, movefocus, d"
        "$mainMod, K, movefocus, u"
        "$mainMod, L, movefocus, r"

        # Workspaces 1-10
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move window to workspace
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Navigate workspaces with Z/X
        "$mainMod, left, workspace, e-1"
        "$mainMod, right, workspace, e+1"
      ];

      bindel = [
        # Media keys
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
      ];

      bindl = [
        ", switch:on:Lid Switch, exec, ~/.config/hypr/lid_handler.sh close"
        ", switch:off:Lid Switch, exec, ~/.config/hypr/lid_handler.sh open"

        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightness-adjust up"
        ", XF86MonBrightnessDown, exec, brightness-adjust down"

        # Media player
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
        "ALT, mouse:272, movewindow"
        "ALT CTRL, mouse:272, resizewindow"
      ];

      windowrule = [
        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        "float,class:^(pavucontrol)$"
        "float,class:^(nm-connection-editor)$"
        "float,class:^(blueman-manager)$"
        "center,class:^(blueman-manager)$"
        "float,class:^(hyprkcs)$"
        "center,class:^(hyprkcs)$"
        "size 889 854, class:^(hyprkcs)$"
        "rounding 5, class:^(kitty)$"
        "suppressevent fullscreen, class:^(kitty)$"
      ];
    };
  };

  # ==========================================
  # Waybar
  # ==========================================
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
        spacing = 2;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [];
        modules-right = [
          "network"
          "bluetooth"
          "custom/sep1"
          "cpu"
          "custom/sep2"
          "memory"
          "custom/sep3"
          "backlight"
          "custom/sep4"
          "pulseaudio"
          "custom/sep5"
          "battery"
          "custom/sep6"
          "clock"
          "tray"
          "custom/power"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        clock = {
          format = "{:%m/%d %I:%M %p}";
          format-alt = "{:%Y-%m-%d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          interval = 60;
        };

        cpu = {
          format = "CPU {usage:02}% ";
          tooltip = true;
          tooltip-format = "CPU Usage: {usage}%\nCores: {avg_frequency} GHz";
          interval = 2;
        };

        memory = {
          format = "MEM {}% ";
          tooltip = true;
          tooltip-format = "Memory: {used:.1f}GB/{total:.1f}GB\nSwap: {swapUsed:.1f}GB/{swapTotal:.1f}GB";
          interval = 5;
        };

        pulseaudio = {
          format = "󰕾 {volume}%";
          format-muted = "󰝟 muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format = "{icon} {essid}";
          format-ethernet = "{icon} {ipaddr}";
          format-linked = "{icon} {ifname}";
          format-disconnected = "󰤭";
          format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
          tooltip = true;
          tooltip-format = "{ifname} via {gwaddr}";
          tooltip-format-wifi = "{essid} ({signalStrength}%)\nFrequency: {frequency}MHz\nIP: {ipaddr}";
          tooltip-format-ethernet = "{ifname}\nIP: {ipaddr}\nGateway: {gwaddr}";
          tooltip-format-disconnected = "Disconnected";
          on-click = "networkmanager_dmenu";
          interval = 10;
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱 {num_connections}";
          format-disabled = "󰂲";
          tooltip-format = "{controller_alias}\n{device_enumerate}";
          on-click = "blueman-manager";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "BAT {capacity}%";
          format-charging = "BAT {capacity}% 󰂄";
          format-plugged = "BAT {capacity}% 󰂄";
          format-icons = [ "" "" "" "" "" ];
        };

        backlight = {
          format = "󰃠 {percent}%";
          interval = 2;
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };

        "custom/sep1" = { format = "|"; tooltip = false; };
        "custom/sep2" = { format = "|"; tooltip = false; };
        "custom/sep3" = { format = "|"; tooltip = false; };
        "custom/sep4" = { format = "|"; tooltip = false; };
        "custom/sep5" = { format = "|"; tooltip = false; };
        "custom/sep6" = { format = "|"; tooltip = false; };

        "custom/power" = {
          format = "⏻";
          tooltip = false;
          on-click = "wlogout -p layer-shell";
        };
      };
    };
    style = ''
      @define-color teal #00ffff;
      @define-color teal-dim #00cccc;
      @define-color teal-light #00ffd5;
      @define-color green #00ff9f;
      @define-color pink #ff33cc;
      @define-color red #ff0080;
      @define-color orange #ff4d00;
      @define-color yellow #ffff00;
      @define-color purple #bd00ff;
      @define-color blue #00b8ff;
      @define-color grey #888888;
      @define-color gold #ffcc00;
      @define-color black #000000;
      @define-color black-gradient #0a0a0a;

      * {
        font-family: 'JetBrainsMono Nerd Font', 'JetBrains Mono', 'Noto Sans Mono', 'Font Awesome 6 Free', 'Font Awesome 6 Brands', monospace;
        font-size: 13px;
        font-weight: 500;
      }

      window#waybar {
        background: linear-gradient(180deg, @black 0%, @black-gradient 100%);
        border-bottom: 2px solid @teal;
        box-shadow: 0 0 20px @teal;
        color: @teal;
        transition-property: background-color, border-color, box-shadow;
        transition-duration: 0.3s;
        border-radius: 0 0;
      }

      window#waybar.hidden { opacity: 0.2; }
      window#waybar.empty { background-color: transparent; }
      window#waybar.solo { background-color: @black; border: 2px solid @teal; }

      button {
        border: none;
        border-radius: 4px;
        background: rgba(0, 255, 255, 0.1);
        color: @teal;
      }
      button:hover {
        background: rgba(0, 255, 255, 0.2);
        box-shadow: 0 0 15px @teal;
      }

      #workspaces button {
        padding: 4px 8px;
        margin: 0 4px;
        background: transparent;
        color: @teal-dim;
        border: none;
      }
      #workspaces button:hover { color: @teal; }
      #workspaces button.focused { color: @teal; font-weight: bold; }
      #workspaces button.urgent { color: @pink; }

      #clock, #battery, #cpu, #memory, #backlight, #disk, #network,
      #bluetooth, #pulseaudio, #wireplumber, #custom-media, #tray,
      #mode, #scratchpad, #power-profiles-daemon, #mpd, #language,
      #keyboard-state, #privacy-item {
        padding: 1px 12px;
        margin: 0;
        background: transparent;
        border: none;
        color: @teal;
      }

      #window, #workspaces { margin: 0 4px; }

      #custom-sep1, #custom-sep2, #custom-sep3, #custom-sep4,
      #custom-sep5, #custom-sep6, #custom-sep7 {
        color: @teal;
        opacity: 0.4;
        padding: 0 4px;
        margin: 0;
      }

      #custom-power {
        color: @red;
        padding: 1px 12px;
        margin: 0;
      }
      #custom-power:hover {
        color: @pink;
        text-shadow: 0 0 10px @pink;
      }

      #cpu { color: @teal; }
      #memory { color: @purple; }
      #disk { color: @orange; }
      #backlight { color: @yellow; }
      #battery { color: @green; }
      #battery.charging, #battery.plugged { color: @green; }
      #battery.critical:not(.charging) { color: @red; }
      #battery.warning:not(.charging) { color: @orange; }
      #network { color: @teal; }
      #network.disconnected { color: @red; }
      #bluetooth { color: @teal; }
      #bluetooth.connected { color: @green; }
      #bluetooth.off, #bluetooth.disabled { color: @red; }
      #pulseaudio { color: @teal-light; }
      #pulseaudio.muted { color: @grey; }
      #wireplumber { color: @pink; }
      #wireplumber.muted { color: @red; }
      #custom-media { color: @green; }
      #mpd { color: @green; }
      #mpd.disconnected { color: @red; }
      #mpd.stopped { color: @grey; }
      #mpd.paused { color: @gold; }
      #clock { font-weight: bold; letter-spacing: 1px; color: @teal-light; }
      #temperature.critical { color: @red; }
      #custom-weather { color: @blue; }
      #tray { color: @teal; }
      #tray > .passive { opacity: 0.5; }
      #tray > .needs-attention { color: @pink; }
      #idle_inhibitor { color: @teal; }
      #idle_inhibitor.activated { color: @green; }
      #language { min-width: 16px; padding: 4px 8px; }
      #keyboard-state { color: @teal-light; padding: 4px 0px; min-width: 16px; }
      #keyboard-state > label.locked { color: @pink; }
      #scratchpad { color: @teal; }
      #scratchpad.empty { color: rgba(0, 255, 255, 0.3); }
      #mode { color: @pink; font-weight: bold; }
      #privacy { padding: 0; }
      #privacy-item.screenshare { color: @orange; }
      #privacy-item.audio-in { color: @green; }
      #privacy-item.audio-out { color: @teal; }
    '';
  };

  # ==========================================
  # hyprpaper
  # ==========================================
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${dark-wallpaper}
    preload = ${light-wallpaper}
    wallpaper = , ${dark-wallpaper}
    ipc = on
  '';

  # ==========================================
  # Notification daemon (dunst)
  # ==========================================
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        width = 300;
        height = 100;
        origin = "top-right";
        offset = "30x20";
        notification_limit = 5;
        separator_height = 2;
        padding = 8;
        horizontal_padding = 8;
        frame_width = 2;
        frame_color = "#3b4252";
        separator_color = "frame";
        font = "JetBrains Mono 10";
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        ellipsize = "middle";
        ignore_newline = false;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;
        icon_theme = "Adwaita";
        icon_position = "left";
        max_icon_size = 32;
        mouse_left_click = "close_current";
        mouse_middle_click = "do_action";
        mouse_right_click = "close_all";
        sort = true;
        idle_threshold = 120;
        layer = "overlay";
        transparency = 20;
      };

      urgency_low = {
        background = "#3b4252";
        foreground = "#d8dee9";
        timeout = 3;
      };

      urgency_normal = {
        background = "#434c5e";
        foreground = "#eceff4";
        timeout = 5;
      };

      urgency_critical = {
        background = "#bf616a";
        foreground = "#eceff4";
        timeout = 0;
      };
    };
  };

  systemd.user.services.dunst = {
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  # ==========================================
  # hypridle
  # ==========================================
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 150;
          on-timeout = "brightnessctl set 10% -s";
          on-resume = "brightnessctl -r";
        }
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 60;
          on-timeout = "pidof hyprlock && hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  # ==========================================
  # hyprlock
  # ==========================================
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = false;
        immediate_render = true;
        fail_timeout = 2000;
      };

      background = {
        path = "screenshot";
        color = "rgba(25, 20, 20, 1.0)";
        blur_passes = 2;
        blur_size = 7;
        noise = 0.0117;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };

      label = [
        {
          text = "cmd[update:1000] echo \"$(date +\"%H:%M\")\"";
          color = "rgba(0, 0, 0, 1.0)";
          font_size = 120;
          font_family = "JetBrainsMono Nerd Font ExtraBold";
          position = "0, -300";
          halign = "center";
          valign = "top";
          shadow_passes = 1;
          shadow_size = 3;
          shadow_color = "rgba(0, 255, 255, 1.0)";
          shadow_boost = 2.0;
        }
        {
          text = "cmd[update:1000] echo \"$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '--')%\"";
          color = "rgba(200, 200, 200, 1.0)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";
          position = "-30, 30";
          halign = "right";
          valign = "bottom";
        }
      ];

      input-field = {
        size = "250, 60";
        outline_thickness = 2;
        rounding = 0;
        dots_size = 0.2;
        dots_spacing = 0.2;
        dots_center = true;
        outer_color = "rgba(0, 255, 255, 1.0)";
        inner_color = "rgba(0, 0, 0, 0.5)";
        font_color = "rgb(200, 200, 200)";
        fade_on_empty = false;
        placeholder_text = "<i>Password...</i>";
        hide_input = false;
        position = "0, -120";
        halign = "center";
        valign = "center";
      };
    };
  };

  # ==========================================
  # Rofi
  # ==========================================
  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      display-drun: "Apps";
      drun-display-format: "{name}";
      font: "JetBrains Mono 12";
    }

    @theme "~/.config/rofi/themes/black-neon.rasi"
  '';

  xdg.configFile."rofi/themes/black-neon.rasi".text = ''
    * {
        background: #000000;
        foreground: #00ffff;
        selected-background: #00ffff33;
        selected-foreground: #00ffff;
        border-color: #00ffff;

        background-color: transparent;
        text-color: @foreground;

        margin: 0px;
        padding: 0px;
        spacing: 0px;
    }

    window {
        background-color: @background;
        border: 2px;
        border-color: @border-color;
        border-radius: 0px;
        width: 960px;
        height: 540px;
        padding: 10px;
    }

    mainbox {
        children: [inputbar, listview];
        background-color: transparent;
    }

    inputbar {
        children: [prompt, entry];
        background-color: transparent;
        border: 0px 0px 2px 0px;
        border-color: @border-color;
        padding: 10px;
        margin: 0px 0px 10px 0px;
    }

    prompt {
        text-color: @foreground;
        padding: 0px 10px 0px 0px;
    }

    entry {
        placeholder: "Search...";
        placeholder-color: #555555;
        text-color: @foreground;
    }

    listview {
        lines: 10;
        columns: 1;
        scrollbar: false;
    }

    element {
        padding: 8px;
        border-radius: 0px;
    }

    element selected {
        background-color: transparent;
        text-color: @selected-foreground;
        border: 2px;
        border-color: @selected-foreground;
    }

    element-text {
        background-color: transparent;
        text-color: inherit;
        vertical-align: 0.5;
    }

    element-icon {
        size: 24px;
        padding: 0px 10px 0px 0px;
        background-color: transparent;
    }
  '';

  xdg.configFile."rofi/themes/light-neon.rasi".text = ''
    * {
        background: #ffffff;
        foreground: #282a36;
        selected-background: #0077aa33;
        selected-foreground: #0077aa;
        border-color: #0077aa;

        background-color: transparent;
        text-color: @foreground;

        margin: 0px;
        padding: 0px;
        spacing: 0px;
    }

    window {
        background-color: @background;
        border: 2px;
        border-color: @border-color;
        border-radius: 0px;
        width: 960px;
        height: 540px;
        padding: 10px;
    }

    mainbox {
        children: [inputbar, listview];
        background-color: transparent;
    }

    inputbar {
        children: [prompt, entry];
        background-color: transparent;
        border: 0px 0px 2px 0px;
        border-color: @border-color;
        padding: 10px;
        margin: 0px 0px 10px 0px;
    }

    prompt {
        text-color: @foreground;
        padding: 0px 10px 0px 0px;
    }

    entry {
        placeholder: "Search...";
        placeholder-color: #aaaaaa;
        text-color: @foreground;
    }

    listview {
        lines: 10;
        columns: 1;
        scrollbar: false;
    }

    element {
        padding: 8px;
        border-radius: 0px;
    }

    element selected {
        background-color: transparent;
        text-color: @selected-foreground;
        border: 2px;
        border-color: @selected-foreground;
    }

    element-text {
        background-color: transparent;
        text-color: inherit;
        vertical-align: 0.5;
    }

    element-icon {
        size: 24px;
        padding: 0px 10px 0px 0px;
        background-color: transparent;
    }
  '';

  # ==========================================
  # Lid handler
  # ==========================================
  xdg.configFile."hypr/lid_handler.sh" = {
    text = ''
      #!/bin/sh
      case "$1" in
          "close")
              pidof hyprlock || hyprlock
              ;;
          "open")
              hyprctl dispatch dpms on
              ;;
          *)
              echo "Usage: $0 [close|open]"
              exit 1
              ;;
      esac
    '';
    executable = true;
  };

  # ==========================================
  # NVChad (Neovim) config files
  # ==========================================
  xdg.configFile = {
    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/lazy-lock.json".source = ./nvim/lazy-lock.json;
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
    "nvim/lua".source = ./nvim/lua;

    # GTK4 theme for hyprKCS
    "gtk-4.0/gtk.css".text = gtk4-dark-css;

    # OpenCode TUI config
    "opencode/tui.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/tui.json";
      attention = {
        enabled = true;
        notifications = true;
        sound = true;
      };
    };
  };
}
