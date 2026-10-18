# external flake packages
{
  pkgs,
  profile,
  spotifyPlayerPackage,
  opencode,
  hyprKCS,
  fast,
  herdr,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  environment.systemPackages = with pkgs; [
    # external flake packages
    opencode.packages.${system}.default
    hyprKCS.packages.${system}.default
    fast.packages.${system}.default
    herdr.packages.${system}.default

    # NixOS Packages
    git
    kitty
    google-chrome
    wget
    curl
    jq
    discord
    ripgrep
    fd
    gcc
    gnumake
    unzip
    wl-clipboard
    fend
    gh
    sl
    fastfetch
    md-tui
    btop
    vlc
    element-desktop
    obs-studio

    system-config-printer
    pandoc

    # Weather clients
    weathr
    wthrr

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
    gimp

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

    # Email Tools
    aerc
    lieer
    notmuch
    chawan

  ];

  custom.services.nordvpn.enable = true;
  users.groups.nordvpn.members = [profile.username];
}
