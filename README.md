# =========================
# README.md
# =========================
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