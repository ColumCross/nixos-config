# =========================
# home.nix
# =========================
{ config, pkgs, ... }:
{
  imports = [ ./theme-switcher ];

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
        "theme-switcher-session"
      ];

      bind = [
        "$mainMod, T, exec, $terminal"
        "$mainMod, S, exec, $menu"
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
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        # Media player
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
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
          format-charging = "󰂄 BAT {capacity}%";
          format-plugged = "󰂄 BAT {capacity}%";
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
        frame_color = "#3b4252";
        separator_color = "frame";
        font = "JetBrains Mono 10";
        markup = "full";
        format = "<b>%s</b>\n%b";
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
