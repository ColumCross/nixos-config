# =========================
# home.nix
# =========================
{ config, lib, pkgs, profile, ... }:

let
  flakeReference = "${profile.configDirectory}#${profile.flakeName}";

  workspace-control = pkgs.writeShellApplication {
    name = "workspace-control";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.libnotify
      pkgs.python3
    ];
    text = ''
      exec python3 ${./scripts/workspace-control.py} "$@"
    '';
  };

  notification-sound-control = pkgs.writeShellApplication {
    name = "notification-sound-control";
    runtimeInputs = [ pkgs.coreutils pkgs.pipewire ];
    text = ''
      STATE_FILE="$XDG_RUNTIME_DIR/notification-sound-muted"

      case "''${1:-status}" in
        play)
          [ -f "$STATE_FILE" ] && exit 0
          pw-play --volume 0.5 ${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/message-new-instant.oga >/dev/null 2>&1 &
          ;;
        toggle)
          if [ -f "$STATE_FILE" ]; then
            rm -f "$STATE_FILE"
          else
            touch "$STATE_FILE"
          fi
          ;;
        status)
          if [ -f "$STATE_FILE" ]; then
            printf '%s\n' '{"text":"󰂛","tooltip":"Notification sounds: muted","class":"muted"}'
          else
            printf '%s\n' '{"text":"󰂚","tooltip":"Notification sounds: enabled","class":"enabled"}'
          fi
          ;;
        *)
          exit 2
          ;;
      esac
    '';
  };

  launch-pavucontrol = pkgs.writeShellApplication {
    name = "launch-pavucontrol";
    runtimeInputs = [ pkgs.pavucontrol pkgs.systemd ];
    text = ''
      exec systemd-run --user --collect --quiet --service-type=exec pavucontrol
    '';
  };

  rebuild-nixos = pkgs.writeShellApplication {
    name = "rebuild-nixos";
    runtimeInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.nixos-rebuild pkgs.sudo pkgs.wl-clipboard ];
    text = builtins.replaceStrings
      [ "@flakeReference@" ]
      [ flakeReference ]
      (builtins.readFile ./scripts/rebuild-nixos.sh);
  };

  active-sleep-inhibit = pkgs.replaceVars ./opencode/plugins/active-sleep-inhibit.js {
    systemdInhibit = "${pkgs.systemd}/bin/systemd-inhibit";
    bash = "${pkgs.bash}/bin/bash";
    sleep = "${pkgs.coreutils}/bin/sleep";
  };

  rabcor-hb-mid = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/Rabcor/Heavy-Bass-EE/3d5471a728eded83b165905a92cd959415eda1f4/HB-Mid.json";
    hash = "sha256-0eIReSFJKQNWiG/mUmmgC8od9TCWckIrMnH/9Y55cgA=";
  };

  easyeffects-reset = pkgs.writeShellScript "easyeffects-reset" ''
    set -eu

    config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/easyeffects/db"
    config_file="$config_dir/easyeffectsrc"

    ${pkgs.coreutils}/bin/mkdir -p "$config_dir"

    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group Presets --key lastLoadedInputPreset --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group Presets --key lastLoadedOutputPreset --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group Presets --key lastLoadedInputCommunityPackage --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group Presets --key lastLoadedOutputCommunityPackage --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group StreamInputs --key plugins --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group StreamOutputs --key plugins --delete
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file "$config_file" --group EffectsPipelines --key bypass --delete
  '';

  # Brightness adjustment logic
  # Brightness buttons increase or decrease in different increments if above or below a cutoff point
  brightness-adjust = pkgs.writeShellScriptBin "brightness-adjust" ''
    CURRENT=$(${pkgs.brightnessctl}/bin/brightnessctl -m info \
      | ${pkgs.coreutils}/bin/cut -d, -f4 \
      | ${pkgs.coreutils}/bin/tr -d '%')

    BRIGHTNESS_CUTOFF=10

    case "$1" in
      up)
        if [ "$CURRENT" -lt $BRIGHTNESS_CUTOFF ]; then
          STEP=1
        else
          STEP=5
        fi
        ${pkgs.brightnessctl}/bin/brightnessctl set "$STEP%+"
        ;;
      down)
        if [ "$CURRENT" -le $BRIGHTNESS_CUTOFF ]; then
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

  # Keybindings
  hyprlandKeybindings = import ./hyprland/keybindings.nix;

