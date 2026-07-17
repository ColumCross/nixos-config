# =========================
# home.nix
# =========================
{ config, pkgs, ... }:

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
    (pkgs.writeShellScriptBin "rebuild-nixos" ''
      sudo nixos-rebuild switch --flake /etc/nixos#laptop
      echo ""
      echo "Press any key to close..."
      read -n 1
    '')
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
  };

  programs.kitty = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#laptop";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#laptop --upgrade";
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
      "$menu" = "wofi --show drun";
      "$fileManager" = "kitty";

      monitor = ",preferred,auto,auto";

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
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
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
        "waybar"
        "hyprpaper"
        "dunst"
      ];

      bind = [
        "$mainMod, Q, exec, $terminal"
        "$mainMod, A, exec, $menu"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, V, togglefloating,"
        "$mainMod, P, pseudo,"
        "$mainMod, J, togglesplit,"

        # Rebuild NixOS
        "$mainMod CTRL SHIFT, R, exec, kitty --class nixos-rebuild -e rebuild-nixos"

        # Screenshots
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "$mainMod, Print, exec, grim - | wl-copy"
        ", SHIFT Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        "$mainMod SHIFT, Print, exec, grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"

        # Focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

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

        # Media keys
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
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
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%A, %B %d, %Y}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = " muted";
          format-icons = {
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };

        network = {
          format-wifi = "{signalStrength}%";
          format-ethernet = "eth";
          format-disconnected = "disconnected";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}%";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-full = "{capacity}% ";
        };

        tray = {
          spacing = 10;
        };
      };
    };
    style = ''
      * {
        font-family: "JetBrains Mono Nerd Font", monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(26, 27, 38, 0.85);
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 5px;
        color: #6c7086;
        background-color: transparent;
        border-radius: 5px;
      }

      #workspaces button.active {
        color: #cdd6f4;
        background-color: #45475a;
      }

      #clock, #battery, #pulseaudio, #network, #tray {
        padding: 0 10px;
      }

      #battery.warning {
        color: #fab387;
      }

      #battery.critical {
        color: #f38ba8;
      }
    '';
  };

  # ==========================================
  # hyprpaper
  # ==========================================
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${pkgs.hyprland}/share/hypr/wall0.png
    wallpaper = , ${pkgs.hyprland}/share/hypr/wall0.png
    ipc = off
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
        offset = "10x10";
        notification_limit = 5;
        progress_bar = true;
      };

      urgency_low = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        timeout = 5;
      };

      urgency_normal = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        timeout = 10;
      };

      urgency_critical = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        timeout = 0;
      };
    };
  };

  # ==========================================
  # NVChad (Neovim) config files
  # ==========================================
  xdg.configFile = {
    "nvim/init.lua".source = ./nvim/init.lua;
    "nvim/lazy-lock.json".source = ./nvim/lazy-lock.json;
    "nvim/.stylua.toml".source = ./nvim/.stylua.toml;
    "nvim/lua".source = ./nvim/lua;
  };
}
