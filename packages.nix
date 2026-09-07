{ pkgs, profile, spotifyPlayerPackage, ... }:

{
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
    spotifyPlayerPackage
    blueman
    wlogout
    adwaita-icon-theme
    kdePackages.dolphin
    easyeffects

    # Disk utilities
    gptfdisk
    parted
    efibootmgr
    gnome-disk-utility

    # LaTeX packages
    (texliveMedium.withPackages (ps: with ps; [
      paracol
      enumitem
      fontawesome
      titlesec
    ]))
  ];

  custom.services.nordvpn.enable = true;
  users.groups.nordvpn.members = [profile.username];
}
