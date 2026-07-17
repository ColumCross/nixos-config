# NixOS Laptop Configuration

## System Overview

- **OS**: NixOS 25.05 (stable)
- **User**: `colum` (wheel, networkmanager groups)
- **Desktop**: Hyprland (Wayland compositor)
- **Display manager**: greetd
- **Audio**: PipeWire (ALSA + PulseAudio)
- **Shell**: Bash (managed by Home Manager)
- **Flake target**: `laptop`

## File Structure

```
/etc/nixos/
├── configuration.nix          # NixOS system config (boot, networking, packages, services)
├── flake.nix                  # Flake inputs: nixpkgs, home-manager, claude-desktop, opencode
├── flake.lock                 # Locked flake inputs
├── hardware-configuration.nix # Auto-generated — do not edit manually
├── home.nix                   # Home Manager: Hyprland, Waybar, dunst, hyprpaper, shell, neovim
├── AGENTS.md                  # This file
├── README.md
└── nvim/                      # NVChad config (placed via xdg.configFile)
    ├── init.lua
    ├── lazy-lock.json
    ├── .stylua.toml
    └── lua/
        ├── chadrc.lua         # Theme: onedark
        ├── mappings.lua       # Custom: ; for cmdline, jk for escape
        ├── options.lua
        ├── autocmds.lua
        ├── configs/
        │   ├── conform.lua    # Formatter: stylua
        │   ├── lazy.lua
        │   └── lspconfig.lua  # LSP: html, cssls
        └── plugins/
            └── init.lua       # Plugins: conform, nvim-lspconfig
```

## How Configuration Works

- `configuration.nix` manages system-level packages and services
- `home.nix` manages all user-level config via Home Manager
- Hyprland config lives entirely in `home.nix` under `wayland.windowManager.hyprland.settings`
- NVChad files in `nvim/` are static copies placed by `xdg.configFile` — updated via Lazy.nvim, not git
- Wrapper scripts (rebuild-nixos, opencode-nixos, nvim-nixos) are generated via `pkgs.writeShellScriptBin` in `home.nix`

## Design Decisions

- **Hyprland package = null**: Both `package` and `portalPackage` are set to `null` in the HM module to use the packages from the NixOS module (`programs.hyprland.enable = true`). This keeps them version-synced.
- **Wrapper scripts for keybinds**: Terminal commands use wrapper scripts on PATH instead of inline `sh -c '...'`. This avoids the `#` comment parsing issue in hyprlang (Hyprland's config format treats `#` as a comment delimiter, breaking commands like `--flake /etc/nixos#laptop`).
- **Shell-agnostic scripts**: Wrapper scripts use `#!/bin/sh` and do not hardcode `bash` or `zsh`. If the user changes their default shell, these scripts still work.
- **NIXOS_OZONE_WL=1**: Set in `home.sessionVariables` so Electron apps (Chrome, Discord) use native Wayland.
- **hyprpaper wallpaper**: Uses `${pkgs.hyprland}/share/hypr/wall0.png` (Nix store path) so it auto-updates when Hyprland is upgraded. Can be swapped by changing `wall0.png` to `wall1.png`/`wall2.png` or a custom path.
- **Git identity**: Configured locally in `/etc/nixos/.git/config` (user.name="Colum Cross", user.email="columcross@gmail.com"). Global git config is read-only due to Home Manager managing `~/.config/git/`.

## Pitfalls to Avoid

- **Do NOT put `#` in Hyprland bind values**: Hyprlang treats `#` as a comment. Use wrapper scripts to avoid this.
- **Do NOT use `programs.neovim` alongside `xdg.configFile` for nvim**: Home Manager's `programs.neovim` creates its own nvim config which conflicts with `xdg.configFile."nvim"`. Currently `programs.neovim.enable = true` is set for PATH/defaultEditor, but nvim config files are managed via `xdg.configFile`. If this causes issues, set `programs.neovim.enable = false` and add neovim to system packages instead.
- **Do NOT have a manual `~/.bashrc`**: `programs.bash.enable = true` in Home Manager manages `~/.bashrc`. An existing file will cause the HM activation to fail. If it does, back up and remove the manual file.
- **`sudo` is required for rebuilds**: The `nixos-rebuild switch` command always needs sudo. Wrapper scripts handle this.
- **Flake uses committed git state**: All changes to files in `/etc/nixos/` must be committed before running `nixos-rebuild switch --flake`. Uncommitted changes are invisible to the flake.
