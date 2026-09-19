# NixOS Laptop Configuration

This repository configures my NixOS laptop and its Hyprland desktop. It includes
the system configuration, Home Manager environment, desktop theming, workspace
tools, editor setup, and support for an HP DisplayLink dock.

This README was prepared by GPT-5.6 Sol with human review. It is intended to be human readable, but provide enough context for AI Agents to use without need for duplicative wording in the AGENTS.md file.

## System Overview

- Hyprland desktop with greetd and tuigreet
- Waybar, Rofi, Dunst, Hyprpaper, Hyprlock, and Hypridle
- Kitty and Bash
- Neovim with NVChad
- PipeWire audio and EasyEffects
- NetworkManager, Bluetooth, and NordVPN
- HP USB-C/A Universal Dock G2 with two HP E243 displays

## Repository Map

```text
/etc/nixos/
|-- configuration.nix       # System services, user, login, and Hyprland package
|-- packages.nix            # System packages and NordVPN
|-- flake.nix               # Inputs, machine profile, and module assembly
|-- hardware-configuration.nix
|-- home.nix                # Home Manager and the main desktop session
|-- home/
|   |-- email.nix           # aerc, Lieer, Notmuch, mail helpers, and sync timer
|   |-- theming/            # Theme variants and switching
|   `-- waybar/             # Waybar package and configuration
|-- hyprland/
|   `-- keybindings.nix
|-- mail/
|   |-- bin/                # Mail setup, sync, status, sending, and launch tools
|   |-- .opencode/          # Restricted email agent, commands, and mail tools
|   |-- AGENTS.md           # Email handling and prompt-injection rules
|   `-- opencode.json       # Mail project's default agent and permissions
|-- modules/
|   `-- gtk4-color-scheme.nix
|-- nvim/                   # NVChad configuration
|-- opencode/plugins/       # OpenCode sleep inhibitor
|-- patches/                # GTK4 and Waybar patches
|-- scripts/                # Rebuild and workspace tools
|-- spotify-player/
|-- tests/                  # Workspace controller and topology tests
`-- wallpapers/
```

`configuration.nix` owns system-level services and the compositor package.
`home.nix` owns the user session and imports the focused theming and Waybar
modules. Custom scripts are packaged through Home Manager so their runtime
dependencies are explicit.

Email identities and the external aerc bindings path are stored in the
owner-only, Git-ignored `/etc/nixos/private-variables.json`. This file is read
at Home Manager activation time rather than during flake evaluation, preserving
pure builds and keeping personal values out of Git and the Nix store.

## Common Commands

The shell aliases below can be run from any directory:

```sh
rebuild  # Activate the current configuration
update   # Update flake inputs, then activate
```

Before activating a configuration change, it can be fully built without
creating a `result` symlink:

```sh
nix build --no-link /etc/nixos#nixosConfigurations.laptop.config.system.build.toplevel
```

The graphical rebuild shortcut runs `rebuild-nixos`. Its terminal remains open
after the rebuild and failed output is copied to the clipboard.

### Git Commands

These Bash aliases are available from any directory:

| Command | Equivalent | Description |
|---|---|---|
| `gco` | `git checkout` | Switch branches or restore files |
| `gs` | `git status` | Show the working tree status |
| `gl` | `git log --oneline -10` | Show the ten most recent commits |
| `gp` | `git push` | Push commits to the configured remote |

## Keybindings

| Shortcut | Action |
|---|---|
| `SUPER+T` | Open Kitty |
| `SUPER+SPACE` | Open Rofi |
| `SUPER+H/J/K/L` | Move focus with Vim-style directions |
| `SUPER+SHIFT+L` | Lock the session |
| `SUPER+ALT+L` | Toggle the dark/light theme |
| `SUPER+CTRL+SHIFT+R` | Open the rebuild wrapper |
| `SUPER+CTRL+C` | Open the OpenCode and editor Neovim workspace in `/etc/nixos` |
| `SUPER+CTRL+SHIFT+C` | Open Neovim in `/etc/nixos` |
| `SUPER+1` through `SUPER+0` | Select desktop 1 through 10 |
| `SUPER+SHIFT+1` through `SUPER+SHIFT+0` | Move the active window to desktop 1 through 10 |
| `SUPER+LEFT/RIGHT` | Cycle through existing desktops and wrap |
| `SUPER+SHIFT+LEFT/RIGHT` | Move the active window to the adjacent number |
| `SUPER+SHIFT+ALT+LEFT/RIGHT` | Reorder the current desktop among existing desktops |
| `SUPER+CTRL+ARROW` | Move the current desktop to another monitor |
| `CTRL+SHIFT+4` | Copy a selected-area screenshot |
| `CTRL+SHIFT+5` | Copy a full-screen screenshot |

## Primary Applications

### EasyEffects

EasyEffects runs as a background PipeWire service with an empty pipeline. It
does not restore the previously selected preset after a service or machine
restart. The Nix-managed `HB-Mid` output preset remains available for manual
selection during the current service lifetime.

### Neovim

NVChad is configured under `nvim/`. Most files are immutable Home Manager
links, but `lazy-lock.json` intentionally points directly into this repository:

```text
~/.config/nvim/lazy-lock.json -> /etc/nixos/nvim/lazy-lock.json
```

This allows `:Lazy sync` to update the tracked lock file. Markdown completion
is limited to paths, and `bullets.nvim` supplies list continuation and
renumbering in Markdown, text, and git commit buffers.

### Aerc

aerc is the terminal interface for a local, multi-account Gmail setup. Lieer
downloads messages and synchronizes Gmail labels, while each account has an
independent Notmuch database for indexing and search. Gmail remains the remote
source of truth and continues to work normally in other clients.

Account identities are declared under the `mail` section of the ignored
`private-variables.json`. During activation, `mail-configure` validates that
file and generates owner-only account, aerc, and Notmuch configuration under
`~/.config`. It also links `~/.config/aerc/binds.conf` to the external file
selected by `mail.aercBindsPath`, allowing the bindings repository to remain
mutable and outside this Git repository.

Each account uses this runtime layout:

```text
~/Mail/<account>/                 # Notmuch database root
|-- gmail/                        # Lieer-managed mail and synchronization state
`-- local-drafts/                 # Local aerc drafts, not Gmail Drafts

~/.config/notmuch/<account>.conf # Account-specific Notmuch configuration
~/.local/state/mail/credentials/ # Private Lieer OAuth tokens
~/.local/state/mail/status/      # Last synchronization result
~/.local/state/mail/locks/       # Manual and scheduled synchronization locks
```

