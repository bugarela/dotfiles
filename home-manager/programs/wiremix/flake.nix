{
  description = "Wiremix";
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rust = pkgs.rust-bin.stable.latest.default;
        supportedSystems = [ "x86_64-linux" ];
      in
      {
        packages = nixpkgs.lib.genAttrs supportedSystems (system: {
          default = nixpkgs.legacyPackages.${system}.callPackage ./. { };
        });
      }
    );
}
