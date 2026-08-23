{
  system = "x86_64-linux";
  hostName = "cottage";
  hardwareModule = ./hardware-configuration.nix;

  users = {
    colum = {
      extraGroups = [
        "wheel"
        "networkmanager"
        "bluetooth"
      ];
      nordvpn = true;
    };

    cottage = {
      extraGroups = [
        "wheel"
        "networkmanager"
        "bluetooth"
      ];
      nordvpn = true;
    };
  };
}
