# NixOS Configuration

This repository contains my complete NixOS system configuration.

## Features

- NixOS Stable (25.05)
- Flakes
- Home Manager
- Git
- Neovim
- Kitty
- Google Chrome
- Hyprland
- greetd login manager

---

## Customization

Fork this repository, then edit the `profile` attribute set near the top of
`flake.nix` before installing:

```nix
profile = rec {
  username = "your-username";
  homeDirectory = "/home/${username}";
  hostName = "your-hostname";
  flakeName = "laptop";
  configDirectory = "/etc/nixos";
};
```

These values configure the NixOS account, Home Manager account, hostname,
flake target, and wrapper-script paths. `configDirectory` must be the path to
the writable configuration checkout on the installed system. The commands
below use `laptop`; if `flakeName` is changed, set `FLAKE_NAME` to the same
value.

The default system architecture is `x86_64-linux`, configured by `system` in
`flake.nix`. Other architectures must change that value and use a matching
generated hardware configuration.

Each computer must use the `hardware-configuration.nix` generated for that
computer. Do not reuse the included disk UUIDs on another machine.

This configuration does not publish a login password. Set the new user's
password locally during installation or from a root console with
`passwd your-username`.

The NordVPN module currently imported from
`/etc/nixos-modules/nix_modules/nordvpn-module.nix` is external to this
repository. That module must exist at the same path, or the import and related
NordVPN options must be removed before evaluating the configuration. Because
of this external import, installation and rebuild commands must use
`--impure`.

The Home Manager Git configuration uses `credential.helper = "store"`, which
saves credentials unencrypted. Remove that setting or select a secure
credential helper before authenticating to a Git host.

---

## Installation

Partition and mount the disks as normal.

Set the URL of your fork and the `flakeName` selected in `flake.nix`:

```bash
REPOSITORY_URL="https://github.com/YOUR-ACCOUNT/YOUR-FORK.git"
FLAKE_NAME="laptop"
```

Clone your fork:

```bash
git clone "$REPOSITORY_URL" nixos-config
```

Change into the repository:

```bash
cd nixos-config
```

Replace the included hardware configuration with the one generated for the
target computer:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix .
```

Install:

```bash
sudo nixos-install --flake ".#$FLAKE_NAME" --impure
```

Reboot.

---

## Updating

Pull the latest configuration:

```bash
git pull
```

Set `FLAKE_NAME` to the value configured in `flake.nix`:

```bash
FLAKE_NAME="laptop"
```

Apply it:

```bash
sudo nixos-rebuild switch --flake ".#$FLAKE_NAME" --impure
```

---

## Updating package versions

```bash
nix flake update
```

Commit the updated flake.lock file.

Rebuild:

```bash
FLAKE_NAME="laptop"
sudo nixos-rebuild switch --flake ".#$FLAKE_NAME" --impure
```



# NixOS Dynamic Theme Switcher

This NixOS and Home Manager configuration provides coordinated dark and light
themes for the Hyprland desktop. A single command updates the terminal,
compositor, wallpaper, desktop color preference, status bar, notifications,
launcher, GTK4 applications, logout menu, and Neovim without restarting the
Hyprland session.

Use either:

```text
SUPER+ALT+L
```

or:

```sh
toggle-theme
```

The implementation is integrated into the existing NixOS configuration rather
than packaged as a separate application. Most theme definitions are
declarative and live in `/etc/nixos`; Kitty palettes remain user-owned so they
can be edited without rebuilding the system.

## Managed Components

| Component | Behavior when the theme changes |
|---|---|
| Kitty | Selects the persistent palette and updates all running Kitty instances through Unix sockets |
| Terminal applications | Inherit Kitty's ANSI palette and redraw with the new colors |
| Hyprland | Updates active and inactive window-border colors at runtime |
| Hyprpaper | Switches to the preloaded dark or light wallpaper |
| GTK and libadwaita | Publishes `prefer-dark` or `prefer-light` through dconf |
| Electron applications | Uses the desktop preference where the application supports it |
| Waybar | Replaces its active CSS and reloads the running bar |
| Dunst | Adds or removes the light-theme override and reloads the daemon |
| Rofi | Selects the matching Rasi theme for the next launch |
| GTK4 and hyprKCS | Replaces the active GTK4 stylesheet |
| wlogout | Replaces the stylesheet used on its next launch |
| Neovim/NvChad | Reads the shared state and switches Base46 themes |

## Configuration Layout

The main files are:

```text
/etc/nixos/
|-- configuration.nix
|-- flake.nix
|-- home.nix
|-- wallpapers/
|   |-- dark_wallpaper.jpg
|   `-- light_wallpaper.jpg
`-- nvim/lua/
    |-- chadrc.lua
    `-- autocmds.lua
```

