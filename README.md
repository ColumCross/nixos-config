# NixOS Laptop Configuration

Declarative NixOS and Home Manager configuration for the `laptop` flake target.
The system tracks NixOS 26.05 and Home Manager release-26.05 while retaining
`system.stateVersion = "25.05"` and `home.stateVersion = "25.05"` for migration
compatibility.

## System Overview

- User: `colum`
- Host: `nixos`
- Desktop: Hyprland on Wayland
- Login: greetd with text-mode tuigreet
- Audio: PipeWire with ALSA and PulseAudio compatibility
- Shell: Bash managed by Home Manager
- Terminal: Kitty
- Editor: Neovim with NVChad
- Status bar: Waybar
- Notifications: Dunst
- Application launcher: Rofi
- Wallpaper service: Hyprpaper
- Lock and idle handling: Hyprlock and Hypridle
- VPN: NordVPN through the local NordVPN flake input

## Repository Layout

```text
/etc/nixos/
|-- configuration.nix
|-- flake.nix
|-- flake.lock
|-- hardware-configuration.nix
|-- home.nix
|-- AGENTS.md
|-- README.md
|-- nvim/
|   |-- init.lua
|   |-- lazy-lock.json
|   |-- .stylua.toml
|   `-- lua/
`-- wallpapers/
    |-- nix-dark.png
    `-- nix-bright.png
```

`configuration.nix` owns system services, users, packages, fonts, networking,
audio, Bluetooth, greetd, portals, Hyprland enablement, and NordVPN.

`home.nix` owns the user's shell, desktop session, theme switcher, Waybar,
Dunst, Hyprpaper, Hypridle, Hyprlock, Rofi, Kitty, Neovim mappings, and wrapper
scripts.

`hardware-configuration.nix` is generated for this machine and should not be
edited manually.

## Flake Architecture

`flake.nix` centralizes machine-specific values in `profile`:

```nix
profile = {
  username = "colum";
  homeDirectory = "/home/colum";
  hostName = "nixos";
  flakeName = "laptop";
  configDirectory = "/etc/nixos";
};
```

The main inputs are NixOS 26.05, Home Manager release-26.05, the unstable
nixpkgs package set used for selected applications, Claude Desktop, OpenCode,
and the local NordVPN module.

The NordVPN module is a locked local Git flake input:

```nix
nordvpn-module.url = "git+file:///etc/nixos-modules/nix_modules";
```

Because it is a flake input recorded in `flake.lock`, the normal check,
evaluation, build, and rebuild commands are pure and do not require
`--impure`. Changes in the separate NordVPN repository must be committed before
updating this repository's lock file to a new revision.

## Login And Session

greetd runs tuigreet in text mode. The greeter limits its user menu to UID 1000
and starts the Hyprland package's `start-hyprland` command after successful
password authentication.

```text
tuigreet --time --user-menu --user-menu-min-uid 1000 \
  --user-menu-max-uid 1000 --cmd .../bin/start-hyprland
```

This is a single-user password prompt, not autologin. UID 1000 must belong to
the intended desktop user. Changing only `profile.username` does not change the
UID filter, so adapting this configuration for another machine also requires
checking that user's UID or changing the greetd command.

The greeter runs on its own virtual terminal. Root and recovery access remain
available through another TTY.

## Hyprland

The NixOS Hyprland module supplies the compositor and portal packages. The Home
Manager module sets both `package` and `portalPackage` to `null` so it reuses
those system packages instead of installing a second, potentially mismatched
copy.

The Home Manager configuration remains in Hyprland's native configuration
format through:

```nix
configType = "hyprlang";
```

The desktop starts Waybar, NetworkManager and Bluetooth applets, Hypridle, and
the dark theme. The default Hyprland logo and splash rendering are disabled.

Notable shortcuts:

| Shortcut | Action |
|---|---|
| `SUPER+T` | Open Kitty |
| `SUPER+SPACE` | Open Rofi |
| `SUPER+W` | Open Chrome |
| `SUPER+B` | Open Bluetooth manager |
| `SUPER+SHIFT+L` | Lock the session |
| `SUPER+ALT+L` | Toggle dark/light theme |
| `SUPER+CTRL+SHIFT+R` | Open the rebuild wrapper |
| `SUPER+CTRL+C` | Open OpenCode in `/etc/nixos` |
| `SUPER+CTRL+SHIFT+C` | Open Neovim in `/etc/nixos` |
| `CTRL+SHIFT+4` | Copy a selected-area screenshot |
| `CTRL+SHIFT+5` | Copy a full-screen screenshot |

The rebuild shortcut intentionally invokes the `rebuild-nixos` wrapper. This
keeps the flake reference out of the Hyprland bind value, where `#` would be
interpreted as the start of a comment.

