{ pkgs ? import <nixpkgs> { } }:
let
  lib = pkgs.lib;
in
pkgs.rustPlatform.buildRustPackage {
  pname = "note-taker-gui";
  version = "0.1.0";

  src = ./.;

  # The crate (and its Cargo.lock) live in src-tauri/. The ui/ dir sits next to
  # it and is embedded at compile time via tauri.conf.json `frontendDist = ../ui`.
  # cargoRoot: where the Cargo.lock / vendor config live.
  # buildAndTestSubdir: where the build phase runs `cargo build`.
  cargoRoot = "src-tauri";
  buildAndTestSubdir = "src-tauri";

  cargoLock = {
    lockFile = ./src-tauri/Cargo.lock;
  };

  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.wrapGAppsHook3
  ];

  buildInputs = [
    pkgs.webkitgtk_4_1
    pkgs.libsoup_3
    pkgs.gtk3
    pkgs.glib
    pkgs.glib-networking          # TLS GIO module, wired in by wrapGAppsHook3
    pkgs.gsettings-desktop-schemas
    pkgs.cairo
    pkgs.pango
    pkgs.gdk-pixbuf
    pkgs.atk
    pkgs.librsvg
    pkgs.openssl
    # WebKit media/canvas backends — silences "GStreamer element appsink not
    # found"; the gst setup hooks feed the wrapper's GST_PLUGIN_SYSTEM_PATH_1_0.
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
  ];

  # We build the binary directly (cargo build --release via buildRustPackage),
  # NOT `cargo tauri build` — the bundler does network fetches that fail in the
  # nix sandbox. The static frontend is embedded by tauri-build, so the plain
  # binary is fully functional.

  # NOTE on performance: we intentionally do NOT set WEBKIT_DISABLE_DMABUF_RENDERER
  # or WEBKIT_DISABLE_COMPOSITING_MODE. Forcing those disables the GPU path and
  # makes the webview laggy. The GPU/DMABUF path is fast *as long as* WebKit/mesa
  # match the running system — which is why common.nix passes the system `pkgs`.
  # If rendering is ever broken on a mismatched driver stack, the manual fallback
  # is: WEBKIT_DISABLE_DMABUF_RENDERER=1 note-taker-gui
  #
  # psmisc (fuser) + libnotify (notify-send) are shelled out to at runtime.
  preFixup = ''
    gappsWrapperArgs+=(
      --prefix PATH : ${lib.makeBinPath [ pkgs.psmisc pkgs.libnotify ]}
    )
  '';

  # No tests in this crate.
  doCheck = false;

  meta = with lib; {
    description = "A cute Tauri front-end for the note-taker transcription CLI";
    license = licenses.mit;
    mainProgram = "note-taker-gui";
    platforms = platforms.linux;
  };
}