Initialize or refresh an account from any directory:

```sh
mail-setup <gmail-address>
```

The command validates existing state, initializes Notmuch before Lieer when
needed, performs browser-based Google OAuth, synchronizes the full mailbox, and
refreshes aerc's Gmail label views. It never wipes an existing repository.
OAuth tokens remain outside Git and the Nix store.

Normal synchronization runs every five minutes through one Home Manager user
timer. Manual and scheduled synchronization use the same per-account locks, so
they cannot race. Useful commands are:

```sh
mail-sync all                  # Synchronize all configured accounts
mail-sync <gmail-address>      # Synchronize one account
mail-status                    # Show index counts and last sync results
mail-refresh-folders <account> # Refresh Gmail label views
aerc                           # Open the terminal mail client
```

aerc shows standard views such as Inbox, Unread, Starred, Important, Sent,
Drafts, All Mail, Spam, and Trash. Account-specific query maps also include all
normal Gmail labels, including empty labels and nested labels. Gmail category
tabs such as Promotions and Social are intentionally excluded. Label maps are
refreshed after successful synchronization and become visible after restarting
aerc.

`Marked for Deletion` is the single custom classification. It is a real Gmail
label, but only a human-operated command may apply it; the email assistant may
only propose it. It provides a review queue and is distinct from Gmail Trash.
Applying the `trash` tag removes Inbox membership on the next Lieer sync and
moves the message to Gmail Trash, where Gmail's normal retention policy applies.

The account-specific `mail-send` wrapper connects aerc's sendmail transport to
`gmi send`. Gmail supplies the synchronized Sent copy, avoiding duplicate local
copies. HTML mail is converted to text offline, remote links are not parsed
automatically, and drafts remain local unless separately implemented.

Open the restricted email assistant with:

```sh
mail-assistant
```

It starts OpenCode in `~/Mail` with a dedicated default-deny email agent. The
agent can only search mail metadata, read one message, read a bounded thread,
inspect synchronization status, and save a private note. It cannot invoke a
shell, send or synchronize mail, alter labels, archive, delete, or access Lieer
OAuth state. `/mail-find`, `/mail-review`, and `/mail-draft` provide optional
shortcuts. Message content selected by these tools is sent to the configured AI
model provider; local storage does not make model inference local.

# Custom Features

## Theme Switching

The desktop has explicit dark, light, and toggle commands:

```sh
set-theme dark
set-theme light
toggle-theme
```

Each Hyprland session starts in dark mode. A switch updates the wallpaper,
Kitty, btop, GTK and KDE color preferences, Waybar, Dunst, Rofi, Wlogout, and
running Neovim instances. The selected theme is recorded in
`~/.cache/current-theme`.

Theme assets are Nix-managed, while small `current` symlinks select the active
variant. Wallpaper application happens first; the shared state changes only if
it succeeds. Successful switches are silent, while a persistent wallpaper
failure sends a Dunst notification.

Kitty palettes remain user-editable at:

```text
~/.config/kitty/theme-dark.conf
~/.config/kitty/theme-light.conf
```

## Workspace Control

Only existing numbered desktops appear in Waybar. Number shortcuts select or
create desktops 1 through 10. Left and right navigation cycles through the
existing set, while window movement targets the numerically adjacent desktop
and may create it. Numeric movement stops at 1 and 10.