in
{
  imports = [ 
    ./home/theming
    ./home/waybar
  ];


  home.username = profile.username;
  home.homeDirectory = profile.homeDirectory;

  home.stateVersion = "25.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    NIXOS_OZONE_WL = "1";
  };

  home.packages = [
    pkgs.networkmanager_dmenu
    pkgs.sound-theme-freedesktop
    launch-pavucontrol
    brightness-adjust
    workspace-control
    notification-sound-control
    rebuild-nixos
    (pkgs.writeShellScriptBin "opencode-nixos" ''
      cd "${profile.configDirectory}"
      exec opencode
    '')
    (pkgs.writeShellScriptBin "nvim-nixos" ''
      cd "${profile.configDirectory}"
      exec nvim .
    '')
  ];

  programs.home-manager.enable = true;

  services.easyeffects = {
    enable = true;
    preset = "";
  };

  systemd.user.services.easyeffects.Service.ExecStartPre = easyeffects-reset;

  home.activation.easyeffectsHBMidMigration = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    remove_if_managed_hb_mid() {
      if [ -e "$1" ] && ${pkgs.coreutils}/bin/cmp -s "$1" ${rabcor-hb-mid}; then
        ${pkgs.coreutils}/bin/rm -f "$1"
      fi
    }

    remove_if_managed_hb_mid "$HOME/.config/easyeffects/output/HB-Mid.json"
    remove_if_managed_hb_mid "$HOME/.local/share/easyeffects/output/HB-Mid.json"
    remove_if_managed_hb_mid "$HOME/.local/share/easyeffects/output/HB-Mid.json.backup"
  '';

  programs.git = {
    enable = true;
    settings.credential.helper = "store";
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "Inconsolata Nerd Font Mono";
      size = 12;
    };
    settings = {
      window_padding_width = 4;
      background_opacity = "1.0";
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake '${flakeReference}'";
      update = "nix flake update --flake '${profile.configDirectory}' && sudo nixos-rebuild switch --flake '${flakeReference}'";
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
    configType = "hyprlang";

    settings = {
      "$terminal" = "kitty";
      "$menu" = "rofi -show drun";
      "$fileManager" = "dolphin";

      monitor = ",preferred,auto,1";

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
        preserve_split = true;
        precise_mouse_move = true;
      };

      master = {
        new_status = "master";
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };

      "$mainMod" = "SUPER";

      exec-once = [
        "nm-applet"
        "blueman-applet"
      ];

      inherit (hyprlandKeybindings) bind bindel bindl bindm;

      windowrule = [
        "match:class .*, suppress_event maximize"
        "match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus true"
        "match:class ^(pavucontrol)$, float true"
        "match:class ^(nm-connection-editor)$, float true"
        "match:class ^(blueman-manager)$, float true, center true"
        "match:class ^(hyprkcs)$, float true, center true, size 889 854"
        "match:class ^(kitty)$, rounding 5, suppress_event fullscreen"
      ];
    };
  };

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

      urgency_low.timeout = 3;

      urgency_normal.timeout = 5;

      urgency_critical.timeout = 0;

      notification-sound = {
        script = "${notification-sound-control}/bin/notification-sound-control play";
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
        ignore_systemd_inhibit = false;
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
    "nvim/lazy-lock.json".source = config.lib.file.mkOutOfStoreSymlink "${profile.configDirectory}/nvim/lazy-lock.json";
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
    "nvim/lua".source = ./nvim/lua;

    # OpenCode TUI config
    "opencode/tui.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/tui.json";
      attention = {
        enabled = true;
        notifications = true;
        sound = false;
      };
    };
    "opencode/plugins/active-sleep-inhibit.js".source = active-sleep-inhibit;

    "spotify-player/app.toml".source = ./spotify-player/app.toml;

  };

  xdg.dataFile."easyeffects/output/HB-Mid.json".source = rabcor-hb-mid;
}
