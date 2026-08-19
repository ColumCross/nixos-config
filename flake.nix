# =========================
# flake.nix
# =========================
{
  description = "Reusable NixOS and Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-desktop.url = "github:aaddrick/claude-desktop-debian";
    opencode.url = "github:anomalyco/opencode";
    hyprKCS.url = "github:kosa12/hyprKCS";
    fast.url = "github:maaslalani/fast";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    claude-desktop,
    opencode,
    hyprKCS,
    fast,
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
  in {
    nixosConfigurations.${profile.flakeName} = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit profile unstablePkgs; };

	pkgs = import nixpkgs {
		inherit system;
		config.allowUnfree = true;
	};

  modules = [
    ({ pkgs, ... }: {
      environment.systemPackages = [ 
		    claude-desktop.packages.${pkgs.system}.default
        opencode.packages.${pkgs.system}.default
        hyprKCS.packages.${pkgs.system}.default
        fast.packages.${pkgs.system}.default
	    ];
	  })
        ./configuration.nix

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
