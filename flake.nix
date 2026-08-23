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
    userDefinitions = {
      colum = import ./users/colum;
      cottage = import ./users/cottage;
    };

    hostDefinitions = {
      laptop = import ./hosts/laptop;
      cottage = import ./hosts/cottage;
    };

    mkHost = flakeName: hostDefinition:
      let
        inherit (hostDefinition) system;

        resolvedUsers = nixpkgs.lib.mapAttrs (
          username: hostUser:
          let
            userDefinition =
              userDefinitions.${username}
                or (throw "Host '${flakeName}' references undefined user '${username}'");
          in
          userDefinition
          // hostUser
          // {
            inherit username;
            homeDirectory = "/home/${username}";
          }
        ) hostDefinition.users;

        hostProfile = {
          inherit flakeName resolvedUsers;
          inherit (hostDefinition) hostName;
          configDirectory = "/etc/nixos";
        };

        unstablePkgs = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = { inherit hostProfile resolvedUsers unstablePkgs; };

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        modules = [
          hostDefinition.hardwareModule
          ./configuration.nix
          home-manager.nixosModules.home-manager

          ({ lib, pkgs, ... }: {
            environment.systemPackages = [
              claude-desktop.packages.${pkgs.system}.default
              opencode.packages.${pkgs.system}.default
              hyprKCS.packages.${pkgs.system}.default
              fast.packages.${pkgs.system}.default
            ];

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.users = lib.mapAttrs (
              username: userProfile: {
                imports = [ userProfile.homeModule ];

                _module.args.profile = {
                  inherit username flakeName;
                  inherit (userProfile) homeDirectory;
                  inherit (hostDefinition) hostName;
                  configDirectory = "/etc/nixos";
                };
              }
            ) resolvedUsers;
          })
        ];
      };
  in
  {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkHost hostDefinitions;
  };
}
