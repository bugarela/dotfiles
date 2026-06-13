{
  description = "note-taker-gui — a cute Tauri front-end for the note-taker CLI";
  inputs = {
    nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        rust = pkgs.rust-bin.stable.latest.default;

        nativeDeps = [
          pkgs.pkg-config
          pkgs.webkitgtk_4_1
          pkgs.gtk3
          pkgs.glib
          pkgs.cairo
          pkgs.pango
          pkgs.gdk-pixbuf
          pkgs.atk
          pkgs.librsvg
          pkgs.openssl
        ];
      in
      {
        packages.default = pkgs.callPackage ./. { };

        # `nix develop` for iterating with `cargo tauri dev` without a full rebuild.
        devShells.default = pkgs.mkShell {
          buildInputs = [
            rust
            pkgs.cargo-tauri
            pkgs.nodejs_22
            pkgs.psmisc
            pkgs.libnotify
          ] ++ nativeDeps;
          shellHook = ''
            export WEBKIT_DISABLE_DMABUF_RENDERER=1
            export WEBKIT_DISABLE_COMPOSITING_MODE=1
          '';
        };
      }
    );
}
