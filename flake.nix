{
  description = "bugarela's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # NordVPN PR branch - provides nordvpn package and module
    nixpkgs-nordvpn.url = "github:different-error/nixpkgs/nordvpn";
    # nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-nordvpn, home-manager, ... }@inputs:
    let
      inherit (self) outputs;

      # Create overlay that provides nordvpn package from PR branch
      nordvpnOverlay = final: prev: {
        nordvpn = nixpkgs-nordvpn.legacyPackages.${final.system}.nordvpn;
      };

      commonModules = name: [
        ./nixos/common.nix
        ./nixos/${name}.nix
        # Import NordVPN module directly from PR branch
        "${nixpkgs-nordvpn}/nixos/modules/services/networking/nordvpn.nix"
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
          home-manager.useUserPackages = true;
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "backup1";
          home-manager.users.gabriela = import ./home-manager/${name}.nix;
        }
        # Apply nordvpn overlay
        { nixpkgs.overlays = [ nordvpnOverlay ]; }
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
