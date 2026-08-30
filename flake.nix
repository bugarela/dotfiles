{
  description = "bugarela's NixOS Config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Latest nixpkgs for bleeding-edge packages like ollama (master branch)
    nixpkgs-latest.url = "github:nixos/nixpkgs";
    # Last release before nixpkgs dropped GTK2; keeps nitrogen alive (see gtk2Overlay)
    nixpkgs-gtk2.url = "github:nixos/nixpkgs/nixos-25.11";
    # nur.url = "github:nix-community/NUR";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-gtk2, home-manager, ... }@inputs:
    let
      inherit (self) outputs;

      # nitrogen was removed from nixpkgs along with GTK2 (it needs gtkmm2). It
      # cannot be rebuilt against the current pin -- the whole GTK2 stack is gone --
      # so take the prebuilt package from the last release that still had it. This
      # drags in that release's GTK2 closure, but it comes straight from the cache.
      gtk2Overlay = final: prev: {
        nitrogen = nixpkgs-gtk2.legacyPackages.${final.system}.nitrogen;
      };

      # openldap test017-syncreplication-refresh is flaky (timing-dependent); skip tests
      openldapOverlay = final: prev: {
        openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });
      };

      # rose-pine-gtk-theme was dropped from nixpkgs when the GTK2 engines
      # (gtk-engine-murrine, gtk_engines, gnome-themes-extra) were removed. Those
      # were only ever declared for the theme's GTK2 assets, which the derivation
      # never installed -- it copies gtk3/ and gtk4/ only. So re-declare it here
      # without them; the result is byte-identical to what upstream shipped.
      rosePineOverlay = final: prev: {
        rose-pine-gtk-theme = final.stdenvNoCC.mkDerivation rec {
          pname = "rose-pine-gtk-theme";
          version = "2.2.0";

          src = final.fetchFromGitHub {
            owner = "rose-pine";
            repo = "gtk";
            tag = "v${version}";
            hash = "sha256-vCWs+TOVURl18EdbJr5QAHfB+JX9lYJ3TPO6IklKeFE=";
          };

          # avoid the makefile which is only for theme maintainers
          dontBuild = true;

          installPhase = ''
            runHook preInstall

            mkdir -p $out/share/themes/rose-pine{,-dawn,-moon}/gtk-4.0

            variants=("rose-pine" "rose-pine-dawn" "rose-pine-moon")
            for n in "''${variants[@]}"; do
              cp -r $src/gtk3/"''${n}"-gtk/* $out/share/themes/"''${n}"
              cp -r $src/gtk4/"''${n}".css $out/share/themes/"''${n}"/gtk-4.0/gtk.css
            done

            runHook postInstall
          '';

          meta = {
            description = "Rosé Pine theme for GTK";
            homepage = "https://github.com/rose-pine/gtk";
            license = nixpkgs.lib.licenses.gpl3Only;
            platforms = nixpkgs.lib.platforms.linux;
          };
        };
      };

      commonModules = name: [
        ./nixos/common.nix
        ./nixos/${name}.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = { inherit inputs outputs; };
          home-manager.useUserPackages = true;
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "backup10";
          home-manager.users.gabriela = import ./home-manager/${name}.nix;
        }
        # Apply overlays
        { nixpkgs.overlays = [ openldapOverlay rosePineOverlay gtk2Overlay ]; }
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
