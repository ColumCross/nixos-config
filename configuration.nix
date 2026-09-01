# =========================
# configuration.nix
# =========================
{ config, pkgs, profile, unstablePkgs, nordvpn-module, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./packages.nix
    "${nordvpn-module}/nordvpn-module.nix"
  ];

  services.udisks2.enable = true;

  services.logind.settings.Login.HandlePowerKey = "suspend";

  #################################
  ## Bootloader
  #################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = null;
  boot.loader.efi.canTouchEfiVariables = true;

  #################################
  ## Networking
  #################################

  networking.hostName = profile.hostName;
  networking.networkmanager.enable = true;

  #################################
  ## Time
  #################################

  #time.timeZone = "Europe/Berlin";
  time.timeZone = "America/New_York";

  #################################
  ## Locale
  #################################

  i18n.defaultLocale = "en_US.UTF-8";

  #################################
  ## Display Manager
  #################################

  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --user-menu --user-menu-min-uid 1000 --user-menu-max-uid 1000 --background matrix --cmd ${config.programs.hyprland.package}/bin/start-hyprland";
      user = "greeter";
    };
  };

  #################################
  ## Sound
  #################################

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

  #################################
  ## Bluetooth
  #################################

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  #################################
  ## XDG Portal
  #################################

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  #################################
  ## Hyprland
  #################################

  programs.hyprland.enable = true;

  #################################
  ## Git
  #################################

  programs.git.enable = true;

  #################################
  ## User
  #################################

  users.users.${profile.username} = {
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
      "bluetooth"
    ];

    shell = pkgs.bash;
  };

  #################################
  ## Fonts
  #################################

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  #################################
  ## Nix Features
  #################################

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  #################################
  ## System Version
  #################################

  system.stateVersion = "25.05";
}
