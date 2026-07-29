# Theme Switcher

This is a system-specific Home Manager feature for the laptop configuration.
It is intentionally tracked as a top-level feature instead of being a separate
flake or a generic public module.

## Behavior

- A new Hyprland session always starts in dark mode.
- `SUPER+ALT+L` toggles between dark and light mode.
- The current session state is stored in `~/.cache/current-theme`.
- Kitty, Hyprland, hyprpaper, Waybar, Dunst, Rofi, GTK4, wlogout, dconf, and
  Neovim are updated when available.
- Neovim watches the shared state file every two seconds.

The startup reset is deliberately separate from the toggle operation. A
rebuild during an active session does not reset the selected theme; a new
Hyprland session does.

## Runtime ownership

Theme source files are installed by Home Manager below
`~/.config/theme-switcher/themes`. The switcher owns only the selected-theme
links and `~/.cache/current-theme`. The runtime script must not overwrite the
source files in the theme directory.

The Kitty socket configuration is required for live palette changes. The
explicit `--to unix:/tmp/kittyrcontrol-$pid` form avoids the timeout documented
in `~/Documents/Configuration_Documentation/theme-switcher-fix.md`.
