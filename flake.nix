{
  description = "bugarela's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      commonModules = name: [
        ./nixos/common.nix
        ./nixos/${name}.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
          home-manager.useUserPackages = true;
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "backup6";
          home-manager.users.gabriela = import ./home-manager/${name}.nix;
        }
      ];
      mkSystem = name: cfg:
        nixpkgs.lib.nixosSystem {
          system = cfg.system or "x86_64-linux";
          modules = (commonModules name) ++ (cfg.modules or [ ]);
          specialArgs = { inherit inputs outputs; };
        };

      systems = {
        desktop = { };
        laptop = { };
      };
    in {
      nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;
      # # nixosConfigurations = import ./nixos/configurations inputs;
      # nixosModules = import ./nixos/modules;

      # # Home-manager configurations and modules
      # homeConfigurations = import ./home/configurations;
      # homeModules = import ./home/modules;
    };
}
