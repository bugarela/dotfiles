# Sable ships as a web app: `pkgs.sable` is a directory of static files (the
# Vite `dist/`), with no binary and no desktop entry. Upstream's own flake is
# the same -- its Tauri desktop build exists only as a devShell, and the only
# ready-made desktop artifacts are prebuilt release binaries.
#
# So build the window ourselves: serve the dist off the loopback and point a
# dedicated Chromium profile at it in --app mode. That is what the prebuilt
# desktop app is too (a browser engine around this same dist), minus the
# 180MB of vendored CEF.
{ pkgs
, sable ? pkgs.sable
, browser ? pkgs.chromium
  # Extra flags for the host browser, e.g. the Chromium clipboard workaround.
, browserFlags ? [ ]
}:

let
  lib = pkgs.lib;

  launcher = pkgs.writeShellApplication {
    name = "sable-desktop";
    runtimeInputs = [ pkgs.static-web-server pkgs.coreutils ];
    text = ''
      dist="${sable}"
      state="''${XDG_DATA_HOME:-$HOME/.local/share}/sable-desktop"
      mkdir -p "$state/browser"

      # A connect that succeeds means something is already listening.
      # The subshell scopes fd 3, so it closes on its own either way.
      port_free() {
        ! (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null
      }

      port=""
      for _ in $(seq 1 100); do
        candidate=$(( 20000 + RANDOM % 20000 ))
        if port_free "$candidate"; then
          port="$candidate"
          break
        fi
      done
      if [ -z "$port" ]; then
        echo "sable-desktop: no free loopback port found" >&2
        exit 1
      fi

      # Serve over http://127.0.0.1 rather than file://. localhost is a secure
      # context, so the service worker, notifications and getUserMedia/WebRTC
      # all work; under file:// the service worker refuses to register and the
      # call stack is dead on arrival. --page-fallback keeps client-side routes
      # working when the app reloads on a deep link.
      static-web-server \
        --host 127.0.0.1 \
        --port "$port" \
        --root "$dist" \
        --page-fallback "$dist/index.html" \
        --log-level error &
      server=$!
      trap 'kill "$server" 2>/dev/null || true' EXIT

      for _ in $(seq 1 200); do
        if ! port_free "$port"; then break; fi
        sleep 0.05
      done

      # Its own --user-data-dir, so the Matrix session and encryption keys live
      # apart from the daily browser and survive across launches.
      # --class makes xmonad see this as "Sable" rather than another Chromium.
      ${lib.getExe browser} \
        --user-data-dir="$state/browser" \
        --class=Sable \
        --no-first-run \
        --no-default-browser-check \
        ${lib.escapeShellArgs browserFlags} \
        --app="http://127.0.0.1:$port/" \
        "$@"
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "sable";
    desktopName = "Sable";
    comment = "Matrix client";
    exec = "sable-desktop";
    icon = "sable";
    categories = [ "Network" "InstantMessaging" ];
    startupWMClass = "Sable";
  };

in
pkgs.stdenvNoCC.mkDerivation {
  pname = "sable-desktop";
  inherit (sable) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    ln -s ${launcher}/bin/sable-desktop $out/bin/sable-desktop
    ln -s ${desktopItem}/share/applications $out/share/applications

    for size in 48 72 96 144 192 256 384 512; do
      dir=$out/share/icons/hicolor/''${size}x''${size}/apps
      mkdir -p "$dir"
      ln -s ${sable}/public/logo/logo-''${size}x''${size}.png "$dir/sable.png"
    done

    runHook postInstall
  '';

  meta = {
    description = "Sable Matrix web client in a dedicated browser window";
    inherit (sable.meta) homepage license;
    mainProgram = "sable-desktop";
    platforms = lib.platforms.linux;
  };
}
