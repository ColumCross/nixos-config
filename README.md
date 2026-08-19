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

Before installing, edit the `profile` attribute set near the top of
`flake.nix`:

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
the writable configuration checkout on the installed system.

Each computer must use the `hardware-configuration.nix` generated for that
computer. Do not reuse the included disk UUIDs on another machine.

This configuration does not publish a login password. Set the new user's
password locally during installation or from a root console with
`passwd your-username`.

The NordVPN module currently imported from
`/etc/nixos-modules/nix_modules/nordvpn-module.nix` is external to this
repository. That module must exist at the same path, or the import and related
NordVPN options must be removed before evaluating the configuration.

---

## Installation

Partition and mount the disks as normal.

Clone the repository:

git clone https://github.com/ColumCross/nixos-config.git

Change into the repository:

cd nixos-config

Copy the generated hardware configuration into the repository:

cp /mnt/etc/nixos/hardware-configuration.nix .

Install:

sudo nixos-install --flake .#laptop

Reboot.

---

## Updating

Pull the latest configuration:

git pull

Apply it:

sudo nixos-rebuild switch --flake .#laptop

---

## Updating package versions

nix flake update

Commit the updated flake.lock file.

Rebuild:

sudo nixos-rebuild switch --flake .#laptop