## Theme Switcher

The desktop has explicit target and toggle commands:

```sh
set-theme dark
set-theme light
toggle-theme
```

Hyprland runs `set-theme dark` at session startup. `toggle-theme` reads
`~/.cache/current-theme` and selects the opposite target.

Each theme application updates:

- The active Hyprpaper wallpaper
- The shared theme state file
- Kitty's selected palette and running Kitty windows
- Hyprland border colors
- The GNOME desktop color preference used by GTK and Electron applications
- Waybar styling
- Dunst styling
- Rofi styling
- GTK4 styling used by hyprKCS
- Wlogout styling

The wallpapers are Nix-managed assets:

```text
/etc/nixos/wallpapers/nix-dark.png
/etc/nixos/wallpapers/nix-bright.png
```

Hyprpaper starts with the dark wallpaper and exposes IPC. `set-theme` uses the
current Hyprpaper wallpaper command with cover fit mode and retries while the
service starts. It commits the new shared state only after the wallpaper switch
succeeds. A persistent wallpaper failure produces a Dunst notification; normal
successful switches are intentionally silent.

Kitty's palette files are user-owned files at:

```text
~/.config/kitty/theme-dark.conf
~/.config/kitty/theme-light.conf
```

`~/.config/kitty/current-theme.conf` points to the selected file. Kitty permits
remote control through per-process sockets, allowing the switcher to recolor
running terminals. The palette files can be edited without rebuilding NixOS.

## Notifications

Dunst is managed by Home Manager and starts with the graphical session. Every
notification invokes a detached PipeWire playback of the Freedesktop
`message-new-instant.oga` sound at volume `0.5`.

The sound rule applies to all Dunst notifications, including screenshot and
theme-error notifications. Theme-switch completion notifications are disabled;
this does not disable Dunst or sounds for other notifications.

## Neovim And NVChad

Home Manager enables Neovim for the executable, editor defaults, and language
provider support. The NVChad configuration under `nvim/` is mapped into
`~/.config/nvim` with `xdg.configFile`.

Most files are immutable Nix-managed links. The lock file is deliberately
different:

```text
~/.config/nvim/lazy-lock.json -> /etc/nixos/nvim/lazy-lock.json
```

It is an out-of-store link, so `:Lazy sync` can update the tracked repository
file directly. Review and commit that change like any other configuration
change.

## Rebuild And Update Workflow

Run commands from `/etc/nixos` unless an absolute flake reference is shown.

Check flake evaluation without building:

```sh
nix flake check --no-build
```

Evaluate the system derivation:

```sh
nix eval .#nixosConfigurations.laptop.config.system.build.toplevel.drvPath
```

Perform the required soft build without creating a `result` symlink:

```sh
nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel
```

Activate the system:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#laptop
```

The `rebuild` Bash alias runs the same activation command. The graphical
`rebuild-nixos` wrapper also pauses before closing its Kitty window so build
output remains visible.

Update all locked flake inputs and activate:

```sh
update
```

This alias runs `nix flake update --flake /etc/nixos` and then rebuilds the
`laptop` target. Review lock-file changes before committing them.

Use `--impure` only if the configuration is deliberately changed to read an
unlocked path, environment value, or another impure dependency. It is not part
of this configuration's normal workflow.

## Customizing The Machine

For a different user or host, update `profile` in `flake.nix` and verify all
machine assumptions. In particular:

- Confirm the greetd UID restriction matches the intended desktop user.
- Regenerate `hardware-configuration.nix` for different hardware.
- Review the timezone, keyboard layout, monitor rule, battery paths, and lid
  behavior.
- Review the fixed `/etc/nixos` and local NordVPN repository paths if moving the
  checkout.
- Keep both state versions unchanged unless performing a deliberate state
  migration after reading the relevant NixOS and Home Manager release notes.

## Troubleshooting

If Home Manager reports an existing-file conflict, inspect the named path before
activation. Do not keep a manually managed `~/.bashrc`; Home Manager owns it.

If the desktop theme is incomplete, run an explicit target first:

```sh
set-theme dark
```

Then verify Hyprpaper, Waybar, Dunst, and Kitty individually. The theme state
file is `~/.cache/current-theme`.

If Lazy cannot update its lock file, verify that
`~/.config/nvim/lazy-lock.json` resolves to the tracked file in `/etc/nixos`,
not to an immutable `/nix/store` path.

If greetd does not present the expected account, verify the user's numeric UID
with `id` and compare it to the UID range in `configuration.nix`.