Waybar desktops can be dragged onto another visible desktop. Dropping on the
left or right half inserts the dragged desktop before or after the target. The
operation preserves each workspace identity, its windows, and monitor; it
reassigns the visible numeric labels to represent the new order. An invalid
drop makes no change.

`workspace-control` serializes changes, verifies Hyprland's result, and attempts
to restore the original mapping after a failed reorder. Failures are reported
through Dunst; successful operations are silent.

`workspace-topology` listens for monitor changes. With both dock displays
present, it places desktops 1, 2, and 3 on the left display, right display, and
laptop panel. Undocked, it places desktop 1 on the laptop panel. These are named
workspace identities so topology updates do not undo drag/drop ordering.

## Notifications and Notification Sound Mute Button

Every Dunst notification plays the configured alert sound. The bell beside
Waybar's volume control toggles this sound for the current graphical session.
Muting notifications does not hide visual notifications or affect any other
audio, and the setting returns to enabled after logout or reboot.

OpenCode uses Dunst for attention notifications, so it follows the same sound
setting rather than playing a separate TUI sound.

When OpenCode runs inside a Neovim terminal, it sends direct Dunst notifications
for completed sessions, prompts, and errors only while its containing Kitty
window is unfocused. Nested OpenCode sessions also follow live theme switches.

`SUPER+CTRL+C` opens two real Neovim tabpages in `/etc/nixos`: an initially
active OpenCode terminal and a `[No Name]` editor alongside the directory tree.

## OpenCode Sleep Inhibition

The Home Manager-deployed OpenCode plugin holds a systemd idle and sleep
inhibitor while an OpenCode session is busy or retrying, including while it is
waiting at a permission or question prompt. Each concurrent session owns its
own inhibitor and releases it when that session becomes idle.

Inspect active inhibitors with:

```sh
systemd-inhibit --list
```

Restart OpenCode after activating a plugin change.

## Battery Warning Notification

While discharging, Dunst sends one critical notification when any battery reaches
10% or lower. It rearms after charging begins or the level rises above 10%.

# Hardware Notes

## HP USB-C/A Universal Dock G2

The dock uses DisplayLink rather than Thunderbolt. Its proprietary driver
archive is not committed. After cloning onto a machine without the archive,
accept the Synaptics license and add the version required by the configured
Nixpkgs package:

```sh
nix-prefetch-url --name displaylink-620.zip \
  "https://www.synaptics.com/sites/default/files/exe_files/2025-09/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.2-EXE.zip"
```

The two HP E243 displays sit side by side above the laptop panel. Their shared
scale is controlled by `externalMonitorScale` near the top of `home.nix`; all
layout coordinates are derived from it. The current value is `5.0 / 6.0`.

Closing the lid while an external display is active locks the session and
disables the laptop panel without suspending. Opening it restores the docked
layout when both external displays are present, or the normal laptop layout
when undocked. Pointer input, including the touchpad, is configured left-handed.

# Architecture And Invariants

These constraints are easy to miss when changing the configuration:

- Machine-specific names and paths are centralized in `profile` in `flake.nix`.
- The NixOS Hyprland module owns the compositor and portal packages. Home
  Manager sets both package options to `null` and owns only session settings.
- Commands containing the flake separator `#` must not be placed directly in a
  Hyprland bind because Hyprland treats it as a comment. Use a wrapper command.
- greetd intentionally limits its menu to UID 1000. Changing the configured
  username or moving to another machine requires checking that UID assumption.
- The NordVPN module comes from `/etc/nixos-modules/nix_modules`; this checkout
  depends on that separate local repository.
- Theme variants are immutable. Only selector symlinks and the shared cache
  state are mutable, and normal theme switches must remain silent.
- `patches/waybar-hyprland-workspace-dnd.patch` supplies Waybar's opt-in drop
  action. Workspace reordering depends on this patched package.
- `modules/gtk4-color-scheme.nix` applies the GTK4 color-scheme backport needed
  for applications to start with the selected desktop theme.
- Workspace topology must preserve named workspace identities and existing
  labels when monitors change.
- `nvim/lazy-lock.json` must remain an out-of-store link so Lazy can update it.
- The OpenCode plugin must inhibit both idle handling and sleep while work or a
  user prompt is active, without one session releasing another's inhibitor.
- EasyEffects must start without an active preset or global bypass.

## Troubleshooting

- If the desktop theme is incomplete, run `set-theme dark`. A wallpaper failure
is reported through Dunst; the active state is in `~/.cache/current-theme`.

- If Lazy cannot update its lock file, verify that
`~/.config/nvim/lazy-lock.json` resolves to `/etc/nixos/nvim/lazy-lock.json`, not
to an immutable Nix store path.

- If greetd does not show the expected account, compare the user's numeric UID
with the UID 1000 restriction in `configuration.nix`.

- **Dunst theme and activation changes**: Restart `dunst.service` rather than using `dunstctl reload` after changing its theme selector symlink. Home Manager activation must also refresh the running service after replacing its generated configuration.