### `home.nix`

`/etc/nixos/home.nix` contains most of the implementation:

- Dark and light wallpaper paths
- Dark and light Waybar CSS
- Light-mode Dunst overrides
- Dark and light Rofi configurations and themes
- Dark and light GTK4 CSS
- Dark and light wlogout CSS
- Hyprland border colors
- Hyprpaper preload and IPC settings
- Kitty remote-control settings
- The `SUPER+ALT+L` Hyprland binding
- The `toggle-theme` command generated with `pkgs.writeShellScriptBin`

The generated command is included in `home.packages`, which makes
`toggle-theme` available on the user's `PATH`.

The Hyprland binding is:

```nix
"$mainMod ALT, L, exec, toggle-theme"
```

### `configuration.nix`

`/etc/nixos/configuration.nix` supplies the desktop packages, services, icons,
and portals used by the switcher. Important dependencies include Hyprland,
hyprpaper, Kitty, Rofi, Dunst, `libnotify`, wlogout,
`xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, and the Adwaita icon
theme.

The GTK portal is enabled alongside the Hyprland portal:

```nix
xdg.portal.extraPortals = [
  pkgs.xdg-desktop-portal-hyprland
  pkgs.xdg-desktop-portal-gtk
];
```

Hyprland also imports `WAYLAND_DISPLAY` and `XDG_CURRENT_DESKTOP` into the
systemd user and D-Bus activation environments when the session starts.

### `flake.nix`

Home Manager is configured to preserve runtime-generated files that conflict
with managed paths:

```nix
home-manager.backupFileExtension = "backup";
```

This setting is required because the switcher replaces some Home
Manager-created symlinks with regular files at runtime. During a later rebuild,
Home Manager moves conflicting files to the `.backup` suffix before recreating
its managed links.

### Neovim files

`/etc/nixos/nvim/lua/chadrc.lua` reads the shared theme state when Neovim
starts. `/etc/nixos/nvim/lua/autocmds.lua` checks that state every two seconds
and reloads NvChad Base46 highlights when it changes.

| Desktop theme | NvChad theme |
|---|---|
| Dark | `onedark` |
| Light | `github_light` |

Dark mode also applies the configured black backgrounds to `Normal`,
`NormalNC`, and `NormalFloat`. The state watcher is preferred over sending
keystrokes into Kitty windows because it works independently of terminal
matching and does not interfere with active Neovim input.

## Shared Theme State

The current mode is stored in:

```text
~/.cache/current-theme
```

The file contains either `dark` or `light`. It is the runtime source of truth
shared by the toggle command and Neovim.

If the file is absent, `toggle-theme` treats the current mode as dark, so the
first toggle selects light mode.

Inspect it with:

```sh
cat ~/.cache/current-theme
```

## Toggle Sequence

When `toggle-theme` runs, it:

1. Reads the current state and selects the opposite mode.
2. Writes the new mode to `~/.cache/current-theme`.
3. Updates Kitty's persistent palette link and all running Kitty instances.
4. Updates Hyprland's active and inactive border colors.
5. Switches the Hyprpaper wallpaper.
6. Publishes the GTK and Electron desktop color preference through dconf.
7. Writes the selected Waybar CSS and reloads Waybar.
8. Adds or removes the Dunst light-theme override and reloads Dunst.
9. Writes the selected Rofi configuration.
10. Writes the selected GTK4 and wlogout stylesheets.
11. Sends a desktop notification confirming the selected mode.

Neovim observes the state-file change separately and updates within two
seconds.

## Kitty Integration

Kitty palettes are deliberately not managed by Nix or Home Manager:

```text
~/.config/kitty/theme-dark.conf
~/.config/kitty/theme-light.conf
~/.config/kitty/current-theme.conf
```

`current-theme.conf` is a symbolic link to the selected palette. The main Kitty
configuration includes it:

```nix
"include" = "~/.config/kitty/current-theme.conf";
```

This link ensures that new windows and tabs use the current palette. Running
instances are updated through Kitty remote control, which requires both:

```nix
allow_remote_control = "yes";
listen_on = "unix:/tmp/kittyrcontrol";
```

Kitty creates sockets named like `/tmp/kittyrcontrol-<pid>`. The switcher should
enumerate these sockets and connect explicitly:

```sh
for socket in /tmp/kittyrcontrol-*; do
  [ -S "$socket" ] || continue
  kitten @ --to "unix:$socket" set-colors --all --configured \
    "$THEME_FILE" 2>/dev/null || true
