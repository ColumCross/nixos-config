# =========================
# configuration.nix
# =========================
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  #################################
  ## Bootloader
  #################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  #################################
  ## Networking
  #################################

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  #################################
  ## Time
  #################################

  time.timeZone = "Europe/Berlin";

  #################################
  ## Locale
  #################################

  i18n.defaultLocale = "en_US.UTF-8";

  #################################
  ## Display Manager
  #################################

  services.greetd = {
    enable = true;

    settings.default_session = {
      command = "${pkgs.hyprland}/bin/Hyprland";
      user = "colum";
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

  users.users.colum = {
    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
      "bluetooth"
    ];

    shell = pkgs.bash;
  };

  #################################
  ## Packages
  #################################

  environment.systemPackages = with pkgs; [

    git
    kitty
    google-chrome
    wget
    curl
    discord
    ripgrep
    fd
    gcc
  	gnumake
  	unzip
  	wl-clipboard

    # Desktop utilities
    rofi
    brightnessctl
    grim
    slurp
    playerctl
    pavucontrol
    hyprpaper
    hypridle
    hyprlock
    dunst
    libnotify
    spotify-player
    blueman

  ];

  #################################
  ## Fonts
  #################################

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
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
