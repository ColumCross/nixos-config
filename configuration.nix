# =========================
# configuration.nix
# =========================
{ config, pkgs, lib, hostProfile, resolvedUsers, unstablePkgs, ... }:

{
  imports = [
    /etc/nixos-modules/nix_modules/nordvpn-module.nix
  ];

  services.udisks2.enable = true;

  #################################
  ## Bootloader
  #################################

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  #################################
  ## Networking
  #################################

  networking.hostName = hostProfile.hostName;
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

  users.users = lib.mapAttrs (_username: userProfile: {
    inherit (userProfile) uid;
    isNormalUser = true;
    extraGroups = userProfile.extraGroups;
    shell = pkgs.bash;
  }) resolvedUsers;

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
    btop
    vlc

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
    easyeffects

  ];

  # NordVPN configuration
  custom.services.nordvpn.enable = true;
  users.groups.nordvpn.members = lib.attrNames (
    lib.filterAttrs (_username: userProfile: userProfile.nordvpn) resolvedUsers
  );

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
