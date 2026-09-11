  # ==========================================
  # Waybar
  # ==========================================
  { pkgs, ... }:

let
  patched-waybar = pkgs.waybar.overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [ ../../patches/waybar-hyprland-workspace-dnd.patch ];
  });
in
{
  programs.waybar = {
    enable = true;
    package = patched-waybar;

    systemd = {
      enable = true;
      targets = [ "hyprland-session.target" ];
    };

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
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
          "custom/notification-sound"
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
          on-drop = "workspace-control reorder {source} {target} {placement}";
          sort-by = "number";
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
          on-click = "launch-pavucontrol";
        };

        "custom/notification-sound" = {
          exec = "notification-sound-control status";
          return-type = "json";
          interval = "once";
          exec-on-event = true;
          on-click = "notification-sound-control toggle";
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
          show-passive-items = true;
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
}
