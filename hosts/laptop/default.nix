{
  system = "x86_64-linux";
  hostName = "nixos";
  hardwareModule = ./hardware-configuration.nix;

  users.colum = {
    extraGroups = [
      "wheel"
      "networkmanager"
      "bluetooth"
    ];
    nordvpn = true;
  };
}
