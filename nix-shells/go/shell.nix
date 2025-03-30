with (import <nixpkgs> {});

let
  pkgs2003 = import
  (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-20.03.tar.gz)
    { inherit config; };
in
pkgs2003.mkShell {
  name = "go-env";
  buildInputs = [
    pkgs2003.go
    pkgs2003.gopls
    pkgs2003.goimports
  ];
}
