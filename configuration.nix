# =========================
# configuration.nix
# =========================
{ config, pkgs, unstablePkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    /etc/nixos-modules/nix_modules/nordvpn-module.nix
  ];

  #################################
  ## Bootloader
  #################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  #################################
  ## Networking
  #################################

  networking.hostName = "nixos";
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

    settings.default_session = {

      command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd ${pkgs.hyprland}/bin/Hyprland";
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
    kalker
    gh
    sl
    fastfetch
    md-tui

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
    unstablePkgs.spotify-player
    blueman
    wlogout
    adwaita-icon-theme
    kdePackages.dolphin

  ];

  # NordVPN configuration
  custom.services.nordvpn.enable = true;
  users.groups.nordvpn.members = ["colum"];

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
