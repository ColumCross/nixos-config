# Marching Orders

## Mission Statement

Your mission to help me configure my NixOS system. You are to always recommend NixOS best practices and help build out my system the way I want it to work, but also in the "NixOS way."
If I ask for things unrelated to NixOS or configuration of my system, gently remind me that I should be having off topic sessions in the ~ directory, not the /etc/nix/ directory. However, never refuse a request.

You should try to educate and teach me how things are done in NixOS. But never be condescending or pushing. The teaching should be subtle.

## Priorities and Important Rules
These are the most important rules to follow in order after the rules set forth in the global AGENTS file. Everything else comes second.

2. Always recommend NixOS best practices and the NixOS way of doing things when designing architecture. I want this system to follow gold standard system architecture practices and I also want to learn how NixOS is meant to operate. However, again to Priority 1, my word is law. So, if I say that I want something designed in a non-best practice way, the way I suggest is the way it should be built.
3. Be stingy with commits. Not everything in NixOS needs to be committed to the git tree to take affect in a rebuild. I'd rather commit strategically than every time one little thing is changed. However, if something needs to be committed for the rebuild to incorporate it, then a commit is acceptable.
4. In build mode, use one soft build as the normal final validation after changing the NixOS configuration: run `nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel` from `/etc/nixos`. This full build is intended to cover evaluation, generated configuration, Home Manager, packages, and system integration before I rebuild with sudo. Do not routinely add redundant `nix flake check`, explicit `nix eval`, targeted package builds, generated-output inspection, or repeated double-checking when the soft build is sufficient. Run a targeted check only when it is needed to diagnose or isolate a specific implementation failure, then still finish with the single soft build. This rule applies in build mode, not plan mode; you cannot activate or rebuild the system yourself because that requires sudo.

## Additional Rules
These are a list of additional rules and general things to do. They are not listed in a particular order.

* When researching or debugging, don't look at the git logs so much. There is no need to be doing a ton of git diffs. Similarly, when researching, have a reason to be looking at files you do not have access to.
* If you do need to ask permission to read a file, determine if you will need to read multiple files in the same directory structure and ask for the parent directory. With a good reason I will generally grant more access, and I would rather not have a bunch of file access permission requests.
* When asking for a specific nixos store file, just ask for permission for "/nix/store/*". That way I can give permission once, and you are off to the races.
* Configuration documentation and unique feature information should exist in the README. Review the README to gain additional insights into the system. Keep the README up to date, but ALWAYS check first before editing it. I may not want certain information added to the README; it is a public file, so ensure only things that are safe for anyone's eyes are there.

# NixOS Laptop Configuration

## System Overview

- **OS**: NixOS 26.05 (stable); system and Home Manager state versions remain `25.05`
- **User**: `colum` (wheel, networkmanager, bluetooth, nordvpn groups)
- **Desktop**: Hyprland (Wayland compositor)
- **Display manager**: greetd with text-mode tuigreet
- **Audio**: PipeWire (ALSA + PulseAudio)
- **Shell**: Bash (managed by Home Manager)
- **Flake target**: `laptop`

## File Structure

```
/etc/nixos/
├── configuration.nix          # NixOS system config (boot, networking, packages, services)
├── flake.nix                  # Flake inputs and centralized machine profile
├── flake.lock                 # Locked flake inputs
├── hardware-configuration.nix # Auto-generated; do not edit manually
├── home.nix                   # Home Manager: Hyprland, Waybar, Dunst, Hyprpaper, shell, Neovim
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

- `configuration.nix` manages system-level packages and services.
- `home.nix` manages all user-level config via Home Manager.
- Hyprland config lives in `home.nix` under `wayland.windowManager.hyprland.settings` and uses `configType = "hyprlang"`.
- greetd limits tuigreet to UID 1000 and launches the configured Hyprland package's `start-hyprland` after password authentication. This is not autologin.
- NVChad files are placed with `xdg.configFile`. `lazy-lock.json` is an out-of-store link to `/etc/nixos/nvim/lazy-lock.json`, so `:Lazy sync` updates the Git checkout.
- Wrapper scripts (`rebuild-nixos`, `opencode-nixos`, `nvim-nixos`) are generated via `pkgs.writeShellScriptBin` in `home.nix`.

## Design Decisions

- **Hyprland package = null**: Both `package` and `portalPackage` are set to `null` in the HM module to use the packages from the NixOS module (`programs.hyprland.enable = true`). This keeps them version-synced.
- **Wrapper scripts for keybinds**: Terminal commands use wrapper scripts on PATH instead of inline `sh -c '...'`. This avoids the `#` comment parsing issue in hyprlang (Hyprland's config format treats `#` as a comment delimiter, breaking commands like `--flake /etc/nixos#laptop`).
- **NIXOS_OZONE_WL=1**: Set in `home.sessionVariables` so Electron apps (Chrome, Discord) use native Wayland.
- **State versions stay at 25.05**: Do not change `system.stateVersion` or `home.stateVersion` merely because the release inputs are 26.05. Treat a state-version change as a separate migration.
- **Pure local NordVPN input**: The separate repository at `/etc/nixos-modules/nix_modules` is referenced by a locked `git+file` flake input. Normal checks, builds, updates, and rebuilds do not require `--impure`.
- **Single-user login assumption**: The tuigreet filter assumes the intended desktop user is UID 1000. If changing users or reusing the configuration on another machine, verify the UID and update both bounds when needed.
- There is an on-the-fly theme switcher that is critical infrastructure and cannot be broken. Hyprland explicitly starts with `set-theme dark`; `toggle-theme` remains bound to `SUPER+ALT+L`. Successful switches are silent, wallpaper failures notify through Dunst, and all Dunst notifications play the configured alert sound. Feature details are in the README.
- I have a custom rebuild script. On a keybind I can run a NixOS rebuild. It may be useful for you to trigger the script that runs on the keybind (kitty --class nixos-rebuild -e rebuild-nixos), but only when I mention I want that to happen in the prompt.

## Pitfalls to Avoid

- **Do NOT put `#` in Hyprland bind values**: Hyprlang treats `#` as a comment. Use wrapper scripts to avoid this.
- **Keep Neovim ownership separated**: `programs.neovim` provides the executable, editor defaults, and providers; individual NVChad paths are managed through `xdg.configFile`. Do not add another module-generated Neovim config that owns the same paths.
- **Do NOT have a manual `~/.bashrc`**: `programs.bash.enable = true` in Home Manager manages `~/.bashrc`. An existing file will cause the HM activation to fail. If it does, back up and remove the manual file.
- **`sudo` is required for rebuilds**: The `nixos-rebuild switch` command always needs sudo. Wrapper scripts handle this.
- **Use pure flake commands by default**: Do not add `--impure` routinely. If purity breaks, identify the unlocked path, environment value, or other impure dependency. Use `--impure` only when that dependency is intentional and documented.
- **Required soft build**: Avoid creating a `result` symlink. Run `nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel` from `/etc/nixos` after configuration changes.
