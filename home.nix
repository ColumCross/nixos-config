# =========================
# home.nix
# =========================
{ config, pkgs, ... }:

{
  home.username = "colum";
  home.homeDirectory = "/home/colum";

  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
  };

  programs.kitty = {
    enable = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
}