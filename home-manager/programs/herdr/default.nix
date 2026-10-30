{ pkgs }:
# Herdr desktop app (herdr-app) and its terminal core (herdr-core / hc).
# herdr-core.nix and herdr-desktop.nix are copied verbatim from the open nixpkgs
# PR https://github.com/NixOS/nixpkgs/pull/581031 (tophcodes/nixpkgs@bc319af8).
# Once it merges, delete this directory and use pkgs.herdr-desktop instead.
let
  herdr-core = pkgs.callPackage ./herdr-core.nix { };
  herdr-desktop = pkgs.callPackage ./herdr-desktop.nix { inherit herdr-core; };
in
pkgs.symlinkJoin {
  name = "herdr-${herdr-desktop.version}";
  paths = [ herdr-desktop herdr-core ];
}
