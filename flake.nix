# =========================
# flake.nix
# =========================
{
  description = "Reusable NixOS and Home Manager configuration";

  inputs = {

    # external flake packages
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    opencode.url = "github:anomalyco/opencode";
    hyprKCS.url = "github:kosa12/hyprKCS";
    fast.url = "github:maaslalani/fast";
    herdr.url = "github:herdrdev/herdr/v0.9.3";

    spotify-player = {
      url = "github:aome510/spotify-player/6f94188ed6aae0d9c2cfecc25a434fc36a322df5";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nordvpn-module = {
      url = "git+file:///etc/nixos-modules/nix_modules";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # external flake packages
  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    opencode,
    hyprKCS,
    fast,
    spotify-player,
    nordvpn-module,
    herdr,
    ...
  }:
  let
    system = "x86_64-linux";
    profile = rec {
      username = "colum";
      homeDirectory = "/home/${username}";
      hostName = "nixos";
      flakeName = "laptop";
      configDirectory = "/etc/nixos";
    };
    unstablePkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    spotifyPlayerPackage = spotify-player.defaultPackage.${system};
  in {
    nixosConfigurations.${profile.flakeName} = nixpkgs.lib.nixosSystem {
      inherit system;

    # external flake packages
    specialArgs = {
      inherit
        profile
        unstablePkgs
        nordvpn-module
        spotifyPlayerPackage
        opencode
        hyprKCS
        fast
        herdr
        ;
    };

	pkgs = import nixpkgs {
		inherit system;
		config.allowUnfree = true;
	};

  modules = [
        ./configuration.nix
        ./modules/gtk4-color-scheme.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.extraSpecialArgs = { inherit profile; };

          home-manager.users.${profile.username} = import ./home.nix;
        }
      ];
    };
  };
}
