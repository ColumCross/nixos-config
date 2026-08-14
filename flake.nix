# =========================
# flake.nix
# =========================
{
  description = "Colum's NixOS configuration";

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
    unstablePkgs = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit unstablePkgs; };

	pkgs = import nixpkgs {
		system = "x86_64-linux";
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

          home-manager.users.colum = import ./home.nix;
        }
      ];
    };
  };
}
