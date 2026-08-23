# Replace this file on the cottage device with:
# sudo nixos-generate-config --root /mnt --show-hardware-config \
#   | sudo tee /mnt/etc/nixos/hosts/cottage/hardware-configuration.nix >/dev/null
throw "Generate hosts/cottage/hardware-configuration.nix on the cottage device before building it"