done
```

Socket enumeration is more reliable than matching a process named `kitty`
because NixOS may expose the process as `.kitty-wrapped`. Explicit `--to`
targeting also prevents the approximately five-second timeout that occurs when
`kitten @` is launched by a Hyprland binding without a terminal context.

Kitty theme files use standard Kitty color syntax:

```text
foreground #282a36
background #ffffff
cursor #6272a4
color0 #21222c
color1 #ff5555
```

Edit either palette directly without rebuilding NixOS:

```sh
nvim ~/.config/kitty/theme-light.conf
nvim ~/.config/kitty/theme-dark.conf
```

Select the edited mode with `toggle-theme` to apply it to running windows.
Terminal programs that use ANSI colors, including terminal user interfaces,
will inherit the updated Kitty palette.

## Hyprland and Wallpapers

Runtime border changes must use Hyprland's complete colon-separated option
names and one call per option:

```sh
hyprctl keyword general:col.active_border "rgba(...)"
hyprctl keyword general:col.inactive_border "rgba(...)"
```

Do not use `hyprctl keyword general "col.active_border = ..."`; Hyprland treats
`general` as the option name and returns `config option <general> does not
exist`.

The wallpapers are Nix-managed assets:

```text
/etc/nixos/wallpapers/dark_wallpaper.jpg
/etc/nixos/wallpapers/light_wallpaper.jpg
```

Hyprpaper preloads both images and enables IPC. The switcher can therefore
change the active wallpaper immediately with:

```sh
hyprctl hyprpaper wallpaper , <wallpaper-path>
```

Replacing either wallpaper requires adding the changed asset to the flake's
Git source and rebuilding.

## GTK and Desktop Applications

The switcher writes one of the following values to the desktop color-scheme
preference:

```sh
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/color-scheme "'prefer-light'"
```

GTK, libadwaita, and supported Electron applications can observe this setting.
`NIXOS_OZONE_WL=1` provides native Wayland support for Electron applications,
but individual applications may vary in whether they react immediately.

The switcher also writes custom GTK4 CSS to:

```text
~/.config/gtk-4.0/gtk.css
```

Applications such as hyprKCS read this stylesheet when launched. There is no
standalone `/etc/nixos/gtk-4.0/gtk.css`; both variants are Nix strings in
`home.nix`.

## Waybar, Dunst, Rofi, and wlogout

### Waybar

The selected stylesheet is written to:

```text
~/.config/waybar/style.css
```

The running bar reloads after receiving:

```sh
pkill -SIGUSR2 waybar
```

### Dunst

Dark mode uses the base Home Manager Dunst configuration. Light mode writes an
override to:

```text
~/.config/dunst/dunstrc.d/10-theme.conf
```

The override is removed when returning to dark mode. `dunstctl reload` applies
the result without restarting the session.

### Rofi

Home Manager provides both themes:

```text
~/.config/rofi/themes/black-neon.rasi
~/.config/rofi/themes/light-neon.rasi
```

The switcher writes `~/.config/rofi/config.rasi` with an `@theme` reference to
the selected file. Rofi applies it the next time it opens.

### wlogout

The selected stylesheet is written to:

```text
~/.config/wlogout/style.css
```

wlogout reads the file the next time it opens. Its CSS references icons from
the Nix-provided wlogout package.

## Runtime Files and Home Manager

The switcher creates or replaces these files while the session is running:

```text
~/.config/waybar/style.css
~/.config/rofi/config.rasi
~/.config/gtk-4.0/gtk.css
~/.config/wlogout/style.css
~/.config/dunst/dunstrc.d/10-theme.conf
```

Waybar, Rofi, and GTK4 paths may initially be Home Manager symlinks. The toggle
script replaces them with regular files containing the active theme. On the
next rebuild, `home-manager.backupFileExtension = "backup"` allows activation
to preserve those files and recreate its symlinks instead of failing.

The toggle script can remove stale, relevant `.backup` files before replacing
runtime configuration. It must not depend on Home Manager silently overwriting
regular files, because Home Manager refuses to do so without the backup
setting.

## Customization

### No rebuild required

These user-owned files can be changed directly:

```text
~/.config/kitty/theme-dark.conf
~/.config/kitty/theme-light.conf
```

Run `toggle-theme` until the edited mode is selected.

### Rebuild required

The following are declarative and should be changed in `/etc/nixos`:

- Waybar dark and light CSS
- Dunst light overrides
- Rofi configuration and theme files
- GTK4 dark and light CSS
- wlogout dark and light CSS
- Hyprland border colors
- Wallpaper files and paths
- Kitty remote-control settings
- Hyprland keybinding
- Neovim theme integration

The main theme values are near the beginning of `home.nix`, including
`dark-wallpaper`, `light-wallpaper`, `waybar-dark-css`, `waybar-light-css`,
`dunst-light-overrides`, `rofi-dark-config`, `rofi-light-config`,
`gtk4-dark-css`, `gtk4-light-css`, `wlogout-dark-css`, and
`wlogout-light-css`.

The NixOS configuration is a Git-backed flake. Add and commit changed or new
files so the flake source includes them, then rebuild:

```sh
cd /etc/nixos
git add <changed-files>
git commit -m "describe the theme change"
sudo nixos-rebuild switch --flake /etc/nixos#laptop --impure
```

The repository also provides the `rebuild-nixos` wrapper and `rebuild` shell
alias.

## Verification

After rebuilding, test both directions of the switch:

1. Press `SUPER+ALT+L` and confirm the state changes.
2. Confirm existing and new Kitty windows use the selected palette.
3. Confirm terminal applications redraw with the new colors.
4. Confirm Hyprland borders and the wallpaper change immediately.
5. Confirm Waybar reloads and Dunst notifications use the selected colors.
6. Open Rofi, hyprKCS, and wlogout and inspect their themes.
7. Start Neovim and confirm its theme matches the current state.
8. Leave Neovim running, toggle again, and confirm it updates within two seconds.

Useful inspection commands are:

```sh
cat ~/.cache/current-theme
dconf read /org/gnome/desktop/interface/color-scheme
hyprctl hyprpaper listactive
ls -l ~/.config/kitty/current-theme.conf
ls -l /tmp/kittyrcontrol-*
```

## Troubleshooting

### Only the wallpaper changes, or the switch pauses for five seconds

Check that Kitty has both `allow_remote_control` and `listen_on` configured,
then restart Kitty so it creates `/tmp/kittyrcontrol-<pid>`. Ensure the script
uses `kitten @ --to "unix:$socket"` for each actual socket. A bare `kitten @`
from a Hyprland keybinding has no Kitty terminal context and waits for a timeout.

### Hyprland borders do not change

Run the border command manually. It should return `ok`:

```sh
hyprctl keyword general:col.active_border "rgba(33ccffee) rgba(00ff99ee) 45deg"
```

If Hyprland reports `config option <general> does not exist`, replace the old
`hyprctl keyword general ...` syntax with the full
`general:col.active_border` and `general:col.inactive_border` option names.

### Home Manager activation fails with "Existing file ... is in the way"

Confirm this is present in the Home Manager module configuration:

```nix
home-manager.backupFileExtension = "backup";
```

Existing runtime files at the reported managed paths may need to be moved once
to unblock the first rebuild. Do not delete unrelated files. After the backup
setting is active, Home Manager handles future conflicts by preserving them as
`.backup` files.

### New Kitty windows use the wrong theme

Inspect `~/.config/kitty/current-theme.conf` and confirm it points to the
palette matching `~/.cache/current-theme`. Also verify that Kitty's main
configuration includes that symlink.

### Neovim does not update

Confirm the state file changes and that `autocmds.lua` is loaded. Current
Neovim integration watches `~/.cache/current-theme`; it does not rely on the
older Kitty `send-text` workaround. A newly started Neovim should select the
matching theme through `chadrc.lua`, while an existing instance should update
within two seconds.

### GTK or Electron applications do not update immediately

Check the dconf value and verify that both GTK and Hyprland portals are active.
Some applications only read the desktop preference or GTK CSS at startup, so
relaunching the affected application may be necessary.

## Expected Result

`SUPER+ALT+L` provides one coordinated, immediate desktop theme change. The
shared state remains simple and inspectable, most styles stay declarative in
the NixOS configuration, and Kitty palettes can be tuned independently without
a rebuild.
