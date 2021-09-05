with (import <nixpkgs> {});

let
  pkgs = import
    (builtins.fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-20.03.tar.gz)
    { inherit config; };

    # The derivation for google-cloud-sdk
    gcloud = stdenv.mkDerivation rec {
      pname = "google-cloud-sdk";
      version = "350.0.0";

      src = pkgs.fetchurl {
        url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-350.0.0-linux-x86_64.tar.gz";
        sha256 =  "1vlcwab68d8rpzkjcwj83qn35bq0awsl15p35x5qpsymmvf046l6";
      };

      vendorSha256 = lib.fakeSha256;

      buildInputs = [
        pkgs.python3
      ];

      subPackages = [ "." ];

      runVend = false;

      installPhase = ''
        mkdir $out
        mv * $out
        mkdir $out/.install
      '';

      meta = with lib; {
        description = "google-cloud-sdk";
        homepage = "https://cloud.google.com/sdk";
        # license = licenses.mit;
        # maintainers = with maintainers; [ kalbasit ];
        platforms = platforms.linux;
      };
    };
in
mkShell {
  name = "gcloud";
  buildInputs = [
    gcloud
    python3
  ];

  shellHook = ''
    gcloud components install cbt
  '';
}
