{
  bind = [
    "$mainMod, T, exec, $terminal"
    "$mainMod, SPACE, exec, $menu"
    "$mainMod, D, exec, discord"
    "$mainMod, Q, killactive,"
    "$mainMod SHIFT, Q, exit,"
    "$mainMod, V, togglefloating,"
    "$mainMod, F, fullscreen"
    "$mainMod, P, pseudo,"
    "$mainMod, N, layoutmsg, togglesplit"
    "$mainMod SHIFT, L, exec, hyprlock"
    "$mainMod, slash, exec, hyprkcs"
    "$mainMod, O, exec, $terminal opencode"

    # Rebuild NixOS
    "$mainMod CTRL SHIFT, R, exec, kitty --class nixos-rebuild -e rebuild-nixos"

    # OpenCode in the configured NixOS directory
    "$mainMod CTRL, C, exec, kitty --class opencode -e opencode-nixos"

    # Neovim in the configured NixOS directory
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

    # Workspaces 1-10 follow the current visible numbering
    "$mainMod, 1, exec, workspace-control focus 1"
    "$mainMod, 2, exec, workspace-control focus 2"
    "$mainMod, 3, exec, workspace-control focus 3"
    "$mainMod, 4, exec, workspace-control focus 4"
    "$mainMod, 5, exec, workspace-control focus 5"
    "$mainMod, 6, exec, workspace-control focus 6"
    "$mainMod, 7, exec, workspace-control focus 7"
    "$mainMod, 8, exec, workspace-control focus 8"
    "$mainMod, 9, exec, workspace-control focus 9"
    "$mainMod, 0, exec, workspace-control focus 10"

    # Move window to workspace
    "$mainMod SHIFT, 1, exec, workspace-control move 1"
    "$mainMod SHIFT, 2, exec, workspace-control move 2"
    "$mainMod SHIFT, 3, exec, workspace-control move 3"
    "$mainMod SHIFT, 4, exec, workspace-control move 4"
    "$mainMod SHIFT, 5, exec, workspace-control move 5"
    "$mainMod SHIFT, 6, exec, workspace-control move 6"
    "$mainMod SHIFT, 7, exec, workspace-control move 7"
    "$mainMod SHIFT, 8, exec, workspace-control move 8"
    "$mainMod SHIFT, 9, exec, workspace-control move 9"
    "$mainMod SHIFT, 0, exec, workspace-control move 10"

    # Navigate workspaces by their current visible order
    "$mainMod, left, exec, workspace-control cycle previous"
    "$mainMod, right, exec, workspace-control cycle next"
    "$mainMod SHIFT, left, exec, workspace-control move-relative previous"
    "$mainMod SHIFT, right, exec, workspace-control move-relative next"
    "$mainMod SHIFT ALT, left, exec, workspace-control shift previous"
    "$mainMod SHIFT ALT, right, exec, workspace-control shift next"
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
}
